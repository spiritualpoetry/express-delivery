export * from './advert'
export * from './tabs'

export class  ResponseData<T>{
  code:number=0
  msg:string=''
  data:null|T=null
}
//泛型