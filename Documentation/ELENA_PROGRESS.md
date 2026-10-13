# Avancement pour les intégrateurs PACS

Révision : 13 octobre 2026. Les responsabilités métier restent dans
l'application : inbox/outbox durable, rapprochement d'identités, autorité des
champs, transactions PostgreSQL, Worklist et MPPS DICOM.

## Livré

- Retrait des 1 816 XSD du dépôt courant et de toutes les ressources SwiftPM.
- `HL7()` autonome, source XSD locale explicitement optionnelle.
- Parsing Unicode et correction de l'accès aux segments répétés intercalés.
- ACK original construit sans XSD, MSA-2 lié au contrôle entrant et MSH-10
  propre à la réponse. Le statut reste décidé par l'application.
- MLLP borné à 8 Mio par défaut, fragmentation des caractères UTF-8 et de
  FS/CR, frames concaténées, rejet des terminaisons invalides et EOF tronqué.
- Vérification du certificat et du nom du serveur TLS par défaut ; configuration
  NIOSSL injectable côté client/serveur et échec explicite si identité absente.

Les tests de structure historiques nécessitent `HL7_TEST_SPEC_DIRECTORY` et
sont explicitement ignorés sans lot local. Les tests de parsing autonome et
MLLP synthétiques s'exécutent toujours. La validation normative demeure
`indeterminate` en l'absence d'artefacts et de contrôles qualifiés.

## Tranches suivantes

Vérification locale de cette première tranche : `swift test --parallel`,
61 tests découverts, sans échec ; 19 tests historiques de structure ignorés
explicitement sans lot externe. Aucune preuve Linux/iOS ni pipeline distante
n'est revendiquée pour cette tranche.

- ER7 indépendant avec séparateurs MSH, politique de tolérance explicite,
  échappements et version déclarée conservée.
- Client FHIR R4 async, CRUD, recherche Bundle, erreurs OperationOutcome.
- Extraction des identités et ordres ADT/ORM/OMI/ORU pour les adaptateurs.
- CDA : patient, sections et narration consultable.
- Qualification TLS en réseau, Linux Swift 6.1, iOS et corpus partenaires.

## Frontière ELENA

Le contrat local consulté est `Elena/specifications/14-hl7swift-integration.md`
et `07-interoperability.md` : ADT et ordres, puis Patient, ImagingStudy,
Endpoint, ServiceRequest et DocumentReference R4. Les fusionnements A40 ne
sont jamais effectués implicitement par la bibliothèque.
