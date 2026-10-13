# Artefacts HL7 v2 externes

HL7Swift ne distribue aucune spécification HL7 v2, aucun XSD et aucun jeu de
valeurs sous licence HL7. Le package reste autonome pour les usages nécessaires
à une passerelle clinique : lecture et écriture ER7, séparateurs, segments non
standard, MLLP/TLS et acquittements.

Les fonctions qui dépendent réellement de la structure normative (construction
préremplie, groupes, noms de champs et validation structurelle approfondie)
peuvent recevoir un lot local, obtenu et licencié par le déployeur :

```swift
let source = HL7V2SpecificationSource(
    directory: URL(fileURLWithPath: "/opt/hl7/approved-xsd")
)
let hl7 = try HL7(specificationSource: source)
```

Le répertoire attendu est `v<version>/` : par exemple
`v2.5.1/messages.xsd`, `datatypes.xsd`, `fields.xsd`, `segments.xsd` et les
fichiers `messages/<structure>.xsd`. Aucun téléchargement n'est effectué et
l'absence d'un fichier désactive seulement les métadonnées correspondantes.

Les lots HL7 fournis à plat peuvent être utilisés sans copie ou import :

```swift
let source = HL7V2SpecificationSource(directory: licensedRoot,
    versionDirectories: ["2.5.1": flatVersionDirectory])
let hl7 = try HL7(specificationSource: source)
```

Des tests avec XML minimal écrit à la main qualifient ce chargement optionnel,
indépendamment des tests historiques nécessitant un lot licencié. DTD et
entités sont refusées ; aucun import XSD ou accès externe n'est résolu.
L'outil `HL7CodeGen` exige désormais `--specification-directory` et
`--output-directory`, et ne peut plus utiliser implicitement un bundle.

Un intégrateur doit conserver la provenance, la version exacte, les errata et
les droits de redistribution de son lot. Le dossier de travail local fourni à
l'équipe ne devient pas une dépendance de package et n'est jamais embarqué dans
un binaire ou une archive SPM.
