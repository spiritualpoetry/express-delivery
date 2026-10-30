const fs = require('node:fs');
const path = require('node:path');
const { createWaitingTask, ANNOUNCEMENTS, taskDispatchContent } = require('./fixtures.cjs');
const stamp = date => {
  const pad = value => String(value).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth()+1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
};

function refreshBusinessData(db, now = new Date()) {
  const next = JSON.parse(JSON.stringify(db));
  let waitingIndex = 0;
  next.tasks = next.tasks.map((task, i) => {
    const sample = createWaitingTask(task.id, task.transportTaskId, task.status === 1 ? waitingIndex++ : i, now);
    const fields = ['driverName', 'licensePlate', 'startAgencyId', 'endAgencyId', 'startProvince', 'startCity',
      'startAddress', 'endProvince', 'endCity', 'endAddress', 'startHandoverName', 'finishHandoverName'];
    for (const field of fields) task[field] = sample[field];
    if (task.status === 1) {
      task.planDepartureTime = sample.planDepartureTime;
      task.planArrivalTime = sample.planArrivalTime;
    } else {
      // Preserve actual events; repair inconsistent old planned times around those events.
      const departure = new Date((task.actualDepartureTime || task.planDepartureTime).replace(' ', 'T'));
      if (Number.isFinite(departure.getTime())) {
        task.planDepartureTime = stamp(departure);
        const actualArrival = new Date((task.actualArrivalTime || '').replace(' ', 'T'));
        const duration = new Date(sample.planArrivalTime.replace(' ', 'T')) - new Date(sample.planDepartureTime.replace(' ', 'T'));
        task.planArrivalTime = stamp(Number.isFinite(actualArrival.getTime()) && actualArrival >= departure
          ? actualArrival : new Date(departure.getTime() + duration));
      }
    }
    return task;
  });
  for (const message of next.messages || []) {
    const task = next.tasks.find(task => String(task.id) === String(message.relevantId));
    if (message.contentType === 201 && task) {
      const title = `运输任务${task.transportTaskId}派车通知`;
      const content = taskDispatchContent(task);
      if (message.title !== title || message.content !== content) {
        message.title = title;
        message.content = content;
        message.updated = stamp(now);
      }
    }
    if (message.contentType === 200 && message.id === 1) {
      if (message.title !== ANNOUNCEMENTS[0].title || message.content !== ANNOUNCEMENTS[0].content) {
        message.title = ANNOUNCEMENTS[0].title;
        message.content = ANNOUNCEMENTS[0].content;
        message.updated = stamp(now);
      }
    }
  }
  next.messages = next.messages || [];
  for (const [i, announcement] of ANNOUNCEMENTS.entries()) {
    if (next.messages.some(message => message.id === announcement.id)) continue;
    const created = stamp(new Date(now.getTime() - (i + 1) * 86400000));
    next.messages.push({ ...announcement, bussinessType: 2, contentType: 200, created, updated: created,
      createUser: 0, updateUser: 0, userId: 1, relevantId: '', isRead: 0, readTime: '' });
  }
  return next;
}

if (require.main === module) {
  // Run with the API stopped to avoid overwriting concurrent business operations.
  const file = path.join(process.env.MOCK_DATA_DIR || path.join(__dirname, 'data'), 'db.json');
  const before = JSON.parse(fs.readFileSync(file, 'utf8'));
  const next = refreshBusinessData(before);
  const backup = file + `.before-business-${Date.now()}.bak`;
  fs.copyFileSync(file, backup);
  fs.writeFileSync(file + '.tmp', JSON.stringify(next, null, 2));
  fs.renameSync(file + '.tmp', file);
  console.log(JSON.stringify({ backup, tasks: next.tasks.length, messages: next.messages.length }));
}
module.exports = { refreshBusinessData };
