# Évaluation de smart-on-fhir/Swift-FHIR

Date : 13 octobre 2026. Périmètre : comparaison des documents et sources publics,
sans import de code tiers ni qualification de compilation de Swift-FHIR.

Le [dépôt proposé](https://github.com/smart-on-fhir/Swift-FHIR) fournit des modèles
R4, primitives, JSON, interactions REST, recherches, opérations et résolution
de références. Sa licence est [Apache 2.0](https://github.com/smart-on-fhir/Swift-FHIR/blob/master/LICENSE.txt).
Sa table de versions présente Swift 5 / FHIR 4.0.0 pour la branche principale.
Les recherches et la gestion de versions ont des limites reconnues dans son README.

Le [manifeste](https://github.com/smart-on-fhir/Swift-FHIR/blob/master/Package.swift)
sépare Models, Client et FHIR, avec Swift tools 5.0 et sans tests SwiftPM déclarés.
Son [modèle de base](https://github.com/smart-on-fhir/Swift-FHIR/blob/master/Sources/Models/FHIRAbstractBase.swift)
utilise un dictionnaire JSON et des liens propriétaire/références résolues dans
les objets. Ce choix facilite la navigation mais diffère des modèles Codable
Apple déjà utilisés dans HL7Swift.

## Décision pour ELENA

Conserver [Apple FHIRModels](https://github.com/apple/FHIRModels), actuellement
figé à 0.8.0 pour Swift tools 6.1, et compléter le client AsyncHTTPClient.
Les modèles R4 de Patient, ImagingStudy, Endpoint, ServiceRequest et
DocumentReference sont déjà disponibles dans cette dépendance. Ajouter
Swift-FHIR maintenant introduirait une seconde hiérarchie de ressources et
une migration des mappings existants, sans combler HL7v2, CDA, MLLP ou les
workflows DICOM.

Swift-FHIR reste utile comme référence de conception pour un futur résolveur
de références contained/Bundle et une API de recherche ergonomique. Aucun
code n'est copié et aucune dépendance n'est ajoutée. Un contrôle de modèles
JSON ne remplace pas la validation des profils, invariants et terminologies.
