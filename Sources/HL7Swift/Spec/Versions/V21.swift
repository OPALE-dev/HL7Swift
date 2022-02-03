extension HL7 {
  class V21: Versioned {
        override func type(forName name:String) -> Typable? {
            switch name {
                case "ACK"     : return ACK()
        default: return nil
        }


      }
      
      class ACK: Typable {
           var name:String = "ACK"
      }

    }

}

