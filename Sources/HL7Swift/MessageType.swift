//
//  File.swift
//  
//
//  Created by Rafael Warnault on 24/12/2021.
//

import Foundation


public enum VersionType:String {
    case v23    = "2.3"
    case v251   = "2.5.1"
    case v26    = "2.6"
    
    public func klass(forVersion type: VersionType) -> Version.Type {
        switch type {
        case .v23:  return V23.self
        case .v251: return V251.self
        case .v26:  return V26.self
        }
    }
}


public class Version {
    public struct MessageType: RawRepresentable {
        public init?(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public var rawValue: String
        
        public typealias RawValue = String
    }
}


public class V23:Version {
    static let ACK = MessageType(rawValue: "ACK")
}


public class V26:Version {
    static let ACK = MessageType(rawValue: "ACK")
}


public class V251:Version {
    static let ACK     = MessageType(rawValue: "ACK")
    static let ADR_A19 = MessageType(rawValue: "ADR_A19")
    static let ADT_A01 = MessageType(rawValue: "ADT_A01")
    static let ADT_A02 = MessageType(rawValue: "ADT_A02")
    static let ADT_A03 = MessageType(rawValue: "ADT_A03")
    static let ADT_A05 = MessageType(rawValue: "ADT_A05")
    static let ADT_A06 = MessageType(rawValue: "ADT_A06")
    static let ADT_A09 = MessageType(rawValue: "ADT_A09")
    static let ADT_A12 = MessageType(rawValue: "ADT_A12")
    static let ADT_A15 = MessageType(rawValue: "ADT_A15")
    static let ADT_A16 = MessageType(rawValue: "ADT_A16")
    static let ADT_A17 = MessageType(rawValue: "ADT_A17")
    static let ADT_A18 = MessageType(rawValue: "ADT_A18")
    static let ADT_A20 = MessageType(rawValue: "ADT_A20")
    static let ADT_A21 = MessageType(rawValue: "ADT_A21")
    static let ADT_A24 = MessageType(rawValue: "ADT_A24")
    static let ADT_A30 = MessageType(rawValue: "ADT_A30")
    static let ADT_A37 = MessageType(rawValue: "ADT_A37")
    static let ADT_A38 = MessageType(rawValue: "ADT_A38")
    static let ADT_A39 = MessageType(rawValue: "ADT_A39")
    static let ADT_A43 = MessageType(rawValue: "ADT_A43")
    static let ADT_A45 = MessageType(rawValue: "ADT_A45")
    static let ADT_A50 = MessageType(rawValue: "ADT_A50")
    static let ADT_A52 = MessageType(rawValue: "ADT_A52")
    static let ADT_A54 = MessageType(rawValue: "ADT_A54")
    static let ADT_A60 = MessageType(rawValue: "ADT_A60")
    static let ADT_A61 = MessageType(rawValue: "ADT_A61")
    static let BAR_P01 = MessageType(rawValue: "BAR_P01")
    static let BAR_P02 = MessageType(rawValue: "BAR_P02")
    static let BAR_P05 = MessageType(rawValue: "BAR_P05")
    static let BAR_P06 = MessageType(rawValue: "BAR_P06")
    static let BAR_P10 = MessageType(rawValue: "BAR_P10")
    static let BAR_P12 = MessageType(rawValue: "BAR_P12")
    static let BPS_O29 = MessageType(rawValue: "BPS_O29")
    static let BRP_O30 = MessageType(rawValue: "BRP_O30")
    static let BRT_O32 = MessageType(rawValue: "BRT_O32")
    static let BTS_O31 = MessageType(rawValue: "BTS_O31")
    static let CRM_C01 = MessageType(rawValue: "CRM_C01")
    static let CSU_C09 = MessageType(rawValue: "CSU_C09")
    static let DFT_P03 = MessageType(rawValue: "DFT_P03")
    static let DFT_P11 = MessageType(rawValue: "DFT_P11")
    static let DOC_T12 = MessageType(rawValue: "DOC_T12")
    static let EAC_U07 = MessageType(rawValue: "EAC_U07")
    static let EAN_U09 = MessageType(rawValue: "EAN_U09")
    static let EAR_U08 = MessageType(rawValue: "EAR_U08")
    static let ESR_U02 = MessageType(rawValue: "ESR_U02")
    static let ESU_U01 = MessageType(rawValue: "ESU_U01")
    static let INR_U06 = MessageType(rawValue: "INR_U06")
    static let INU_U05 = MessageType(rawValue: "INU_U05")
    static let LSU_U12 = MessageType(rawValue: "LSU_U12")
    static let MDM_T01 = MessageType(rawValue: "MDM_T01")
    static let MDM_T02 = MessageType(rawValue: "MDM_T02")
    static let MFK_M01 = MessageType(rawValue: "MFK_M01")
    static let MFN_M01 = MessageType(rawValue: "MFN_M01")
    static let MFN_M02 = MessageType(rawValue: "MFN_M02")
    static let MFN_M03 = MessageType(rawValue: "MFN_M03")
    static let MFN_M04 = MessageType(rawValue: "MFN_M04")
    static let MFN_M05 = MessageType(rawValue: "MFN_M05")
    static let MFN_M06 = MessageType(rawValue: "MFN_M06")
    static let MFN_M07 = MessageType(rawValue: "MFN_M07")
    static let MFN_M08 = MessageType(rawValue: "MFN_M08")
    static let MFN_M09 = MessageType(rawValue: "MFN_M09")
    static let MFN_M10 = MessageType(rawValue: "MFN_M10")
    static let MFN_M11 = MessageType(rawValue: "MFN_M11")
    static let MFN_M12 = MessageType(rawValue: "MFN_M12")
    static let MFN_M13 = MessageType(rawValue: "MFN_M13")
    static let MFN_M15 = MessageType(rawValue: "MFN_M15")
    static let MFN_Znn = MessageType(rawValue: "MFN_Znn")
    static let MFQ_M01 = MessageType(rawValue: "MFQ_M01")
    static let MFR_M01 = MessageType(rawValue: "MFR_M01")
    static let MFR_M04 = MessageType(rawValue: "MFR_M04")
    static let MFR_M05 = MessageType(rawValue: "MFR_M05")
    static let MFR_M06 = MessageType(rawValue: "MFR_M06")
    static let MFR_M07 = MessageType(rawValue: "MFR_M07")
    static let NMD_N02 = MessageType(rawValue: "NMD_N02")
    static let NMQ_N01 = MessageType(rawValue: "NMQ_N01")
    static let NMR_N01 = MessageType(rawValue: "NMR_N01")
    static let OMB_O27 = MessageType(rawValue: "OMB_O27")
    static let OMD_O03 = MessageType(rawValue: "OMD_O03")
    static let OMG_O19 = MessageType(rawValue: "OMG_O19")
    static let OMI_O23 = MessageType(rawValue: "OMI_O23")
    static let OML_O21 = MessageType(rawValue: "OML_O21")
    static let OML_O33 = MessageType(rawValue: "OML_O33")
    static let OML_O35 = MessageType(rawValue: "OML_O35")
    static let OMN_O07 = MessageType(rawValue: "OMN_O07")
    static let OMP_O09 = MessageType(rawValue: "OMP_O09")
    static let OMS_O05 = MessageType(rawValue: "OMS_O05")
    static let ORB_O28 = MessageType(rawValue: "ORB_O28")
    static let ORD_O04 = MessageType(rawValue: "ORD_O04")
    static let ORF_R04 = MessageType(rawValue: "ORF_R04")
    static let ORG_O20 = MessageType(rawValue: "ORG_O20")
    static let ORI_O24 = MessageType(rawValue: "ORI_O24")
    static let ORL_O22 = MessageType(rawValue: "ORL_O22")
    static let ORL_O34 = MessageType(rawValue: "ORL_O34")
    static let ORL_O36 = MessageType(rawValue: "ORL_O36")
    static let ORM_O01 = MessageType(rawValue: "ORM_O01")
    static let ORN_O08 = MessageType(rawValue: "ORN_O08")
    static let ORP_O10 = MessageType(rawValue: "ORP_O10")
    static let ORR_O02 = MessageType(rawValue: "ORR_O02")
    static let ORS_O06 = MessageType(rawValue: "ORS_O06")
    static let ORU_R01 = MessageType(rawValue: "ORU_R01")
    static let ORU_R30 = MessageType(rawValue: "ORU_R30")
    static let OSQ_Q06 = MessageType(rawValue: "OSQ_Q06")
    static let OSR_Q06 = MessageType(rawValue: "OSR_Q06")
    static let OUL_R21 = MessageType(rawValue: "OUL_R21")
    static let OUL_R22 = MessageType(rawValue: "OUL_R22")
    static let OUL_R23 = MessageType(rawValue: "OUL_R23")
    static let OUL_R24 = MessageType(rawValue: "OUL_R24")
    static let PEX_P07 = MessageType(rawValue: "PEX_P07")
    static let PGL_PC6 = MessageType(rawValue: "PGL_PC6")
    static let PMU_B01 = MessageType(rawValue: "PMU_B01")
    static let PMU_B03 = MessageType(rawValue: "PMU_B03")
    static let PMU_B04 = MessageType(rawValue: "PMU_B04")
    static let PMU_B07 = MessageType(rawValue: "PMU_B07")
    static let PMU_B08 = MessageType(rawValue: "PMU_B08")
    static let PPG_PCG = MessageType(rawValue: "PPG_PCG")
    static let PPP_PCB = MessageType(rawValue: "PPP_PCB")
    static let PPR_PC1 = MessageType(rawValue: "PPR_PC1")
    static let PPT_PCL = MessageType(rawValue: "PPT_PCL")
    static let PPV_PCA = MessageType(rawValue: "PPV_PCA")
    static let PRR_PC5 = MessageType(rawValue: "PRR_PC5")
    static let PTR_PCF = MessageType(rawValue: "PTR_PCF")
    static let QBP_Q11 = MessageType(rawValue: "QBP_Q11")
    static let QBP_Q13 = MessageType(rawValue: "QBP_Q13")
    static let QBP_Q15 = MessageType(rawValue: "QBP_Q15")
    static let QBP_Q21 = MessageType(rawValue: "QBP_Q21")
    static let QBP_Qnn = MessageType(rawValue: "QBP_Qnn")
    static let QBP_Z73 = MessageType(rawValue: "QBP_Z73")
    static let QCN_J01 = MessageType(rawValue: "QCN_J01")
    static let QRY_A19 = MessageType(rawValue: "QRY_A19")
    static let QRY_PC4 = MessageType(rawValue: "QRY_PC4")
    static let QRY_Q01 = MessageType(rawValue: "QRY_Q01")
    static let QRY_R02 = MessageType(rawValue: "QRY_R02")
    static let QRY     = MessageType(rawValue: "QRY")
    static let QSB_Q16 = MessageType(rawValue: "QSB_Q16")
    static let QVR_Q17 = MessageType(rawValue: "QVR_Q17")
    static let RAR_RAR = MessageType(rawValue: "RAR_RAR")
    static let RAS_O17 = MessageType(rawValue: "RAS_O17")
    static let RCI_I05 = MessageType(rawValue: "RCI_I05")
    static let RCL_I06 = MessageType(rawValue: "RCL_I06")
    static let RDE_O11 = MessageType(rawValue: "RDE_O11")
    static let RDR_RDR = MessageType(rawValue: "RDR_RDR")
    static let RDS_O13 = MessageType(rawValue: "RDS_O13")
    static let RDY_K15 = MessageType(rawValue: "RDY_K15")
    static let REF_I12 = MessageType(rawValue: "REF_I12")
    static let RER_RER = MessageType(rawValue: "RER_RER")
    static let RGR_RGR = MessageType(rawValue: "RGR_RGR")
    static let RGV_O15 = MessageType(rawValue: "RGV_O15")
    static let ROR_ROR = MessageType(rawValue: "ROR_ROR")
    static let RPA_I08 = MessageType(rawValue: "RPA_I08")
    static let RPI_I01 = MessageType(rawValue: "RPI_I01")
    static let RPI_I04 = MessageType(rawValue: "RPI_I04")
    static let RPL_I02 = MessageType(rawValue: "RPL_I02")
    static let RPR_I03 = MessageType(rawValue: "RPR_I03")
    static let RQA_I08 = MessageType(rawValue: "RQA_I08")
    static let RQC_I05 = MessageType(rawValue: "RQC_I05")
    static let RQI_I01 = MessageType(rawValue: "RQI_I01")
    static let RQP_I04 = MessageType(rawValue: "RQP_I04")
    static let RRA_O18 = MessageType(rawValue: "RRA_O18")
    static let RRD_O14 = MessageType(rawValue: "RRD_O14")
    static let RRE_O12 = MessageType(rawValue: "RRE_O12")
    static let RRG_O16 = MessageType(rawValue: "RRG_O16")
    static let RRI_I12 = MessageType(rawValue: "RRI_I12")
    static let RSP_K11 = MessageType(rawValue: "RSP_K11")
    static let RSP_K21 = MessageType(rawValue: "RSP_K21")
    static let RSP_K23 = MessageType(rawValue: "RSP_K23")
    static let RSP_K25 = MessageType(rawValue: "RSP_K25")
    static let RSP_K31 = MessageType(rawValue: "RSP_K31")
    static let RSP_Q11 = MessageType(rawValue: "RSP_Q11")
    static let RSP_Z82 = MessageType(rawValue: "RSP_Z82")
    static let RSP_Z86 = MessageType(rawValue: "RSP_Z86")
    static let RSP_Z88 = MessageType(rawValue: "RSP_Z88")
    static let RSP_Z90 = MessageType(rawValue: "RSP_Z90")
    static let RTB_K13 = MessageType(rawValue: "RTB_K13")
    static let RTB_Knn = MessageType(rawValue: "RTB_Knn")
    static let RTB_Z74 = MessageType(rawValue: "RTB_Z74")
    static let SIU_S12 = MessageType(rawValue: "SIU_S12")
    static let SQM_S25 = MessageType(rawValue: "SQM_S25")
    static let SQR_S25 = MessageType(rawValue: "SQR_S25")
    static let SRM_S01 = MessageType(rawValue: "SRM_S01")
    static let SRR_S01 = MessageType(rawValue: "SRR_S01")
    static let SSR_U04 = MessageType(rawValue: "SSR_U04")
    static let SSU_U03 = MessageType(rawValue: "SSU_U03")
    static let SUR_P09 = MessageType(rawValue: "SUR_P09")
    static let TCU_U10 = MessageType(rawValue: "TCU_U10")
    static let VXQ_V01 = MessageType(rawValue: "VXQ_V01")
    static let VXR_V03 = MessageType(rawValue: "VXR_V03")
    static let VXU_V04 = MessageType(rawValue: "VXU_V04")
    static let VXX_V02 = MessageType(rawValue: "VXX_V02")
}
