const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { createServer } = require('./server.cjs');
const { normalizeDisplay } = require('./normalize-display.cjs');

test('display migration preserves business state and is idempotent', () => {
  const before = { tasks: [{ id: 'job-17', status: 4, driverName: '陈志远（演示）',
    startAddress: '物流中心（演示）', cargoPictureList: [{ url: 'http://host/photo.jpg' }],
    exceptionList: [{ exceptionDescribe: '模拟故障记录' }] }],
    messages: [{ id: 1, title: '本地演示公告', content: '欢迎使用本地模拟服务，所有任务与消息均为演示数据。',
      isRead: 1, readTime: '2026-10-30 19:00:00' }], extra: 'preserved' };
  const after = normalizeDisplay(before);
  assert.equal(before.tasks[0].driverName, '陈志远（演示）');
  assert.deepEqual(after, { ...before,
    tasks: [{ ...before.tasks[0], driverName: '陈志远', startAddress: '物流中心' }],
    messages: [{ ...before.messages[0], title: '系统公告', content: '欢迎使用司机服务，请及时查看运输任务与通知。' }] });
  assert.deepEqual(normalizeDisplay(after), after);
});

test('message migration, pagination, read state, authentication and vehicle contract', async () => {
  const dataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fast-driver-message-test-'));
  const { createWaitingTask } = require('./fixtures.cjs');
  const tasks = Array.from({ length: 12 }, (_, i) => createWaitingTask(`job-${i+1}`, String(100001+i), i));
  fs.writeFileSync(path.join(dataDir, 'db.json'), JSON.stringify({ tasks, preserved: 'keep' }));
  let server, base;
  async function start() {
    server = createServer({ dataDir });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    base = `http://127.0.0.1:${server.address().port}`;
  }
  async function stop() {
    server.closeIdleConnections();
    await new Promise(resolve => server.close(resolve));
  }
  async function api(route, method = 'GET', auth = true) {
    return (await fetch(base + '/driver' + route, { method,
      headers: auth ? { Authorization: 'mock-driver-demo-token' } : {} })).json();
  }
  const list = '/messages/page?page=1&pageSize=10&contentType=201';
  try {
    await start();
    assert.equal((await api(list, 'GET', false)).code, 401);
    assert.equal((await api('/messages/2', 'PUT', false)).code, 401);
    assert.equal((await api('/messages/readAll/201', 'PUT', false)).code, 401);
    assert.equal((await api('/users/truck', 'GET', false)).code, 401);
    const first = (await api(list)).data;
    assert.doesNotMatch(JSON.stringify(first), /演示|模拟/);
    assert.equal(first.counts, 12); assert.equal(first.pages, 2); assert.equal(first.items.length, 10);
    const second = (await api('/messages/page?page=2&pageSize=10&contentType=201')).data;
    assert.equal(second.items.length, 2);
    assert.equal(first.items.some(a => second.items.some(b => a.id === b.id)), false);
    assert.equal((await api('/tasks/details/' + first.items[0].relevantId)).code, 200);
    const messageId = first.items[0].id;
    assert.equal((await api('/messages/' + messageId, 'PUT')).code, 200);
    const read = (await api(list)).data.items.find(m => m.id === messageId);
    assert.equal(read.isRead, 1); assert.ok(read.readTime);
    assert.equal((await api('/messages/' + messageId, 'PUT')).code, 200);
    assert.equal((await api(list)).data.items.find(m => m.id === messageId).readTime, read.readTime);
    assert.equal((await api('/messages/999999', 'PUT')).code, 404);
    assert.equal((await api('/messages/page?page=0&pageSize=10&contentType=201')).code, 400);
    assert.equal((await api('/messages/page?page=1&pageSize=101&contentType=201')).code, 400);
    assert.equal((await api('/messages/page?page=1&pageSize=10&contentType=202')).code, 400);
    assert.equal((await api('/messages/readAll/202', 'PUT')).code, 400);
    assert.equal((await api('/messages/page?page=3&pageSize=10&contentType=201')).data.items.length, 0);
    assert.equal((await api('/messages/readAll/201', 'PUT')).code, 200);
    assert.ok((await api(list)).data.items.every(m => m.isRead === 1));
    assert.equal((await api('/messages/page?page=1&pageSize=10&contentType=200')).data.items[0].isRead, 0);
    const truck = (await api('/users/truck')).data;
    assert.doesNotMatch(JSON.stringify(truck), /演示|模拟/);
    for (const key of ['allowableLoad', 'currentOrganName', 'id', 'licensePlate', 'truckType']) assert.equal(typeof truck[key], 'string');
    assert.ok(Array.isArray(truck.pictureList));
    await stop(); await start();
    assert.equal((await api(list)).data.counts, 12);
    assert.ok((await api('/messages/page?page=2&pageSize=10&contentType=201')).data.items.every(m => m.isRead === 1));
    let saved = JSON.parse(fs.readFileSync(path.join(dataDir, 'db.json'), 'utf8'));
    assert.deepEqual(saved.tasks, tasks); assert.equal(saved.preserved, 'keep');
    await stop();
    saved.messages = [];
    fs.writeFileSync(path.join(dataDir, 'db.json'), JSON.stringify(saved));
    await start();
    assert.equal((await api(list)).data.counts, 0);
  } finally {
    if (server?.listening) await stop();
    fs.rmSync(dataDir, { recursive: true, force: true });
  }
});

