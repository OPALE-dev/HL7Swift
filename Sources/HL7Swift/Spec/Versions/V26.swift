extension HL7 {
  class V26: Versioned {
      override func type(forName name:String) -> Typable? {
          switch name {
              case "ACK" : return ACK()
              case "ADR_A19" : return ADR_A19()
              case "ADT_A01" : return ADT_A01()
              case "ADT_A02" : return ADT_A02()
              case "ADT_A03" : return ADT_A03()
              case "ADT_A05" : return ADT_A05()
              case "ADT_A06" : return ADT_A06()
              case "ADT_A09" : return ADT_A09()
              case "ADT_A12" : return ADT_A12()
              case "ADT_A15" : return ADT_A15()
              case "ADT_A16" : return ADT_A16()
              case "ADT_A17" : return ADT_A17()
              case "ADT_A18" : return ADT_A18()
              case "ADT_A20" : return ADT_A20()
              case "ADT_A21" : return ADT_A21()
              case "ADT_A24" : return ADT_A24()
              case "ADT_A30" : return ADT_A30()
              case "ADT_A37" : return ADT_A37()
              case "ADT_A38" : return ADT_A38()
              case "ADT_A39" : return ADT_A39()
              case "ADT_A43" : return ADT_A43()
              case "ADT_A45" : return ADT_A45()
              case "ADT_A50" : return ADT_A50()
              case "ADT_A52" : return ADT_A52()
              case "ADT_A54" : return ADT_A54()
              case "ADT_A60" : return ADT_A60()
              case "ADT_A61" : return ADT_A61()
              case "BAR_P01" : return BAR_P01()
              case "BAR_P02" : return BAR_P02()
              case "BAR_P05" : return BAR_P05()
              case "BAR_P06" : return BAR_P06()
              case "BAR_P10" : return BAR_P10()
              case "BAR_P12" : return BAR_P12()
              case "BPS_O29" : return BPS_O29()
              case "BRP_O30" : return BRP_O30()
              case "BRT_O32" : return BRT_O32()
              case "BTS_O31" : return BTS_O31()
              case "CRM_C01" : return CRM_C01()
              case "CSU_C09" : return CSU_C09()
              case "DFT_P03" : return DFT_P03()
              case "DFT_P11" : return DFT_P11()
              case "DOC_T12" : return DOC_T12()
              case "EAC_U07" : return EAC_U07()
              case "EAN_U09" : return EAN_U09()
              case "EAR_U08" : return EAR_U08()
              case "EHC_E01" : return EHC_E01()
              case "EHC_E02" : return EHC_E02()
              case "EHC_E04" : return EHC_E04()
              case "EHC_E10" : return EHC_E10()
              case "EHC_E12" : return EHC_E12()
              case "EHC_E13" : return EHC_E13()
              case "EHC_E15" : return EHC_E15()
              case "EHC_E20" : return EHC_E20()
              case "EHC_E21" : return EHC_E21()
              case "EHC_E24" : return EHC_E24()
              case "ESR_U02" : return ESR_U02()
              case "ESU_U01" : return ESU_U01()
              case "INR_U06" : return INR_U06()
              case "INU_U05" : return INU_U05()
              case "LSU_U12" : return LSU_U12()
              case "MDM_T01" : return MDM_T01()
              case "MDM_T02" : return MDM_T02()
              case "MFK_M01" : return MFK_M01()
              case "MFN_M01" : return MFN_M01()
              case "MFN_M02" : return MFN_M02()
              case "MFN_M03" : return MFN_M03()
              case "MFN_M04" : return MFN_M04()
              case "MFN_M05" : return MFN_M05()
              case "MFN_M06" : return MFN_M06()
              case "MFN_M07" : return MFN_M07()
              case "MFN_M08" : return MFN_M08()
              case "MFN_M09" : return MFN_M09()
              case "MFN_M10" : return MFN_M10()
              case "MFN_M11" : return MFN_M11()
              case "MFN_M12" : return MFN_M12()
              case "MFN_M13" : return MFN_M13()
              case "MFN_M15" : return MFN_M15()
              case "MFN_M16" : return MFN_M16()
              case "MFN_M17" : return MFN_M17()
              case "MFN_Znn" : return MFN_Znn()
              case "MFQ_M01" : return MFQ_M01()
              case "MFR_M01" : return MFR_M01()
              case "MFR_M04" : return MFR_M04()
              case "MFR_M05" : return MFR_M05()
              case "MFR_M06" : return MFR_M06()
              case "MFR_M07" : return MFR_M07()
              case "NMD_N02" : return NMD_N02()
              case "NMQ_N01" : return NMQ_N01()
              case "NMR_N01" : return NMR_N01()
              case "OMB_O27" : return OMB_O27()
              case "OMD_O03" : return OMD_O03()
              case "OMG_O19" : return OMG_O19()
              case "OMI_O23" : return OMI_O23()
              case "OML_O21" : return OML_O21()
              case "OML_O33" : return OML_O33()
              case "OML_O35" : return OML_O35()
              case "OMN_O07" : return OMN_O07()
              case "OMP_O09" : return OMP_O09()
              case "OMS_O05" : return OMS_O05()
              case "OPL_O37" : return OPL_O37()
              case "OPR_O38" : return OPR_O38()
              case "OPU_R25" : return OPU_R25()
              case "ORB_O28" : return ORB_O28()
              case "ORD_O04" : return ORD_O04()
              case "ORF_R04" : return ORF_R04()
              case "ORG_O20" : return ORG_O20()
              case "ORI_O24" : return ORI_O24()
              case "ORL_O22" : return ORL_O22()
              case "ORL_O34" : return ORL_O34()
              case "ORL_O36" : return ORL_O36()
              case "ORM_O01" : return ORM_O01()
              case "ORN_O08" : return ORN_O08()
              case "ORP_O10" : return ORP_O10()
              case "ORR_O02" : return ORR_O02()
              case "ORS_O06" : return ORS_O06()
              case "ORU_R01" : return ORU_R01()
              case "ORU_R30" : return ORU_R30()
              case "OSQ_Q06" : return OSQ_Q06()
              case "OSR_Q06" : return OSR_Q06()
              case "OUL_R21" : return OUL_R21()
              case "OUL_R22" : return OUL_R22()
              case "OUL_R23" : return OUL_R23()
              case "OUL_R24" : return OUL_R24()
              case "PEX_P07" : return PEX_P07()
              case "PGL_PC6" : return PGL_PC6()
              case "PMU_B01" : return PMU_B01()
              case "PMU_B03" : return PMU_B03()
              case "PMU_B04" : return PMU_B04()
              case "PMU_B07" : return PMU_B07()
              case "PMU_B08" : return PMU_B08()
              case "PPG_PCG" : return PPG_PCG()
              case "PPP_PCB" : return PPP_PCB()
              case "PPR_PC1" : return PPR_PC1()
              case "PPT_PCL" : return PPT_PCL()
              case "PPV_PCA" : return PPV_PCA()
              case "PRR_PC5" : return PRR_PC5()
              case "PTR_PCF" : return PTR_PCF()
              case "QBP_E03" : return QBP_E03()
              case "QBP_E22" : return QBP_E22()
              case "QBP_Q11" : return QBP_Q11()
              case "QBP_Q13" : return QBP_Q13()
              case "QBP_Q15" : return QBP_Q15()
              case "QBP_Q21" : return QBP_Q21()
              case "QBP_Qnn" : return QBP_Qnn()
              case "QBP_Z73" : return QBP_Z73()
              case "QCN_J01" : return QCN_J01()
              case "QRY_A19" : return QRY_A19()
              case "QRY_PC4" : return QRY_PC4()
              case "QRY_Q01" : return QRY_Q01()
              case "QRY_R02" : return QRY_R02()
              case "QRY_T12" : return QRY_T12()
              case "QSB_Q16" : return QSB_Q16()
              case "QVR_Q17" : return QVR_Q17()
              case "RAR_RAR" : return RAR_RAR()
              case "RAS_O17" : return RAS_O17()
              case "RCI_I05" : return RCI_I05()
              case "RCL_I06" : return RCL_I06()
              case "RDE_O11" : return RDE_O11()
              case "RDR_RDR" : return RDR_RDR()
              case "RDS_O13" : return RDS_O13()
              case "RDY_K15" : return RDY_K15()
              case "REF_I12" : return REF_I12()
              case "RER_RER" : return RER_RER()
              case "RGR_RGR" : return RGR_RGR()
              case "RGV_O15" : return RGV_O15()
              case "ROR_ROR" : return ROR_ROR()
              case "RPA_I08" : return RPA_I08()
              case "RPI_I01" : return RPI_I01()
              case "RPI_I04" : return RPI_I04()
              case "RPL_I02" : return RPL_I02()
              case "RPR_I03" : return RPR_I03()
              case "RQA_I08" : return RQA_I08()
              case "RQC_I05" : return RQC_I05()
              case "RQI_I01" : return RQI_I01()
              case "RQP_I04" : return RQP_I04()
              case "RRA_O18" : return RRA_O18()
              case "RRD_O14" : return RRD_O14()
              case "RRE_O12" : return RRE_O12()
              case "RRG_O16" : return RRG_O16()
              case "RRI_I12" : return RRI_I12()
              case "RSP_E03" : return RSP_E03()
              case "RSP_E22" : return RSP_E22()
              case "RSP_K11" : return RSP_K11()
              case "RSP_K21" : return RSP_K21()
              case "RSP_K23" : return RSP_K23()
              case "RSP_K25" : return RSP_K25()
              case "RSP_K31" : return RSP_K31()
              case "RSP_Q11" : return RSP_Q11()
              case "RSP_Z82" : return RSP_Z82()
              case "RSP_Z86" : return RSP_Z86()
              case "RSP_Z88" : return RSP_Z88()
              case "RSP_Z90" : return RSP_Z90()
              case "RTB_K13" : return RTB_K13()
              case "RTB_Z74" : return RTB_Z74()
              case "SDR_S31" : return SDR_S31()
              case "SDR_S32" : return SDR_S32()
              case "SIU_S12" : return SIU_S12()
              case "SLR_S28" : return SLR_S28()
              case "SQM_S25" : return SQM_S25()
              case "SQR_S25" : return SQR_S25()
              case "SRM_S01" : return SRM_S01()
              case "SRR_S01" : return SRR_S01()
              case "SSR_U04" : return SSR_U04()
              case "SSU_U03" : return SSU_U03()
              case "STC_S33" : return STC_S33()
              case "SUR_P09" : return SUR_P09()
              case "TCU_U10" : return TCU_U10()
              case "VXQ_V01" : return VXQ_V01()
              case "VXR_V03" : return VXR_V03()
              case "VXU_V04" : return VXU_V04()
              case "VXX_V02" : return VXX_V02()
      default: return nil
      }


    }

      class ACK: Typable {
          var name:String = "ACK"

    }

      class ADR_A19: Typable {
          var name:String = "ADR_A19"

    }

      class ADT_A01: Typable {
          var name:String = "ADT_A01"

    }

      class ADT_A02: Typable {
          var name:String = "ADT_A02"

    }

      class ADT_A03: Typable {
          var name:String = "ADT_A03"

    }

      class ADT_A05: Typable {
          var name:String = "ADT_A05"

    }

      class ADT_A06: Typable {
          var name:String = "ADT_A06"

    }

      class ADT_A09: Typable {
          var name:String = "ADT_A09"

    }

      class ADT_A12: Typable {
          var name:String = "ADT_A12"

    }

      class ADT_A15: Typable {
          var name:String = "ADT_A15"

    }

      class ADT_A16: Typable {
          var name:String = "ADT_A16"

    }

      class ADT_A17: Typable {
          var name:String = "ADT_A17"

    }

      class ADT_A18: Typable {
          var name:String = "ADT_A18"

    }

      class ADT_A20: Typable {
          var name:String = "ADT_A20"

    }

      class ADT_A21: Typable {
          var name:String = "ADT_A21"

    }

      class ADT_A24: Typable {
          var name:String = "ADT_A24"

    }

      class ADT_A30: Typable {
          var name:String = "ADT_A30"

    }

      class ADT_A37: Typable {
          var name:String = "ADT_A37"

    }

      class ADT_A38: Typable {
          var name:String = "ADT_A38"

    }

      class ADT_A39: Typable {
          var name:String = "ADT_A39"

    }

      class ADT_A43: Typable {
          var name:String = "ADT_A43"

    }

      class ADT_A45: Typable {
          var name:String = "ADT_A45"

    }

      class ADT_A50: Typable {
          var name:String = "ADT_A50"

    }

      class ADT_A52: Typable {
          var name:String = "ADT_A52"

    }

      class ADT_A54: Typable {
          var name:String = "ADT_A54"

    }

      class ADT_A60: Typable {
          var name:String = "ADT_A60"

    }

      class ADT_A61: Typable {
          var name:String = "ADT_A61"

    }

      class BAR_P01: Typable {
          var name:String = "BAR_P01"

    }

      class BAR_P02: Typable {
          var name:String = "BAR_P02"

    }

      class BAR_P05: Typable {
          var name:String = "BAR_P05"

    }

      class BAR_P06: Typable {
          var name:String = "BAR_P06"

    }

      class BAR_P10: Typable {
          var name:String = "BAR_P10"

    }

      class BAR_P12: Typable {
          var name:String = "BAR_P12"

    }

      class BPS_O29: Typable {
          var name:String = "BPS_O29"

    }

      class BRP_O30: Typable {
          var name:String = "BRP_O30"

    }

      class BRT_O32: Typable {
          var name:String = "BRT_O32"

    }

      class BTS_O31: Typable {
          var name:String = "BTS_O31"

    }

      class CRM_C01: Typable {
          var name:String = "CRM_C01"

    }

      class CSU_C09: Typable {
          var name:String = "CSU_C09"

    }

      class DFT_P03: Typable {
          var name:String = "DFT_P03"

    }

      class DFT_P11: Typable {
          var name:String = "DFT_P11"

    }

      class DOC_T12: Typable {
          var name:String = "DOC_T12"

    }

      class EAC_U07: Typable {
          var name:String = "EAC_U07"

    }

      class EAN_U09: Typable {
          var name:String = "EAN_U09"

    }

      class EAR_U08: Typable {
          var name:String = "EAR_U08"

    }

      class EHC_E01: Typable {
          var name:String = "EHC_E01"

    }

      class EHC_E02: Typable {
          var name:String = "EHC_E02"

    }

      class EHC_E04: Typable {
          var name:String = "EHC_E04"

    }

      class EHC_E10: Typable {
          var name:String = "EHC_E10"

    }

      class EHC_E12: Typable {
          var name:String = "EHC_E12"

    }

      class EHC_E13: Typable {
          var name:String = "EHC_E13"

    }

      class EHC_E15: Typable {
          var name:String = "EHC_E15"

    }

      class EHC_E20: Typable {
          var name:String = "EHC_E20"

    }

      class EHC_E21: Typable {
          var name:String = "EHC_E21"

    }

      class EHC_E24: Typable {
          var name:String = "EHC_E24"

    }

      class ESR_U02: Typable {
          var name:String = "ESR_U02"

    }

      class ESU_U01: Typable {
          var name:String = "ESU_U01"

    }

      class INR_U06: Typable {
          var name:String = "INR_U06"

    }

      class INU_U05: Typable {
          var name:String = "INU_U05"

    }

      class LSU_U12: Typable {
          var name:String = "LSU_U12"

    }

      class MDM_T01: Typable {
          var name:String = "MDM_T01"

    }

      class MDM_T02: Typable {
          var name:String = "MDM_T02"

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

      class MFN_M03: Typable {
          var name:String = "MFN_M03"

    }

      class MFN_M04: Typable {
          var name:String = "MFN_M04"

    }

      class MFN_M05: Typable {
          var name:String = "MFN_M05"

    }

      class MFN_M06: Typable {
          var name:String = "MFN_M06"

    }

      class MFN_M07: Typable {
          var name:String = "MFN_M07"

    }

      class MFN_M08: Typable {
          var name:String = "MFN_M08"

    }

      class MFN_M09: Typable {
          var name:String = "MFN_M09"

    }

      class MFN_M10: Typable {
          var name:String = "MFN_M10"

    }

      class MFN_M11: Typable {
          var name:String = "MFN_M11"

    }

      class MFN_M12: Typable {
          var name:String = "MFN_M12"

    }

      class MFN_M13: Typable {
          var name:String = "MFN_M13"

    }

      class MFN_M15: Typable {
          var name:String = "MFN_M15"

    }

      class MFN_M16: Typable {
          var name:String = "MFN_M16"

    }

      class MFN_M17: Typable {
          var name:String = "MFN_M17"

    }

      class MFN_Znn: Typable {
          var name:String = "MFN_Znn"

    }

      class MFQ_M01: Typable {
          var name:String = "MFQ_M01"

    }

      class MFR_M01: Typable {
          var name:String = "MFR_M01"

    }

      class MFR_M04: Typable {
          var name:String = "MFR_M04"

    }

      class MFR_M05: Typable {
          var name:String = "MFR_M05"

    }

      class MFR_M06: Typable {
          var name:String = "MFR_M06"

    }

      class MFR_M07: Typable {
          var name:String = "MFR_M07"

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

      class OMB_O27: Typable {
          var name:String = "OMB_O27"

    }

      class OMD_O03: Typable {
          var name:String = "OMD_O03"

    }

      class OMG_O19: Typable {
          var name:String = "OMG_O19"

    }

      class OMI_O23: Typable {
          var name:String = "OMI_O23"

    }

      class OML_O21: Typable {
          var name:String = "OML_O21"

    }

      class OML_O33: Typable {
          var name:String = "OML_O33"

    }

      class OML_O35: Typable {
          var name:String = "OML_O35"

    }

      class OMN_O07: Typable {
          var name:String = "OMN_O07"

    }

      class OMP_O09: Typable {
          var name:String = "OMP_O09"

    }

      class OMS_O05: Typable {
          var name:String = "OMS_O05"

    }

      class OPL_O37: Typable {
          var name:String = "OPL_O37"

    }

      class OPR_O38: Typable {
          var name:String = "OPR_O38"

    }

      class OPU_R25: Typable {
          var name:String = "OPU_R25"

    }

      class ORB_O28: Typable {
          var name:String = "ORB_O28"

    }

      class ORD_O04: Typable {
          var name:String = "ORD_O04"

    }

      class ORF_R04: Typable {
          var name:String = "ORF_R04"

    }

      class ORG_O20: Typable {
          var name:String = "ORG_O20"

    }

      class ORI_O24: Typable {
          var name:String = "ORI_O24"

    }

      class ORL_O22: Typable {
          var name:String = "ORL_O22"

    }

      class ORL_O34: Typable {
          var name:String = "ORL_O34"

    }

      class ORL_O36: Typable {
          var name:String = "ORL_O36"

    }

      class ORM_O01: Typable {
          var name:String = "ORM_O01"

    }

      class ORN_O08: Typable {
          var name:String = "ORN_O08"

    }

      class ORP_O10: Typable {
          var name:String = "ORP_O10"

    }

      class ORR_O02: Typable {
          var name:String = "ORR_O02"

    }

      class ORS_O06: Typable {
          var name:String = "ORS_O06"

    }

      class ORU_R01: Typable {
          var name:String = "ORU_R01"

    }

      class ORU_R30: Typable {
          var name:String = "ORU_R30"

    }

      class OSQ_Q06: Typable {
          var name:String = "OSQ_Q06"

    }

      class OSR_Q06: Typable {
          var name:String = "OSR_Q06"

    }

      class OUL_R21: Typable {
          var name:String = "OUL_R21"

    }

      class OUL_R22: Typable {
          var name:String = "OUL_R22"

    }

      class OUL_R23: Typable {
          var name:String = "OUL_R23"

    }

      class OUL_R24: Typable {
          var name:String = "OUL_R24"

    }

      class PEX_P07: Typable {
          var name:String = "PEX_P07"

    }

      class PGL_PC6: Typable {
          var name:String = "PGL_PC6"

    }

      class PMU_B01: Typable {
          var name:String = "PMU_B01"

    }

      class PMU_B03: Typable {
          var name:String = "PMU_B03"

    }

      class PMU_B04: Typable {
          var name:String = "PMU_B04"

    }

      class PMU_B07: Typable {
          var name:String = "PMU_B07"

    }

      class PMU_B08: Typable {
          var name:String = "PMU_B08"

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

      class PPT_PCL: Typable {
          var name:String = "PPT_PCL"

    }

      class PPV_PCA: Typable {
          var name:String = "PPV_PCA"

    }

      class PRR_PC5: Typable {
          var name:String = "PRR_PC5"

    }

      class PTR_PCF: Typable {
          var name:String = "PTR_PCF"

    }

      class QBP_E03: Typable {
          var name:String = "QBP_E03"

    }

      class QBP_E22: Typable {
          var name:String = "QBP_E22"

    }

      class QBP_Q11: Typable {
          var name:String = "QBP_Q11"

    }

      class QBP_Q13: Typable {
          var name:String = "QBP_Q13"

    }

      class QBP_Q15: Typable {
          var name:String = "QBP_Q15"

    }

      class QBP_Q21: Typable {
          var name:String = "QBP_Q21"

    }

      class QBP_Qnn: Typable {
          var name:String = "QBP_Qnn"

    }

      class QBP_Z73: Typable {
          var name:String = "QBP_Z73"

    }

      class QCN_J01: Typable {
          var name:String = "QCN_J01"

    }

      class QRY_A19: Typable {
          var name:String = "QRY_A19"

    }

      class QRY_PC4: Typable {
          var name:String = "QRY_PC4"

    }

      class QRY_Q01: Typable {
          var name:String = "QRY_Q01"

    }

      class QRY_R02: Typable {
          var name:String = "QRY_R02"

    }

      class QRY_T12: Typable {
          var name:String = "QRY_T12"

    }

      class QSB_Q16: Typable {
          var name:String = "QSB_Q16"

    }

      class QVR_Q17: Typable {
          var name:String = "QVR_Q17"

    }

      class RAR_RAR: Typable {
          var name:String = "RAR_RAR"

    }

      class RAS_O17: Typable {
          var name:String = "RAS_O17"

    }

      class RCI_I05: Typable {
          var name:String = "RCI_I05"

    }

      class RCL_I06: Typable {
          var name:String = "RCL_I06"

    }

      class RDE_O11: Typable {
          var name:String = "RDE_O11"

    }

      class RDR_RDR: Typable {
          var name:String = "RDR_RDR"

    }

      class RDS_O13: Typable {
          var name:String = "RDS_O13"

    }

      class RDY_K15: Typable {
          var name:String = "RDY_K15"

    }

      class REF_I12: Typable {
          var name:String = "REF_I12"

    }

      class RER_RER: Typable {
          var name:String = "RER_RER"

    }

      class RGR_RGR: Typable {
          var name:String = "RGR_RGR"

    }

      class RGV_O15: Typable {
          var name:String = "RGV_O15"

    }

      class ROR_ROR: Typable {
          var name:String = "ROR_ROR"

    }

      class RPA_I08: Typable {
          var name:String = "RPA_I08"

    }

      class RPI_I01: Typable {
          var name:String = "RPI_I01"

    }

      class RPI_I04: Typable {
          var name:String = "RPI_I04"

    }

      class RPL_I02: Typable {
          var name:String = "RPL_I02"

    }

      class RPR_I03: Typable {
          var name:String = "RPR_I03"

    }

      class RQA_I08: Typable {
          var name:String = "RQA_I08"

    }

      class RQC_I05: Typable {
          var name:String = "RQC_I05"

    }

      class RQI_I01: Typable {
          var name:String = "RQI_I01"

    }

      class RQP_I04: Typable {
          var name:String = "RQP_I04"

    }

      class RRA_O18: Typable {
          var name:String = "RRA_O18"

    }

      class RRD_O14: Typable {
          var name:String = "RRD_O14"

    }

      class RRE_O12: Typable {
          var name:String = "RRE_O12"

    }

      class RRG_O16: Typable {
          var name:String = "RRG_O16"

    }

      class RRI_I12: Typable {
          var name:String = "RRI_I12"

    }

      class RSP_E03: Typable {
          var name:String = "RSP_E03"

    }

      class RSP_E22: Typable {
          var name:String = "RSP_E22"

    }

      class RSP_K11: Typable {
          var name:String = "RSP_K11"

    }

      class RSP_K21: Typable {
          var name:String = "RSP_K21"

    }

      class RSP_K23: Typable {
          var name:String = "RSP_K23"

    }

      class RSP_K25: Typable {
          var name:String = "RSP_K25"

    }

      class RSP_K31: Typable {
          var name:String = "RSP_K31"

    }

      class RSP_Q11: Typable {
          var name:String = "RSP_Q11"

    }

      class RSP_Z82: Typable {
          var name:String = "RSP_Z82"

    }

      class RSP_Z86: Typable {
          var name:String = "RSP_Z86"

    }

      class RSP_Z88: Typable {
          var name:String = "RSP_Z88"

    }

      class RSP_Z90: Typable {
          var name:String = "RSP_Z90"

    }

      class RTB_K13: Typable {
          var name:String = "RTB_K13"

    }

      class RTB_Z74: Typable {
          var name:String = "RTB_Z74"

    }

      class SDR_S31: Typable {
          var name:String = "SDR_S31"

    }

      class SDR_S32: Typable {
          var name:String = "SDR_S32"

    }

      class SIU_S12: Typable {
          var name:String = "SIU_S12"

    }

      class SLR_S28: Typable {
          var name:String = "SLR_S28"

    }

      class SQM_S25: Typable {
          var name:String = "SQM_S25"

    }

      class SQR_S25: Typable {
          var name:String = "SQR_S25"

    }

      class SRM_S01: Typable {
          var name:String = "SRM_S01"

    }

      class SRR_S01: Typable {
          var name:String = "SRR_S01"

    }

      class SSR_U04: Typable {
          var name:String = "SSR_U04"

    }

      class SSU_U03: Typable {
          var name:String = "SSU_U03"

    }

      class STC_S33: Typable {
          var name:String = "STC_S33"

    }

      class SUR_P09: Typable {
          var name:String = "SUR_P09"

    }

      class TCU_U10: Typable {
          var name:String = "TCU_U10"

    }

      class VXQ_V01: Typable {
          var name:String = "VXQ_V01"

    }

      class VXR_V03: Typable {
          var name:String = "VXR_V03"

    }

      class VXU_V04: Typable {
          var name:String = "VXU_V04"

    }

      class VXX_V02: Typable {
          var name:String = "VXX_V02"

    }


  }


}

