// Run only while the mock server is stopped. This script intentionally clears non-waiting tasks.
const fs=require('node:fs');
const path=require('node:path');
const {createWaitingTask}=require('./fixtures.cjs');
const dir=process.env.MOCK_DATA_DIR || path.join(__dirname,'data');
const file=path.join(dir,'db.json');
const db=JSON.parse(fs.readFileSync(file,'utf8'));
const backup=file+`.before-clean-${Date.now()}.bak`;
fs.copyFileSync(file,backup);
const waiting=db.tasks.filter(t=>Number(t.status)===1);
const tasks=waiting.map((task,index)=>({
  ...task,...createWaitingTask(task.id,task.transportTaskId,index),
  cargoPickUpPictureList:task.cargoPickUpPictureList || [],cargoPictureList:task.cargoPictureList || [],
  certificatePictureList:task.certificatePictureList || [],deliverPictureList:task.deliverPictureList || [],
  exceptionList:task.exceptionList || []
}));
fs.writeFileSync(file+'.tmp',JSON.stringify({...db,tasks},null,2));
fs.renameSync(file+'.tmp',file);
console.log(JSON.stringify({preserved:tasks.length,removed:db.tasks.length-tasks.length,backup}));
