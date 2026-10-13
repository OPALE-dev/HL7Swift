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
try builder.addImagingProcedure(.init(
    accession: .init(value: "acc-123", namespace: "RIS"),
    requestedProcedure: .init(value: "rp-123", namespace: "RIS"),
    scheduledProcedureStep: .init(value: "sps-123", namespace: "RIS"), modality: "CT"))
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

`addImagingProcedure` crée IPC avec accession, procédure demandée, étape
planifiée, UID d'étude facultatif, modalité et AE Title. La projection expose
ces valeurs pour l'adaptateur Worklist ; aucune entrée DICOM ni UID n'est
généré implicitement. Le connecteur peut exiger IPC-3 via
`requireImagingStudyUID`. `addTextDocument` crée TXA et OBX TX pour un compte
rendu MDM T02, avec identifiant et statut documentaire explicites.

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

## Traitement entrant asynchrone

`V2InboundProcessor` reçoit les octets exacts, parse et applique les contrôles
natifs. Son callback `handle` est obligatoire et asynchrone : l'application
peut y enregistrer l'inbox et choisir AA/AE/AR ou CA/CE/CR. L'ACK est construit
après le retour du callback ; une erreur de stockage se propage sans ACK
positif. Un contrat invalide produit le code de rejet configuré sans mutation
métier. Les erreurs de syntaxe ou l'absence de MSH-10 empêchent un ACK corrélé.

Le callback reçoit `sourceBytes`, `message` et `report`. L'application reste
responsable des clés d'idempotence, de la politique MSH-15/16 et de la phase
ACK négociée. Cette primitive ne constitue pas un stockage durable embarqué.
