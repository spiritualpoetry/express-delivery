const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createWaitingTask, TRUCK } = require('./fixtures.cjs');
const { refreshBusinessData } = require('./refresh-business-data.cjs');

test('regional schedule has coherent addresses, vehicle and rest gaps', () => {
  const now = new Date('2026-10-30T21:00:00');
  const tasks = Array.from({ length: 12 }, (_, i) => createWaitingTask(`job-${i}`, String(100000+i), i, now));
  for (const [i, task] of tasks.entries()) {
    assert.equal(task.licensePlate, TRUCK.licensePlate);
    assert.doesNotMatch(task.startAddress + task.endAddress, /上海市上海市|演示|模拟/);
    assert.ok(new Date(task.planDepartureTime.replace(' ', 'T')) > now);
    assert.ok(task.planArrivalTime > task.planDepartureTime);
    if (i) {
      assert.equal(task.startAddress, tasks[i-1].endAddress);
      assert.ok(task.planDepartureTime > tasks[i-1].planArrivalTime);
    }
  }
});

test('refresh preserves business records and read receipts without duplication', () => {
  const tasks = [createWaitingTask('job-a', '100001', 0), createWaitingTask('job-b', '100002', 1)];
  tasks[1].status = 6;
  tasks[1].planDepartureTime = '2026-10-09 22:34:00';
  tasks[1].planArrivalTime = '2026-10-08 02:00:00';
  tasks[1].actualDepartureTime = '2026-10-07 22:35:08';
  tasks[1].actualArrivalTime = '2026-10-07 22:57:57';
  tasks[1].cargoPictureList = [{ url: 'http://host/existing.jpg' }];
  tasks[1].exceptionList = [{ exceptionDescribe: '已有记录' }];
  tasks[1].registration = { startTime: 'existing' };
  const messages = [{ id: 2, contentType: 201, relevantId: 'job-b', isRead: 1, readTime: '2026-10-08 08:00:00', created: '2026-10-07 08:00:00' }];
  const before = { tasks, messages, custom: 'keep' };
  const original = JSON.stringify(before);
  const now = new Date('2026-10-30T21:00:00');
  const after = refreshBusinessData(before, now);
  assert.equal(JSON.stringify(before), original);
  for (const [i, task] of after.tasks.entries()) {
    for (const key of ['id', 'transportTaskId', 'status', 'actualDepartureTime', 'actualArrivalTime',
      'cargoPictureList', 'exceptionList', 'registration']) assert.deepEqual(task[key], before.tasks[i][key]);
    assert.ok(task.planArrivalTime >= task.planDepartureTime);
  }
  assert.ok(after.tasks[0].planDepartureTime.startsWith('2026-10-31'));
  for (const key of ['isRead', 'readTime', 'created']) assert.equal(after.messages[0][key], messages[0][key]);
  assert.match(after.messages[0].content, /100002.*计划提货/);
  assert.equal(after.custom, 'keep');
  assert.equal(after.messages.filter(m => m.contentType === 200).length, 5);
  assert.deepEqual(refreshBusinessData(after, now), after);
});
