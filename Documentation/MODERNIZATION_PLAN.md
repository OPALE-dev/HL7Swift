# Plan de modernisation de HL7Swift

Statut : document directeur vivant

Dernière révision : 9 octobre 2026

## 1. Vision

HL7Swift doit rester un seul package Swift, composé de targets spécialisées et faciles à utiliser, consacré à l'interopérabilité de santé. Il doit permettre à une application cliente de lire, produire, transporter, valider et transformer des données issues de l'écosystème HL7 sans imposer son architecture métier, son stockage ou son mode de déploiement.

HL7Swift doit rester utile à une application mobile, un outil en ligne de commande, une passerelle, un serveur Vapor ou tout autre logiciel Swift, sans orienter ses API vers un produit particulier.

Les principes directeurs sont les suivants :

- un seul dépôt et un seul package Swift Package Manager, avec des targets et produits bibliothèque distincts ;
- une API publique claire, documentée et compatible avec le versionnage sémantique ;
- le minimum de dépendances transitives pour chaque produit ;
- aucun modèle métier propre à une application ou un établissement dans la bibliothèque ;
- une couverture annoncée uniquement lorsqu'elle est vérifiée et traçable ;
- des diagnostics exploitables plutôt qu'un simple résultat booléen ;
- macOS, iOS et Linux comme environnements de première classe lorsque les dépendances le permettent ;
- SwiftNIO comme socle réseau commun, cohérent avec les autres composants Swift de l'écosystème.

## 2. Périmètre

### 2.1 Dans HL7Swift

- **HL7 v2.x** : modèles de spécification, encodage ER7, parsing, sérialisation, construction, validation structurelle, acquittements et transport MLLP.
- **FHIR** : ressources versionnées, JSON et XML, client REST, recherche, opérations, validation, FHIRPath, packages et guides d'implémentation.
- **CDA** : documents CDA R2, en-tête, corps structuré ou non structuré, texte narratif, types de données HL7 v3 nécessaires à CDA, validation et profils de documents.
- **HL7Mapping** : transformations explicites entre HL7 v2, FHIR et CDA, avec diagnostics, provenance et pertes d'information déclarées.
- **Outillage de conformité** : chargement d'artefacts officiels, génération reproductible, jeux d'essai, rapports de couverture et qualification par version ou profil.

### 2.2 Hors périmètre

Les éléments suivants appartiennent à d'autres bibliothèques ou aux applications qui consomment HL7Swift :

- les modèles métier internes aux applications consommatrices ;
- les protocoles et formats qui n'appartiennent pas à l'écosystème HL7 ;
- la persistance applicative, les files de tâches, l'interface utilisateur et l'hébergement ;
- un serveur FHIR complet et déployable, qui relève d'une application utilisant HL7Swift ;
- l'orchestration complète des acteurs et transactions IHE ;
- la facturation, la réglementation nationale et les règles métier propres à un établissement ;
- la distribution de terminologies ou de contenus normatifs dont la licence ne l'autorise pas.

HL7Swift peut fournir les primitives nécessaires à ces usages sans les implémenter lui-même.

## 3. Indépendance vis-à-vis des applications consommatrices

FHIR est une représentation d'échange, pas un modèle métier interne imposé aux applications clientes. Chaque application doit pouvoir conserver son propre domaine et projeter ses données vers les formats d'interopérabilité.

```text
                application consommatrice
                           |
                 adaptateurs applicatifs
                           |
                     HL7Mapping
                  /       |       \
               HL7V2     FHIR      CDA
```

Cette frontière évite de coupler les évolutions d'un produit à celles des standards et permet à d'autres développeurs d'utiliser chaque module isolément.

## 4. Point de départ en octobre 2026

Le package utilise Swift tools 6.1 tout en conservant temporairement le mode de langage Swift 5. Il expose actuellement les produits bibliothèque suivants, chacun adossé à une target du même package :

| Produit | Rôle actuel | Direction |
| --- | --- | --- |
| `HL7Core` | modèle commun de diagnostics et d'étapes de validation | Socle partagé sans dépendance externe |
| `HL7V2` | API HL7 v2, réexportant encore l'implémentation historique | Produit public principal pour HL7 v2 |
| `FHIR` | client et modèles FHIR R4 | Produit FHIR autonome et versionné |
| `CDA` | lecture initiale de l'enveloppe CDA R2 | Modèle et validation CDA complets |
| `HL7Mapping` | conversions entre HL7 v2 et FHIR | Transformations explicites entre modules |
| `HL7Swift` | implémentation historique HL7 v2 | Façade de compatibilité à déprécier progressivement |
| `FHIRSwift` | ancienne surface FHIR et conversion | Façade de compatibilité à déprécier progressivement |

