// Update display labels only; preserve IDs, state, credentials, pictures and user-entered records.
const fs = require('node:fs');
const path = require('node:path');

function normalizeDisplay(db) {
  const next = JSON.parse(JSON.stringify(db));
  for (const task of next.tasks || []) {
    for (const field of ['driverName', 'startAddress', 'endAddress', 'startHandoverName', 'finishHandoverName']) {
      if (typeof task[field] === 'string') task[field] = task[field].replaceAll('（演示）', '');
    }
  }
  for (const message of next.messages || []) {
    if (typeof message.content === 'string') {
      message.content = message.content.replaceAll('（演示）', '');
      if (message.content === '欢迎使用本地模拟服务，所有任务与消息均为演示数据。') {
        message.content = '欢迎使用司机服务，请及时查看运输任务与通知。';
      }
    }
    if (message.title === '本地演示公告') message.title = '系统公告';
  }
  return next;
}

if (require.main === module) {
  // Stop the service before running, so in-memory state cannot overwrite the change.
  const file = path.join(process.env.MOCK_DATA_DIR || path.join(__dirname, 'data'), 'db.json');
  const before = JSON.parse(fs.readFileSync(file, 'utf8'));
  const next = normalizeDisplay(before);
  if (JSON.stringify(before) !== JSON.stringify(next)) {
    const backup = file + `.before-display-${Date.now()}.bak`;
    fs.copyFileSync(file, backup);
    fs.writeFileSync(file + '.tmp', JSON.stringify(next, null, 2));
    fs.renameSync(file + '.tmp', file);
    console.log(JSON.stringify({ updated: true, backup, tasks: next.tasks.length }));
  } else console.log(JSON.stringify({ updated: false }));
}
module.exports = { normalizeDisplay };