test('HTTP workflow, filtering, upload and persistent task state', async () => {
  const dataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fast-driver-mock-test-'));
  let server;
  async function start() {
    server = createServer({ dataDir });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    return `http://127.0.0.1:${server.address().port}`;
  }
  async function stop() {
    server.closeIdleConnections();
    await new Promise(resolve => server.close(resolve));
  }
  try {
    let base = await start(), token = '';
    async function api(route, method = 'GET', form, auth = true) {
      const response = await fetch(base + route, { method,
        headers: { 'Content-Type':'application/json', ...(auth ? {Authorization:token} : {}) },
        body: form === undefined ? undefined : JSON.stringify(form) });
      return response.json();
    }
    assert.equal((await api('/health', 'GET', undefined, false)).data.mock, true);
    assert.equal((await api('/driver/tasks/list?page=1&pageSize=5&status=1')).code, 401);
    assert.equal((await api('/driver/login/account', 'POST', {account:'demo',password:'bad'}, false)).code, 401);
    token = (await api('/driver/login/account', 'POST', {account:'demo',password:'mock123456'}, false)).data;
    const initialFinished = (await api('/driver/tasks/list?page=1&pageSize=20&status=6')).data.counts;
    assert.equal(initialFinished,0);
    const list = await api('/driver/tasks/list?page=1&pageSize=5&status=1');
    assert.equal(list.data.counts, 24); assert.equal(list.data.pages, 5); assert.equal(list.data.items[0].status, '1');
    assert.equal((await api('/driver/tasks/list?page=2&pageSize=5&status=1')).data.items.length, 5);
    assert.equal((await api('/driver/tasks/list?page=1&pageSize=5&status=2')).data.counts, 0);
    assert.equal((await api('/driver/tasks/list?page=1&pageSize=5&status=1&startTime=2026-02-30')).code, 400);
    const original = list.data.items[0];
    const date = original.planDepartureTime.slice(0,10);
    assert.equal((await api(`/driver/tasks/list?page=1&pageSize=5&status=1&transportTaskId=${original.transportTaskId}&startTime=${date}&endTime=${date}`)).data.counts, 1);
    assert.equal((await api('/driver/tasks/list?page=1&pageSize=5&status=1&transportTaskId=missing')).data.pages, 0);
    assert.equal((await api('/driver/tasks/details/missing')).code, 404);
    const png = await (await fetch(base + '/demo.png')).arrayBuffer();
    const form = new FormData(); form.append('file',new Blob([png],{type:'image/png'}),'photo.png');
    const upload = await (await fetch(base + '/driver/files/imageUpload',{method:'POST',headers:{Authorization:token},body:form})).json();
    assert.equal(upload.code,200);
    const savedImage = Buffer.from(await (await fetch(upload.data)).arrayBuffer());
    assert.equal(savedImage.equals(Buffer.from(png)),true);
    const badForm = new FormData(); badForm.append('file',new Blob(['invalid']),'bad.png');
    assert.equal((await (await fetch(base+'/driver/files/imageUpload',{method:'POST',headers:{Authorization:token},body:badForm})).json()).code,400);
    const picture = [{url:upload.data}];
    assert.equal((await api('/driver/tasks/delay','PUT',{id:original.id,delayTime:'2026-10-08 09:00',delayReason:'模拟延迟'})).code,200);
    assert.equal((await api('/driver/tasks/takeDelivery','POST',{id:original.id,cargoPictureList:[],cargoPickUpPictureList:picture})).code,400);
    assert.equal((await api('/driver/tasks/takeDelivery','POST',{id:original.id,cargoPictureList:picture,cargoPickUpPictureList:picture})).code,200);
    assert.equal((await api('/driver/tasks/takeDelivery','POST',{id:original.id,cargoPictureList:picture,cargoPickUpPictureList:picture})).code,409);
    assert.equal((await api('/driver/tasks/details/'+original.id)).data.status,2);
    const exception = {transportTaskId:original.transportTaskId,exceptionTime:'2026-10-07 20:00',exceptionPlace:'模拟站',exceptionType:'漏油',exceptionImagesList:picture};
    assert.equal((await api('/driver/tasks/reportException','POST',{...exception,transportTaskId:original.id})).code,404);
    assert.equal((await api('/driver/tasks/reportException','POST',{...exception,exceptionType:'不着车、漏油'})).code,400);
    assert.equal((await api('/driver/tasks/reportException','POST',exception)).code,'200');
    assert.equal((await api('/driver/tasks/deliver','POST',{id:original.id,certificatePictureList:picture,deliverPictureList:picture})).code,200);
    assert.equal((await api('/driver/tasks/truckRegistration','POST',{id:original.transportTaskId,startTime:'2026-10-07 18:00:00',endTime:'2026-10-07 21:00:00'})).code,200);
    assert.equal((await api('/driver/users')).data.number,'SJ310027');
    assert.equal((await api('/driver/users/taskReport?year=2026&month=10')).code,200);
    await stop(); base = await start();
    const detail = (await api('/driver/tasks/details/'+original.id)).data;
    assert.equal(detail.status,6);assert.equal(detail.exceptionList.length,1);assert.equal(detail.cargoPictureList[0].url,upload.data);
    assert.equal((await api('/driver/tasks/list?page=1&pageSize=20&status=6')).data.counts,initialFinished + 1);
  } finally {
    if(server?.listening) await stop();
    fs.rmSync(dataDir,{recursive:true,force:true});
  }
});
