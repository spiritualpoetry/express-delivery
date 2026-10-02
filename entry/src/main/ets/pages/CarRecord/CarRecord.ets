import { HmCard, HmCardItem, HmNavBar } from '@hm/basic'

@Entry
@Component
struct CarRecord {

  build() {
    Column(){
      HmNavBar({title:"回车登记"})
      Column(){
        HmCard(){
          HmCardItem({leftTitle:"出车时间",rightText:"2022.05.04",showRightIcon:false})
          HmCardItem({leftTitle:"回车时间",rightText:"请选择"})

        }
      }
    }

  }
}