Les dépendances de domaine doivent rester orientées ainsi :

```text
HL7Swift <- HL7V2 <- HL7Mapping -> FHIR
                          |
                         CDA   (lorsque les mappings CDA seront introduits)

FHIR et CDA ne dépendent pas de HL7V2.
```

La suite compte actuellement des tests unitaires, réseau et d'architecture. Leur réussite démontre la non-régression du code testé, pas encore une conformité normative complète.

## 5. Mesurer honnêtement la couverture

Chaque fonctionnalité annoncée doit être évaluée suivant plusieurs dimensions :

1. syntaxe et sérialisation ;
2. modèle de données et contraintes ;
3. transport ou API ;
4. validation ;
5. profils et guides d'implémentation ;
6. interopérabilité vérifiée avec une implémentation de référence.

Une version ou un profil n'est « pris en charge » que si sont publiés :

- la version exacte du standard ;
- les artefacts normatifs utilisés et leur provenance ;
- le périmètre effectivement implémenté ;
- les limites connues ;
- les plateformes testées ;
- les résultats d'une suite de qualification reproductible.

Niveaux de maturité à employer dans la documentation et les versions :

| Niveau | Signification |
| --- | --- |
| Planifié | Aucun contrat d'API ou de comportement |
| Expérimental | API utilisable pour évaluation, modifications incompatibles possibles |
| Partiel | Sous-ensemble documenté et testé, sans prétention de couverture globale |
| Qualifié | Matrice de conformité, corpus et limites publiés |
| Stable | API publique soumise au versionnage sémantique et qualification maintenue |

La validation doit distinguer au minimum `valid`, `invalid` et `indeterminate`. Une validation statique réussie ne prouve ni la conformité de bout en bout ni le respect des règles métier externes.

## 6. Cibles de standards

Les versions doivent toujours être épinglées dans les livrables. Au moment de cette révision, HL7 publie HL7 v2.9.1 comme mise à jour normative active, FHIR R5 comme version finale courante, tandis que R6 reste une séquence de travail. R4 et R4B doivent rester des cibles majeures en raison de leur adoption et de leurs guides d'implémentation.

| Domaine | Cible | Priorité | Objectif |
| --- | --- | --- | --- |
| HL7 v2 | v2.3 à v2.8.2 | P0 | Auditer et qualifier la couverture historique existante |
| HL7 v2 | v2.9 et v2.9.1 | P1 | Importer les artefacts, générer les modèles et qualifier les écarts |
| HL7 v2 | ER7, échappements, jeux de caractères | P0 | Parsing et sérialisation sans perte |
| HL7 v2 | ACK, modes original et amélioré, batch | P0/P1 | Cycle d'échange correctement modélisé |
| HL7 v2 | MLLP | P0 | Client et serveur robustes, TLS configurable |
| HL7 v2 | XML Encoding | P2 | Ajouter après qualification ER7 |
| HL7 v2 | HLLP | P3 | Étudier seulement après stabilisation de MLLP |
| FHIR | R4 | P0 | Première base stable et qualifiée |
| FHIR | R4B et R5 | P1/P0 | Modèles et validation réellement versionnés |
| FHIR | R6 | Expérimental | Suivi et essais sans promesse de stabilité avant publication finale |
| FHIR | JSON, XML et REST | P0/P1 | Formats et protocole de base |
| FHIR | Packages, profils et guides d'implémentation | P1 | Résolution déterministe des dépendances de conformité |
| FHIR | FHIRPath | P0 | Moteur indépendant utilisé par la validation et les mappings |
| FHIR | SMART App Launch | P2 | Primitives client, sans système d'identité embarqué |
| FHIR | Bulk Data Access | P3 | Client asynchrone séparé après stabilisation REST |
| CDA | CDA R2 | P0 | Lecture, écriture et modèle documentaire |
| CDA | schémas, SDTC et templates | P1 | Validation graduée et profils explicitement nommés |
| HL7 v3 | types nécessaires à CDA | P1 | Socle XML et types de données minimal, partagé avec CDA |
| HL7 v3 | couverture universelle | Hors cible | Ne pas promettre une implémentation générique de tout HL7 v3 |
| CQL | faisabilité | P3 | Étude après FHIRPath et validation FHIR |

Références de suivi officielles :

