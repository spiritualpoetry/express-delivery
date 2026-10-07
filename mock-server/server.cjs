// Local demo backend: uses Node built-ins only, no dependency installation.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const os = require('node:os');
const TOKEN = 'mock-driver-demo-token';
const TYPES = ['发动机启动困难', '不着车', '漏油', '漏水', '照明失灵', '有异响', '排烟异常', '温度异常', '其他'];
const PIXEL = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII=', 'base64');
const pad = n => String(n).padStart(2, '0');
function stamp(d = new Date()) {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}
function seed() {
  const { createWaitingTask } = require('./fixtures.cjs');
  return { tasks:Array.from({length:24},(_,i)=>createWaitingTask(`job-${i+1}`,String(100001+i),i)) };
}
function check(condition, message, status = 400) {
  if (!condition) throw Object.assign(new Error(message), { status });
}
function text(value) { return typeof value === 'string' ? value.trim() : ''; }
function validTime(value, seconds = false) {
  if (typeof value !== 'string') return false;
  const pattern = seconds ? /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ : /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/;
  if (!pattern.test(value)) return false;
  const date = new Date(value.replace(' ', 'T'));
  return Number.isFinite(date.getTime()) && stamp(date).slice(0, seconds ? 19 : 16) === value;
}
function images(value, required = false, max = 6) {
  const list = value === undefined ? [] : value;
  check(Array.isArray(list) && list.length <= max && (!required || list.length > 0), '图片数量不正确');
  check(list.every(item => item && /^https?:\/\//.test(text(item.url))), '图片必须先上传并提供 HTTP URL');
  return list.map(item => ({ url: item.url }));
}
async function body(req, limit) {
  const chunks = []; let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    check(size <= limit, '上传内容过大', 413);
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}
function multipart(buffer, contentType) {
  const boundary = /boundary=(?:"([^"]+)"|([^;\s]+))/i.exec(contentType);
  check(boundary, '缺少 multipart boundary');
  const marker = Buffer.from('--' + (boundary[1] || boundary[2]));
  let cursor = buffer.indexOf(marker), file;
  while (cursor >= 0) {
    const start = cursor + marker.length;
    if (buffer.subarray(start, start + 2).toString() === '--') break;
    const headerEnd = buffer.indexOf('\r\n\r\n', start);
    check(headerEnd >= 0, 'multipart 格式错误');
    const next = buffer.indexOf(Buffer.concat([Buffer.from('\r\n'), marker]), headerEnd + 4);
    check(next >= 0, 'multipart 未完整结束');
    const headers = buffer.subarray(start, headerEnd).toString();
    if (/\bname="file"/.test(headers)) {
      check(!file, '每次只上传一张图片');
      file = buffer.subarray(headerEnd + 4, next);
    }
    cursor = next + 2;
  }
  check(file && file.length, '缺少 file 图片');
  let extension;
  if (file.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) extension = 'png';
  else if (file[0] === 255 && file[1] === 216 && file[2] === 255) extension = 'jpg';
  else if (file.subarray(0, 4).toString() === 'RIFF' && file.subarray(8, 12).toString() === 'WEBP') extension = 'webp';
  check(extension, '模拟上传支持 PNG、JPEG、WebP 图片');
  return { file, extension };
}
function createServer(options = {}) {
  const dir = options.dataDir || process.env.MOCK_DATA_DIR || path.join(__dirname, 'data');
  const uploads = path.join(dir, 'uploads');
  const storePath = path.join(dir, 'db.json');
  fs.mkdirSync(uploads, { recursive: true });
  let db = fs.existsSync(storePath) ? JSON.parse(fs.readFileSync(storePath, 'utf8')) : seed();
  function save(next) {
    fs.writeFileSync(storePath + '.tmp', JSON.stringify(next, null, 2));
    fs.renameSync(storePath + '.tmp', storePath);
    db = next;
  }
  if (!fs.existsSync(storePath)) save(db);
  const server = http.createServer(async (req, res) => {
    function respond(code, data = null, msg = '成功', httpStatus = 200) {
      res.writeHead(httpStatus, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' });
      res.end(JSON.stringify({ code, data, msg }));
    }
    try {
      const url = new URL(req.url, 'http://localhost');
      const route = url.pathname;
      const origin = options.publicUrl || process.env.MOCK_PUBLIC_URL || `http://${req.headers.host}`;
      if (req.method === 'GET' && route === '/health') return respond(200, { mock: true, tasks: db.tasks.length });
      if (req.method === 'GET' && route === '/demo.png') {
        res.writeHead(200, { 'Content-Type': 'image/png' }); return res.end(PIXEL);
      }
      if (req.method === 'GET' && route === '/assets/driver.svg') {
        res.writeHead(200, { 'Content-Type':'image/svg+xml' });
        return fs.createReadStream(path.join(__dirname,'assets','driver.svg')).pipe(res);
      }
      if (req.method === 'GET' && route.startsWith('/uploads/')) {
        const name = route.slice('/uploads/'.length);
        check(/^[a-f0-9-]+\.(png|jpg|webp)$/.test(name), '图片不存在', 404);
        const imagePath = path.join(uploads, name);
        check(fs.existsSync(imagePath), '图片不存在', 404);
        res.writeHead(200, { 'Content-Type': {png:'image/png', jpg:'image/jpeg', webp:'image/webp'}[name.split('.').pop()] });
        return fs.createReadStream(imagePath).pipe(res);
      }
      if (req.method === 'POST' && route === '/driver/login/account') {
        const form = JSON.parse((await body(req, 1024 * 1024)).toString());
        check(form.account === 'demo' && form.password === 'mock123456', '模拟账号或密码错误', 401);
        // App reads data as token; msg also contains it to match the supplied login description.
        return respond(200, TOKEN, TOKEN);
      }
      check(text(req.headers.authorization).replace(/^Bearer\s+/i, '') === TOKEN, '请使用模拟账号登录', 401);
      if (req.method === 'GET' && route === '/driver/users') return respond(200, {
        name: '陈志远（演示）', number: 'MOCK001', phone: '', avatar: origin + '/assets/driver.svg'
      });
      if (req.method === 'GET' && route === '/driver/users/taskReport') {
        const year = Number(url.searchParams.get('year')), month = Number(url.searchParams.get('month'));
        check(Number.isInteger(year) && year >= 2000 && Number.isInteger(month) && month >= 1 && month <= 12, '年月不正确');
        const prefix = `${year}-${pad(month)}`;
        const finished = db.tasks.filter(t => t.status === 6 && t.actualArrivalTime.startsWith(prefix));
        return respond(200, { completedAmounts: finished.length,
          taskAmounts: db.tasks.filter(t => t.planArrivalTime.startsWith(prefix)).length,
          transportMileage: finished.length * 20,
          dailyMileage: Array.from({ length: new Date(year, month, 0).getDate() }, (_, i) => ({
            dateTime: `${prefix}-${pad(i + 1)} 00:00:00`,
            mileage: finished.filter(t => t.actualArrivalTime.startsWith(`${prefix}-${pad(i + 1)}`)).length * 20
          })) });
      }
      if (req.method === 'GET' && route === '/driver/tasks/list') {
        const q = url.searchParams, page = Number(q.get('page')), pageSize = Number(q.get('pageSize')), status = Number(q.get('status'));
        check(Number.isInteger(page) && page >= 1 && Number.isInteger(pageSize) && pageSize >= 1 && pageSize <= 100, '分页参数不正确');
        check([1,2,3,5,6].includes(status), '任务列表状态不正确');
        for (const field of ['startTime', 'endTime']) if(q.get(field)) check(validTime(q.get(field) + ' 00:00'), '日期格式应为 yyyy-MM-dd');
        check(!q.get('startTime') || !q.get('endTime') || q.get('startTime') <= q.get('endTime'), '开始时间不能晚于结束时间');
        const rows = db.tasks.filter(t => (status === 2 ? [2,4].includes(t.status) : t.status === status)
          && (!q.get('transportTaskId') || t.transportTaskId === q.get('transportTaskId'))
          && (!q.get('startTime') || t.planDepartureTime.slice(0,10) >= q.get('startTime'))
          && (!q.get('endTime') || t.planDepartureTime.slice(0,10) <= q.get('endTime')));
        return respond(200, { counts: rows.length, page, pageSize, pages: Math.ceil(rows.length/pageSize),
          items: rows.slice((page-1)*pageSize, page*pageSize).map(t => ({...t, status:String(t.status),
            startAgencyId:Number(t.startAgencyId), endAgencyId:Number(t.endAgencyId),
            startHandover:t.startHandoverName, finishHandover:t.finishHandoverName })) });
      }
      if (req.method === 'GET' && route.startsWith('/driver/tasks/details/')) {
        const task = db.tasks.find(t => t.id === decodeURIComponent(route.slice('/driver/tasks/details/'.length)));
        check(task, '作业单不存在', 404); return respond(200, task);
      }
      if (req.method === 'POST' && route === '/driver/files/imageUpload') {
        const { file, extension } = multipart(await body(req, 12 * 1024 * 1024), req.headers['content-type'] || '');
        const name = `${crypto.randomUUID()}.${extension}`;
        fs.writeFileSync(path.join(uploads, name), file);
        return respond(200, origin + '/uploads/' + name);
      }
      const methods = {'/driver/tasks/takeDelivery':'POST', '/driver/tasks/deliver':'POST',
        '/driver/tasks/truckRegistration':'POST', '/driver/tasks/delay':'PUT', '/driver/tasks/reportException':'POST'};
      check(methods[route] === req.method, '模拟接口不存在或请求方法错误', 404);
      const form = JSON.parse((await body(req, 1024 * 1024)).toString());
      check(form && typeof form === 'object' && !Array.isArray(form), '请求体必须是对象');
      const next = JSON.parse(JSON.stringify(db));
      const transport = ['/driver/tasks/reportException','/driver/tasks/truckRegistration'].includes(route);
      const id = route.endsWith('reportException') ? form.transportTaskId : form.id;
      const task = next.tasks.find(t => (transport ? t.transportTaskId : t.id) === id);
      check(task, transport ? '运输任务不存在' : '作业单不存在', 404);
      if (route.endsWith('takeDelivery')) {
        check(task.status === 1, '只有待提货任务可以提货', 409);
        task.cargoPickUpPictureList = images(form.cargoPickUpPictureList, true);
        task.cargoPictureList = images(form.cargoPictureList, true);
        task.status = 2; task.enablePickUp = false; task.actualDepartureTime = stamp();
      } else if (route.endsWith('/deliver')) {
        check(task.status === 2, '只有在途任务可以交付', 409);
        task.certificatePictureList = images(form.certificatePictureList, true);
        task.deliverPictureList = images(form.deliverPictureList, true);
        task.status = 4; task.actualArrivalTime = stamp();
      } else if (route.endsWith('truckRegistration')) {
        check(task.status === 4, '只有已交付任务可以回车登记', 409);
        check(validTime(form.startTime, true) && validTime(form.endTime, true) && form.startTime <= form.endTime, '出车和回车时间格式或顺序不正确');
        task.registration = form; task.status = 6;
      } else if (route.endsWith('/delay')) {
        check(task.status === 1, '只有待提货任务可以延迟提货', 409);
        check(text(form.delayReason) && validTime(form.delayTime), '延迟原因或时间不正确');
        task.delayReason = form.delayReason; task.delayTime = form.delayTime;
        task.planDepartureTime = form.delayTime + ':00';
      } else {
        check([2,4].includes(task.status), '模拟规则：在途或已交付任务可以上报异常', 409);
        check(validTime(form.exceptionTime) && text(form.exceptionPlace) && TYPES.includes(form.exceptionType), '异常时间、位置或类型不正确');
        check(form.exceptionDescribe === undefined || (typeof form.exceptionDescribe === 'string' && form.exceptionDescribe.length <= 200), '描述最多200字');
        task.exceptionList.push({ exceptionTime:form.exceptionTime, exceptionPlace:form.exceptionPlace,
          exceptionType:form.exceptionType, exceptionDescribe:form.exceptionDescribe || '',
          exceptionImagesList:images(form.exceptionImagesList), handleResult:'待处理' });
      }
      save(next);
      return respond(route.endsWith('reportException') ? '200' : 200);
    } catch (error) {
      const status = error.status || (error instanceof SyntaxError ? 400 : 500);
      if (!res.headersSent && !res.destroyed) respond(status, null, status === 500 ? '模拟服务内部错误' : error.message);
    }
  });
  return server;
}
if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  const server = createServer();
  server.on('error', error => { console.error('启动失败:', error.message); process.exitCode = 1; });
  server.listen(port, '0.0.0.0', () => {
    console.log(`Mock server: http://127.0.0.1:${port}/health`);
    for (const entries of Object.values(os.networkInterfaces())) for (const item of entries || [])
      if(item.family === 'IPv4' && !item.internal) console.log(`App BASE_URL: http://${item.address}:${port}/driver`);
    console.log('Demo login: demo / mock123456. Stop with Ctrl+C.');
  });
}
module.exports = { createServer };
