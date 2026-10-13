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
- IPC natif pour les adaptateurs Worklist et TXA/OBX TX pour les comptes rendus MDM.
- Traitement entrant async à callback obligatoire, conservation des octets exacts
  et ACK après le résultat de persistance/traitement fourni par l'application.
- Suppression de l'API de répertoire externe après clarification du besoin.
- Retrait des 164 CSV de mapping importés inutilisés et de SwiftCSV.
- Corrections de portabilité FoundationXML, CoreFoundation et taille de fichiers
  détectées par la compilation Linux Swift 6.1.

Les tests de compatibilité s'exécutent sans artefacts et couvrent le corpus
historique, les champs nommés courants, le Terser plat, la construction native
et la libération des arbres. La validation normative demeure `indeterminate`
pour les contraintes de standard/profil qui ne sont pas encore implémentées.

## Qualification du lot natif — 13 octobre 2026

Révision du code : `7944e6e`. Les contrôles suivants ont réussi :

- macOS arm64, Swift 6.2.4 : `swift test`, 82 tests, 2 ignorés, aucun échec.
- Linux aarch64, image officielle Swift 6.1 (compilateur 6.1.3) :
  `swift build -c release -j 4`, puis
  `swift test -j 4 --parallel --num-workers 2`, 82 tests, aucun échec.
  Le dépôt est monté en lecture seule et copié dans le conteneur avant compilation.
- iOS, destination générique sans signature : compilation réussie avec
  `xcodebuild build -scheme HL7Swift-Package -destination 'generic/platform=iOS'`
  et `CODE_SIGNING_ALLOWED=NO`. Pas de test sur appareil ou simulateur dans ce lot.
- Vérification d'absence de XSD sous `Sources` :
  `bash Documentation/verify-v2-resources.sh`.

Les deux anciens tests d'intégration FHIR nécessitent désormais l'activation
explicite `HL7_TEST_FHIR_BASE_URL` vers un serveur jetable. Les tests courants
HTTP et MLLP/TLS démarrent leurs propres serveurs loopback : vraie connexion,
certificat et nom d'hôte contrôlés, délais, annulation et corrélation ACK.
Cette preuve n'est pas une qualification d'un serveur partenaire ou d'un réseau
hospitalier. La compilation iOS ne constitue pas une preuve d'exécution sur appareil.

## Lot primitives serveur FHIR — 13 octobre 2026

- `FHIRR4ReadServer` : metadata/read/search GET et POST, négociation JSON,
  OperationOutcome sûrs, ETag/Last-Modified et lectures conditionnelles.
- CapabilityStatement limité aux capacités configurées ; aucun historique,
  écriture, transaction ou profil IHE annoncé implicitement.
- Bundles searchset, liens canoniques self/next, limites de recherche/réponse,
  paramètres répétés conservés et curseurs détenus par le backend.
- Projection ImagingStudy/séries/instances et Endpoint WADO-RS : identités et
  statuts explicites, références relatives, UID contrôlés, distinction inconnu/vide.
- Pas de dépendance Vapor, persistance ou session d'autorisation. Les callbacks
  sont fournis par requête, après les contrôles applicatifs.

Qualification du code `8bf03c3` : macOS Swift 6.2.4, 96 tests, 2 ignorés,
aucun échec ; compilation iOS générique sans signature réussie. Le test HTTP
réel effectue metadata/read/search/404 ; un autre teste la pagination via le
client public. Ce n'est pas une qualification d'ELENA ou d'un client indépendant.

Le build release Linux Swift 6.1.3 a réussi, y compris pour le code `8bf03c3`.
La suite complète Linux n'est **pas qualifiée** : des exécutions parallèles et
sérielles sont restées bloquées, tandis que des tests isolés réussissent. LLDB
localise l'attente dans le teardown asynchrone XCTest/CFRunLoop, sans frame
HL7Swift bloquée. Cause non établie ; la modification temporaire vers des tests
en série a été retirée puisqu'elle ne résout pas le problème.
L'intégration authentification/Vapor/PostgreSQL et les profils restent applicatifs.
Voir [le guide serveur](FHIR_SERVER.md) et [la note CI](CONTINUOUS_INTEGRATION.md).

## Tranches suivantes

- Profils de connecteurs ELENA et corpus partenaires : écarts de versions,
  champs obligatoires locaux, identifiants et variantes d'ordres/résultats.
- Validation normative par version/profil et terminologies : les contrôles
  natifs partiels ne doivent pas être présentés comme exhaustifs.
- Entrées CDA structurées et profils documentaires, au-delà de la narration.
- Transformations explicites vers Patient, ServiceRequest, ImagingStudy,
  Endpoint et DocumentReference R4, avec politique de références/identités.
- Adaptateurs ELENA : inbox/outbox PostgreSQL et services Worklist/MPPS DICOM.
  Les primitives sont disponibles ; ces workflows ne sont pas implémentés ici.

## Frontière ELENA

Le contrat local consulté est `Elena/specifications/14-hl7swift-integration.md`
et `07-interoperability.md` : ADT et ordres, puis Patient, ImagingStudy,
Endpoint, ServiceRequest et DocumentReference R4. Les fusionnements A40 ne
sont jamais effectués implicitement par la bibliothèque.
