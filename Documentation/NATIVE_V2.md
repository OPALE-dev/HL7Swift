# Construction et contrôles natifs

```swift
import HL7V2

var builder = try V2MessageBuilder(kind: .imagingOrder,
    sendingApplication: "RIS", sendingFacility: "HOSP",
    receivingApplication: "PACS", receivingFacility: "HOSP", controlID: "order-123")
try builder.addPatient(.init(
    identifiers: [.init(value: "patient-123", namespace: "HOSP", type: "MR")],
    family: "Été", given: ["Zoé"], birthTime: "19800501"))
try builder.addOrder(control: "NW", placer: .init(value: "order-123", namespace: "RIS"),
    serviceCode: "CT", serviceText: "Thorax", codingSystem: "LOCAL")
let message = try builder.build()
let report = V2NativeValidator().validate(message,
    policy: .init(requirePatientAuthority: true))
```

Les identifiants patient CX et ordres EI conservent leurs autorités. Les valeurs
sont échappées avant composition. `addTextObservation` crée OBX TX avec
répétitions ; `addPriorIdentifiers` produit une assertion MRG sans effectuer
de fusion. `appendRawSegment` accepte les segments locaux et refuse
l'injection de headers, lignes ou octets de framing.

Les événements natifs initiaux sont ADT A01/A02/A03/A04/A05/A08/A28/A31/A40,
ORM O01, OMI O23, ORU R01 et MDM T02. Le constructeur produit MSH-9
code/événement ; `messageStructure` peut désigner explicitement la structure
négociée. EVN, TXA et les détails de planification sont à renseigner selon le
contrat partenaire via les segments appropriés.

Le validateur contrôle une portée explicite : enveloppe, segments requis par
le contrat initial, identifiants patient/ordre, autorités optionnellement
obligatoires et codes ACK. `expectedMessageType` compare le champ MSH-9 complet.
Absence, valeur vide et null explicite restent distincts. Les diagnostics
donnent positions et codes sans révéler les valeurs des patients.

Le stage `v2.standard-profile` reste `notRun` pour les contraintes encore non
implémentées. Un rapport sain reste `indeterminate` quant à la conformité
complète. Les profils IHE, règles calendaires détaillées, champs conditionnels
et terminologies ne sont pas implicitement validés.

Pour ELENA, l'ACK positif appartient au résultat garanti par l'inbox. La
bibliothèque ne réconcilie pas les identités, n'annule pas un examen et ne
déduit pas une accession universelle d'OBR-18.