- [HL7 v2.9.1](https://dev3.hl7.org/implement/standards/product_brief.cfm?product_id=649)
- [répertoire des versions FHIR](https://hl7.org/fhir/directory.html)
- [gestion des versions FHIR](https://fhir.hl7.org/fhir/versioning.html)
- [CDA R2](https://hl7.org/cda/)
- [FHIRPath](https://hl7.org/fhirpath/)
- [validation FHIR](https://fhir.hl7.org/fhir/validation.html)
- [SMART App Launch](https://www.hl7.org/fhir/smart-app-launch/conformance.html)
- [Bulk Data Access](https://hl7.org/fhir/uv/bulkdata/en/index.html)

## 7. Architecture cible des modules

La structure suivante décrit des targets possibles dans le même package, pas une obligation de tout fractionner immédiatement :

```text
HL7Core
  diagnostics, versions, provenance, abstractions de terminologie

HL7V2
  modèle, spécifications et API publique
HL7V2Transport
  MLLP, TLS et comportements réseau sur SwiftNIO

FHIR
  API commune et primitives indépendantes de version
FHIRR4 / FHIRR4B / FHIRR5
  modèles générés ou adaptés par version
FHIRClient
  REST, recherche, opérations et pagination sur AsyncHTTPClient/SwiftNIO
FHIRValidation
  profils, packages, terminologie et contraintes
FHIRPath
  analyse, évaluation et diagnostics

HL7V3Core
  types de données XML strictement nécessaires à CDA
CDA
  modèle documentaire et narration
CDAValidation
  schémas, templates et profils

HL7Mapping
  transformations et rapports de pertes
```

Règles de dépendance :

- les modèles ne dépendent pas des transports ;
- FHIR, CDA et HL7V2 restent utilisables seuls ;
- un mapping dépend uniquement de ses formats source et cible ;
- le code réseau asynchrone n'envahit pas les modèles ;
- SwiftNIO et AsyncHTTPClient restent les implémentations réseau de référence ;
- les exécutables de démonstration ne définissent pas l'API des bibliothèques ;
- toute dépendance tierce importante doit être justifiée, maintenue et masquée derrière une API HL7Swift lorsque cela protège les consommateurs.

La séparation physique en davantage de targets ne doit intervenir que lorsqu'elle améliore effectivement la taille, les dépendances ou la stabilité des API. Un morcellement prématuré serait aussi coûteux qu'un module monolithique.

## 8. Chantiers transversaux

### 8.1 API pour développeurs tiers

- tutoriels courts par produit et exemples compilés dans la CI ;
- documentation DocC des symboles publics et guides conceptuels ;
- API `async/await` au-dessus de SwiftNIO et types d'erreur structurés ;
- valeurs par défaut sûres, configuration explicite pour les comportements sensibles ;
- politique de dépréciation et guide de migration à chaque rupture ;
- aucune initialisation globale obligatoire pour utiliser les fonctionnalités courantes ;
- possibilité de substituer transport, terminologie, cache et journalisation.

### 8.2 Swift moderne et concurrence

- activer progressivement la vérification stricte de concurrence de Swift 6 ;
- qualifier les types `Sendable` et isoler les états mutables ;
- employer des actors pour les connexions et caches partagés lorsque nécessaire ;
- remplacer les ponts bloquants par des API asynchrones ;
- supprimer les déballages forcés et assertions sur les entrées externes.

### 8.3 Diagnostics communs

Le modèle commun `HL7Core` contient :

- sévérité, code stable et message lisible ;
- format, version et profil concernés ;
- chemin logique et position source lorsque disponibles ;
- règle ou artefact d'origine ;
- étape de validation et état de complétude ;
- cause sous-jacente sans fuite de données sensibles.

Le rapport est disponible comme structure Swift, en JSON et sous forme de texte, sans imposer une interface utilisateur. Le validateur historique HL7 v2 dispose d'un adaptateur `validateReport` dans `HL7V2`, avec des étapes explicitement incomplètes pour les contrôles non exhaustifs. L'adaptation des autres validateurs et mappings reste à réaliser.

### 8.4 Artefacts et génération

- inventorier les fichiers de spécification existants, leurs versions, licences et origines ;
- épingler URL, version, somme de contrôle et date d'import ;
- rendre la génération déterministe et vérifiable en CI ;
- séparer sources normatives, correctifs locaux documentés et sorties générées ;
- ne pas intégrer un contenu normatif dont le droit de redistribution n'est pas établi.

### 8.5 Sécurité et robustesse

- limites configurables de taille, profondeur, répétitions et temps de traitement ;
- parsing XML sans résolution d'entités externes ni accès réseau implicite ;
- validation stricte des URL et politique TLS injectable ;
- secrets et données de santé exclus des journaux par défaut ;
- fuzzing des parseurs et tests systématiques des entrées tronquées ou hostiles ;
- annulation et back-pressure sur les transports réseau.

### 8.6 Portabilité et livraison

- CI macOS, iOS et Linux sur les versions Swift prises en charge ;
- tests iOS au minimum au niveau compilation, complétés par des tests ciblés ;
- builds debug et release ;
- produits SPM vérifiés individuellement par des tests qui n'importent que leur module public ;
- changelog, documentation de compatibilité et matrice de qualification par version publiée.

## 9. Feuille de route

Les jalons sont ordonnés par dépendance technique. Ils ne constituent pas des dates de livraison.

### M0 — Socle modulaire initial

État : réalisé, à consolider.

- mise à jour du manifeste et des dépendances ;
- séparation publique `HL7V2`, `FHIR`, `CDA` et `HL7Mapping` ;
- façades de compatibilité `HL7Swift` et `FHIRSwift` ;
- premiers tests d'indépendance des modules et stabilisation réseau.

Sortie attendue : état actuel reproductible, documenté et sans régression connue.

### M1 — Qualité de bibliothèque et contrat public

- établir la politique de compatibilité et les niveaux de maturité ;
- maintenir la CI macOS/iOS/Linux, les builds release et les tests d'usage public par target ;
- adapter progressivement les validateurs au modèle commun de diagnostics ;
- activer Swift 6 strict target par target ;
- publier une première documentation DocC modulaire ;
- inventorier API publiques, dépendances et artefacts embarqués.

Critère de sortie : chaque produit du package se compile et se teste via son import public, avec une API documentée et une liste de limites connue.

### M2 — Qualification HL7 v2

- auditer la couverture réelle de v2.3 à v2.8.2 ;
- ajouter v2.9 et v2.9.1 après vérification des droits et artefacts ;
- fiabiliser séparateurs, échappements, répétitions, sous-composants, null explicite, jeux de caractères et fins de lignes ;
- couvrir messages, groupes, Z-segments, batch, ACK original et amélioré ;
- stabiliser MLLP, TLS, délais, reconnexion, limites et back-pressure ;
- comparer parsing et sérialisation à des corpus indépendants ;
- publier une matrice version × fonctionnalité × niveau de maturité.

Critère de sortie : aucun message valide du corpus qualifié n'est perdu au round-trip et toute limite de version est déclarée.

### M3 — FHIR versionné et client REST

- définir une façade commune qui n'efface pas les différences entre R4, R4B et R5 ;
- rendre les modèles de version explicitement sélectionnables ;
- prendre en charge JSON puis XML avec `Resource`, `Bundle` et `OperationOutcome` ;
- fournir un client `async/await` fondé sur AsyncHTTPClient/SwiftNIO, avec recherche, pagination, CRUD, historique, opérations, batch et transaction ;
- gérer négociation de contenu, en-têtes FHIR, erreurs HTTP, annulation et politiques de retry sûres ;
- tester contre des serveurs simulés puis plusieurs implémentations externes.

Critère de sortie : un projet consommateur peut choisir sa version sans importer HL7 v2 ni les mappings.

### M4 — FHIRPath et validation FHIR

- implémenter l'analyseur et l'évaluateur FHIRPath avec une suite de conformité ;
- charger de manière déterministe packages, dépendances et `StructureDefinition` ;
- valider cardinalités, types, valeurs fixes, bindings, invariants, profils et slicing ;
- définir une interface de terminologie locale ou distante sans imposer un fournisseur ;
- produire un rapport de validation complet et explicitement `indeterminate` lorsqu'une dépendance manque ;
- comparer les résultats à un validateur de référence sur un corpus versionné.

Critère de sortie : les capacités et lacunes du validateur sont mesurées règle par règle, sans promesse de conformité globale implicite.

### M5 — CDA R2 qualifié

- compléter modèle d'en-tête, participants, sections, entrées et références internes ;
- préserver et sécuriser la narration XHTML ;
- introduire le sous-ensemble nécessaire des types de données HL7 v3 ;
- fournir parsing et sérialisation XML déterministes ;
- appliquer schémas, contraintes, templates et extensions SDTC par étapes distinctes ;
- préserver les signatures sans prétendre pouvoir réécrire un document signé sans les invalider ;
- qualifier des profils CDA nommés avec leurs jeux d'essai.

Critère de sortie : chaque profil annoncé dispose d'une provenance, d'un corpus positif/négatif et de limites documentées.

### M6 — Mappings explicites

- définir un `MappingResult` commun : résultat, diagnostics, provenance et pertes ;
- prioriser les flux cliniques courants : ADT, ORM/OML, ORU, SIU et MDM ;
- établir des mappings HL7 v2 vers FHIR par cas d'usage et version, jamais par simple équivalence de types ;
- ajouter CDA vers FHIR au niveau document et données structurées lorsque la sémantique le permet ;
- tester les invariants métier conservés, plutôt que supposer des round-trips sans perte ;
- rendre les politiques locales injectables et distinctes du socle standard.

Critère de sortie : toute transformation indique ce qui a été produit, ignoré, transformé avec approximation ou rendu impossible.

### M7 — Extensions optionnelles

- primitives SMART App Launch côté client ;
- client Bulk Data Access ;
- étude CQL après stabilisation de FHIRPath ;
- fixtures facilitant certains profils IHE, profil par profil ;
- étude des besoins d'une application serveur FHIR générique utilisant les targets de HL7Swift.

Ces extensions ne doivent pas retarder la qualification des fondations.

## 10. Stratégie de tests et qualification

Chaque domaine doit combiner :

- tests unitaires des valeurs limites ;
- tests de round-trip avec comparaison sémantique ;
- exemples officiels lorsque leur licence le permet ;
- corpus positifs et négatifs maintenus dans le dépôt ou récupérés de façon reproductible ;
- tests génératifs et fuzzing des parseurs ;
- tests réseau sur fragmentation, annulation, délais, TLS et concurrence ;
- comparaison avec des outils ou validateurs de référence indépendants ;
- tests d'intégration contre plusieurs implémentations ;
- tests de compilation et d'exécution macOS/Linux ;
- contrôle des performances et de la mémoire sur des documents réalistes et hostiles.

Une réussite du build ou des tests unitaires ne suffit pas pour qualifier une version normative. Chaque publication doit joindre une matrice de preuves et de limites.

## 11. Prochain lot de travail

Les prochaines modifications recommandées, sous forme de commits séparés, sont :

1. adapter les mappings existants puis FHIR et CDA au modèle `HL7Core`, étape par étape ;
2. auditer et documenter la provenance des ressources HL7 v2 existantes ;
3. établir la matrice de couverture réelle HL7 v2 et les corpus manquants ;
4. exposer une API publique FHIR `async/await` au-dessus d'AsyncHTTPClient/SwiftNIO ;
5. proposer la stratégie de modèles R4/R4B/R5 et mesurer son impact binaire et source ;
6. durcir le parseur CDA XML et étendre progressivement son modèle ;
7. créer un manifeste de couverture lisible par machine, générant les tableaux de documentation.

## 12. Risques et décisions à suivre

| Risque | Réponse attendue |
| --- | --- |
| Étendue excessive de l'écosystème HL7 | Livrer par version, profil et niveau de maturité mesurable |
| Faux sentiment de conformité | Diagnostics gradués, preuves publiées et état `indeterminate` |
| Dépendance forte à un fournisseur de modèles | Façade stable, évaluation régulière et génération reproductible |
| Ruptures d'API pendant Swift 6 | Migration par module, dépréciations et guides de migration |
| Artefacts normatifs incomplets ou non redistribuables | Inventaire de provenance et récupération contrôlée lorsque nécessaire |
| Terminologies volumineuses ou sous licence | Interfaces injectables et packages externes, sans redistribution implicite |
| Multiplication des targets | Fractionnement motivé par l'autonomie et les dépendances, pas par principe |
| Mappings présentés comme universels | Contexte, version, hypothèses et pertes intégrés au résultat |

## 13. Définition de « terminé »

Une capacité n'est terminée que si :

- son périmètre et sa version normative sont explicites ;
- l'API publique est documentée et testée par ses imports publics dans une target de test distincte ;
- les cas positifs, négatifs et limites sont couverts ;
- les plateformes annoncées passent en CI ;
- les diagnostics sont exploitables sans analyser une chaîne de texte ;
- les performances et limites de sécurité sont connues ;
- les licences et provenances des artefacts sont enregistrées ;
- la matrice de couverture et le changelog sont à jour.

Ce document doit être revu à chaque version mineure. Une nouvelle cible normative ou un nouveau profil ne devient pas une promesse de support par sa seule présence dans cette feuille de route.
