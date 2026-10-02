export const DateFormat=(value:Date, includeSeconds:boolean=false):string=>{
  const year = value.getFullYear()
  const month = (value.getMonth() + 1).toString().padStart(2, '0')
  const day = value.getDate().toString().padStart(2, '0')
  const hour = value.getHours().toString().padStart(2, '0')
  const minute = value.getMinutes().toString().padStart(2, '0')

  const result = `${year}-${month}-${day} ${hour}:${minute}`
  return includeSeconds ? `${result}:${value.getSeconds().toString().padStart(2, '0')}` : result
}
