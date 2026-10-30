const ROUTES = [
  ['上海市','上海市','青浦区华新集配站','江苏省','苏州市','昆山市陆家配送站',2],
  ['江苏省','苏州市','昆山市陆家配送站','江苏省','无锡市','新吴区城南配送站',2],
  ['江苏省','无锡市','新吴区城南配送站','江苏省','常州市','武进区湖塘集配站',2],
  ['江苏省','常州市','武进区湖塘集配站','浙江省','杭州市','余杭区仁和配送站',4],
  ['浙江省','杭州市','余杭区仁和配送站','浙江省','嘉兴市','南湖区城东配送站',2],
  ['浙江省','嘉兴市','南湖区城东配送站','上海市','上海市','青浦区华新集配站',2]
];
const CONTACTS = ['王建明', '李文斌', '赵海峰', '周立新', '刘晓东', '吴志强'];
const DRIVER = { name: '陈志远', number: 'SJ310027', phone: '' };
const TRUCK = { id: 'SH-0072', licensePlate: '沪B76258', allowableLoad: '12吨',
  currentOrganName: '华东运输部 · 青浦车队', truckType: '9.6米厢式货车', pictureList: [] };
const pad = n => String(n).padStart(2,'0');
const stamp = d => `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
function createWaitingTask(id, transportTaskId, index, now = new Date()) {
  const r = ROUTES[index % ROUTES.length];
  const departure = new Date(now);
  departure.setDate(departure.getDate() + 1 + Math.floor(index / 3));
  departure.setHours(6 + (index % 3) * 5, 30, 0, 0);
  const arrival = new Date(departure); arrival.setHours(arrival.getHours()+r[6]);
  const created = new Date(now); created.setHours(created.getHours()-12);
  return {
    id, transportTaskId, status:1, enablePickUp:true,
    driverId:'mock-driver', driverName:DRIVER.name, licensePlate:TRUCK.licensePlate,
    startAgencyId:String(310100+index%6), endAgencyId:String(310100+(index+1)%6),
    startProvince:r[0], startCity:r[1], startAddress:(r[0]===r[1] ? r[1] : r[0]+r[1])+r[2],
    endProvince:r[3], endCity:r[4], endAddress:(r[3]===r[4] ? r[4] : r[3]+r[4])+r[5],
    startHandoverName:CONTACTS[index%6], startHandoverPhone:'',
    finishHandoverName:CONTACTS[(index+1)%6], finishHandoverPhone:'',
    created:stamp(created), planDepartureTime:stamp(departure), planArrivalTime:stamp(arrival),
    actualDepartureTime:'', actualArrivalTime:'',
    cargoPickUpPictureList:[], cargoPictureList:[], certificatePictureList:[], deliverPictureList:[], exceptionList:[]
  };
}
function taskDispatchContent(task) {
  return `运输任务${task.transportTaskId}已下发。${task.startAddress} → ${task.endAddress}；计划提货${task.planDepartureTime}，预计送达${task.planArrivalTime}。装车前请与${task.startHandoverName}核对件数及封签，交接后及时上传回单。`;
}
const ANNOUNCEMENTS = [
  { id: 1, title: '装车与回单交接要求', content: '装车前核对运单、件数和货物外包装，确认封签号后发车。到站后与收货联系人共同清点，签收回单应包含日期和签收信息，拍照时请保持文字清晰、四角完整。' },
  { id: 9001, title: '雨雾天气行车提醒', content: '出车前检查雨刷、灯光和轮胎。遇雨雾天气降低车速、保持安全车距；需要临时停车时选择安全区域，并及时向调度说明位置及预计延误时间。' },
  { id: 9002, title: '到站卸货预约安排', content: '请在预计到站前30分钟与站点交接人确认卸货月台。未完成到站登记前，请按现场指引停放车辆，装卸区域禁止长时间占道。' },
  { id: 9003, title: '车辆出车检查', content: '每日首趟出车前检查制动、胎压、油液和随车证件。发现漏油、异响或仪表报警时停止发车，说明故障现象并上报车辆异常。' },
  { id: 9004, title: '运输异常信息填写要求', content: '发生故障或延误时，请填写实际发生时间、位置及影响情况，并上传现场照片。预计到达时间变化后，及时联系调度与收货站点，避免重复报送同一异常。' }
];
module.exports={createWaitingTask, DRIVER, TRUCK, ANNOUNCEMENTS, taskDispatchContent};
