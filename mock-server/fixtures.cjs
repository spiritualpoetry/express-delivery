const ROUTES = [
  ['北京市','北京市','顺义空港分拨中心','天津市','天津市','东丽配送中心',3],
  ['上海市','上海市','青浦华新分拨中心','江苏省','苏州市','昆山陆家配送中心',2],
  ['广东省','广州市','白云物流中心','广东省','深圳市','龙岗配送中心',4],
  ['浙江省','杭州市','萧山分拨中心','浙江省','宁波市','北仑配送中心',3],
  ['四川省','成都市','新都物流中心','重庆市','重庆市','渝北配送中心',5],
  ['湖北省','武汉市','东西湖分拨中心','湖南省','长沙市','望城配送中心',6]
];
const pad = n => String(n).padStart(2,'0');
const stamp = d => `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
function createWaitingTask(id, transportTaskId, index, now = new Date()) {
  const r = ROUTES[index % ROUTES.length];
  const departure = new Date(now); departure.setMinutes(0,0,0); departure.setHours(departure.getHours()+1+index*2);
  const arrival = new Date(departure); arrival.setHours(arrival.getHours()+r[6]);
  const created = new Date(now); created.setHours(created.getHours()-12);
  return {
    id, transportTaskId, status:1, enablePickUp:true,
    driverId:'mock-driver', driverName:'陈志远', licensePlate:`京B${String(23001 + index).padStart(5,'0')}`,
    startAgencyId:String(11001+index), endAgencyId:String(21001+index),
    startProvince:r[0], startCity:r[1], startAddress:r[0]+r[1]+r[2],
    endProvince:r[3], endCity:r[4], endAddress:r[3]+r[4]+r[5],
    startHandoverName:['王师傅','李师傅','赵师傅'][index%3]+'', startHandoverPhone:'',
    finishHandoverName:['周师傅','刘师傅','吴师傅'][index%3]+'', finishHandoverPhone:'',
    created:stamp(created), planDepartureTime:stamp(departure), planArrivalTime:stamp(arrival),
    actualDepartureTime:'', actualArrivalTime:'',
    cargoPickUpPictureList:[], cargoPictureList:[], certificatePictureList:[], deliverPictureList:[], exceptionList:[]
  };
}
module.exports={createWaitingTask};
