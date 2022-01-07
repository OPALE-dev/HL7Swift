extension HL7 {
  class V231: Versioned {
      override func type(forName name:String) -> Typable? {
          switch name {
              case "ACK" : return ACK()
              case "CRM_C01" : return CRM_C01()
              case "CSU_C09" : return CSU_C09()
              case "MFK_M01" : return MFK_M01()
              case "MFN_M01" : return MFN_M01()
              case "MFN_M02" : return MFN_M02()
              case "MFQ_M01" : return MFQ_M01()
              case "MFR_M01" : return MFR_M01()
              case "NMD_N02" : return NMD_N02()
              case "NMQ_N01" : return NMQ_N01()
              case "NMR_N01" : return NMR_N01()
              case "OMD_O01" : return OMD_O01()
              case "OMN_O01" : return OMN_O01()
              case "OMS_O01" : return OMS_O01()
              case "ORD_O02" : return ORD_O02()
              case "ORM_O01" : return ORM_O01()
              case "ORN_O02" : return ORN_O02()
              case "ORR_O02" : return ORR_O02()
              case "ORS_O02" : return ORS_O02()
              case "PEX_P07" : return PEX_P07()
              case "PGL_PC6" : return PGL_PC6()
              case "PPG_PCG" : return PPG_PCG()
              case "PPP_PCB" : return PPP_PCB()
              case "PPR_PC1" : return PPR_PC1()
              case "RDO_O01" : return RDO_O01()
              case "REF_I12" : return REF_I12()
              case "RPA_I08" : return RPA_I08()
              case "RQA_I08" : return RQA_I08()
              case "RRI_I12" : return RRI_I12()
              case "RRO_O02" : return RRO_O02()
              case "SIU_S12" : return SIU_S12()
              case "SRM_S01" : return SRM_S01()
              case "SRR_S01" : return SRR_S01()
      default: return nil
      }


    }

      class ACK: Typable {
          var name:String = "ACK"

    }

      class CRM_C01: Typable {
          var name:String = "CRM_C01"

    }

      class CSU_C09: Typable {
          var name:String = "CSU_C09"

    }

      class MFK_M01: Typable {
          var name:String = "MFK_M01"

    }

      class MFN_M01: Typable {
          var name:String = "MFN_M01"

    }

      class MFN_M02: Typable {
          var name:String = "MFN_M02"

    }

      class MFQ_M01: Typable {
          var name:String = "MFQ_M01"

    }

      class MFR_M01: Typable {
          var name:String = "MFR_M01"

    }

      class NMD_N02: Typable {
          var name:String = "NMD_N02"

    }

      class NMQ_N01: Typable {
          var name:String = "NMQ_N01"

    }

      class NMR_N01: Typable {
          var name:String = "NMR_N01"

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

      class ORS_O02: Typable {
          var name:String = "ORS_O02"

    }

      class PEX_P07: Typable {
          var name:String = "PEX_P07"

    }

      class PGL_PC6: Typable {
          var name:String = "PGL_PC6"

    }

      class PPG_PCG: Typable {
          var name:String = "PPG_PCG"

    }

      class PPP_PCB: Typable {
          var name:String = "PPP_PCB"

    }

      class PPR_PC1: Typable {
          var name:String = "PPR_PC1"

    }

      class RDO_O01: Typable {
          var name:String = "RDO_O01"

    }

      class REF_I12: Typable {
          var name:String = "REF_I12"

    }

      class RPA_I08: Typable {
          var name:String = "RPA_I08"

    }

      class RQA_I08: Typable {
          var name:String = "RQA_I08"

    }

      class RRI_I12: Typable {
          var name:String = "RRI_I12"

    }

      class RRO_O02: Typable {
          var name:String = "RRO_O02"

    }

      class SIU_S12: Typable {
          var name:String = "SIU_S12"

    }

      class SRM_S01: Typable {
          var name:String = "SRM_S01"

    }

      class SRR_S01: Typable {
          var name:String = "SRR_S01"

    }


  }


}

