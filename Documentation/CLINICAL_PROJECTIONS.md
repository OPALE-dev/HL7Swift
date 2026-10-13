# Projections cliniques de lecture

## HL7 v2

```swift
let message = try ER7Message(wire, policy: connectorPolicy)
let clinical = V2ClinicalProjection(message)
```

Cette lecture positionnelle expose PID, PV1-19, MRG-1, ORC, OBR et OBX.
Les identifiants CX/EI conservent valeur, namespace, identifiant universel,
type d'identifiant universel et type d'identifiant. Les noms et valeurs
composites restent bruts et le message source est conservé par l'application.
Les indices de segments sont zéro-based dans le tableau `segments` ; les
positions de champs ER7 restent one-based.

Plusieurs patients et ordres sont projetés en gardant leurs frontières.
`patientIndex` et `orderIndex` associent les résultats à leur contexte. Un
nouveau PID réinitialise le contexte d'ordre ; les ORC sans OBR, notamment
les demandes d'annulation, restent représentés. Les segments non projetés
(NTE, Z-segments, etc.) sont inventoriés par indice pour éviter une perte tacite.
Les notices contiennent des codes stables, jamais les valeurs cliniques.

MRG fournit des identifiants antérieurs et une notice de politique obligatoire.
Il n'effectue pas de fusion. OBR-18 reste un champ opaque du demandeur ; son
interprétation comme accession doit appartenir au contrat partenaire. Les
statuts ORC/OBR/OBX, dates, codes et autorités ne sont pas normalisés implicitement.
Ce modèle partiel n'est pas une commande Worklist/MPPS ni un mapping complet
vers FHIR ; les champs non projetés restent dans le message ER7.

## CDA

`CDAParser().parse(xml)` expose maintenant `recordTargets` (identifiants,
noms, naissance, sexe administratif) et `sections` en ordre documentaire.
Chaque section conserve ses identifiants/templateIds, code, titre, texte
narratif et nombre d'entrées directes. `parentIndex` restitue la hiérarchie.
La lecture respecte les chemins et namespaces CDA ; les arbres étrangers ne
peuvent pas injecter une identité ou une section.

`narrativeText` est une projection texte pour la consultation. Aucun HTML
exécutable n'est rendu ; les références internes, styles et tableaux ne sont
pas reproduits intégralement. Conserver le XML original pour la traçabilité,
les signatures et les entrées structurées. La limite par défaut est 16 Mio
et 128 niveaux. DTD, entités et résolution externe restent interdits.

Ces capacités sont couvertes par fixtures synthétiques. Le rapport reste
`indeterminate` tant que schémas, templates et contraintes ne sont pas qualifiés.
