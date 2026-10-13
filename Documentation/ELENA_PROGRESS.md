# Avancement pour les intégrateurs PACS

Révision : 13 octobre 2026. Les responsabilités métier restent dans
l'application : inbox/outbox durable, rapprochement d'identités, autorité des
champs, transactions PostgreSQL, Worklist et MPPS DICOM.

## Livré

- Retrait des 1 816 XSD du dépôt courant et de toutes les ressources SwiftPM.
- `HL7()` autonome avec modèles de travail natifs ; aucun chargement XSD.
- Parsing Unicode et correction de l'accès aux segments répétés intercalés.
- ACK original construit sans XSD, MSA-2 lié au contrôle entrant et MSH-10
  propre à la réponse. Le statut reste décidé par l'application.
- MLLP borné à 8 Mio par défaut, fragmentation des caractères UTF-8 et de
  FS/CR, frames concaténées, rejet des terminaisons invalides et EOF tronqué.
- Vérification du certificat et du nom du serveur TLS par défaut ; configuration
  NIOSSL injectable côté client/serveur et échec explicite si identité absente.
- `ER7Message` : séparateurs personnalisés, null explicite, échappements,
  répétitions sans plafond historique arbitraire, politique d'interprétation
  versionnée par connecteur et conservation de la déclaration MSH-12.
- Client REST R4 async injectable : CRUD, recherche complète, pagination,
  CapabilityStatement, historique, lecture versionnée, batch/transaction,
  ETag/Location et erreurs OperationOutcome ; transport HTTP borné.
- Projections patient/ordre/résultat v2 : autorités CX/EI, visites, MRG
  explicite, frontières multi-patient et ORC/OBR/OBX préservées.
- CDA : patients de l'en-tête, sections imbriquées, narration texte,
  namespaces contrôlés, CDATA et limites de taille/profondeur.
- `MLLPConnection` async : socket à un échange en vol, corrélation MSA-2,
  timeout/annulation, fermeture sur ACK invalide et TLS vérifié en loopback.
- Constructeur et contrôles cliniques natifs (`V2MessageBuilder`, `V2NativeValidator`).
- Suppression de l'API de répertoire externe après clarification du besoin.
- Retrait des 164 CSV de mapping importés inutilisés et de SwiftCSV.
- Corrections de portabilité FoundationXML, CoreFoundation et taille de fichiers
  détectées par la compilation Linux Swift 6.1.

Les tests de compatibilité s'exécutent sans artefacts et couvrent le corpus
historique, les champs nommés courants, le Terser plat, la construction native
et la libération des arbres. La validation normative demeure `indeterminate`
pour les contraintes de standard/profil qui ne sont pas encore implémentées.

## Tranches suivantes

Les résultats de qualification sont mis à jour à la clôture de chaque lot.

- Qualification TLS en réseau, Linux Swift 6.1, iOS et corpus partenaires.

## Frontière ELENA

Le contrat local consulté est `Elena/specifications/14-hl7swift-integration.md`
et `07-interoperability.md` : ADT et ordres, puis Patient, ImagingStudy,
Endpoint, ServiceRequest et DocumentReference R4. Les fusionnements A40 ne
sont jamais effectués implicitement par la bibliothèque.
