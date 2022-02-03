extension HL7 {
  class V23: Versioned {
      override func type(forName name:String) -> Typable? {
          switch name {
              case "ACK"     : return ACK()
              case "MFK_M01" : return MFK_M01()
              case "OMD_O01" : return OMD_O01()
              case "OMN_O01" : return OMN_O01()
              case "OMS_O01" : return OMS_O01()
              case "ORD_O02" : return ORD_O02()
              case "ORM_O01" : return ORM_O01()
              case "ORN_O02" : return ORN_O02()
              case "ORR_O02" : return ORR_O02()
              case "RDO_O01" : return RDO_O01()
              case "RRO_O02" : return RRO_O02()
      default: return nil
      }


    }
    
    class ACK: Typable {
         var name:String = "ACK"
    }

      class MFK_M01: Typable {
          var name:String = "MFK_M01"

    }

      class OMD_O01: Typable {
          var name:String = "OMD_O01"

    }

      class OMN_O01: Typable {
          var name:String = "OMN_O01"

    }

      class OMS_O01: Typable {
          var name:String = "OMS_O01"

    }

      class ORD_O02: Typable {
          var name:String = "ORD_O02"

    }

      class ORM_O01: Typable {
          var name:String = "ORM_O01"

    }

      class ORN_O02: Typable {
          var name:String = "ORN_O02"

    }

      class ORR_O02: Typable {
          var name:String = "ORR_O02"

    }

      class RDO_O01: Typable {
          var name:String = "RDO_O01"

    }

      class RRO_O02: Typable {
          var name:String = "RRO_O02"

    }


  }


}

