# Inventaire et provenance des ressources HL7 v2

**Archive historique** : les 1 816 XSD ont été retirés le 13 octobre 2026.
Le package ne les redistribue plus. Les observations ci-dessous décrivent le
lot ancien ; voir [le chargement explicite](HL7V2_SPECIFICATIONS.md) pour l'API
actuelle. L'historique Git permet de retrouver cet état antérieur.

État au 9 octobre 2026. Cet inventaire concerne uniquement les XSD présents dans
`Sources/HL7Swift/Spec/Resources`. Il ne constitue ni une qualification des
schémas, ni une conclusion juridique sur leur redistribution.

## Inventaire reproductible

Les 11 répertoires contiennent 1 816 fichiers XSD. Le fichier
[`HL7V2_RESOURCES.lock`](HL7V2_RESOURCES.lock) donne, pour chaque version, le
nombre de fichiers et l'empreinte SHA-256 de l'arbre. L'empreinte est calculée
sur les lignes `SHA256(contenu)  chemin/relatif`, triées par chemin en locale C,
avec un saut de ligne final. Les fichiers `.DS_Store` locaux sont ignorés.

```sh
bash Documentation/verify-v2-resources.sh
```

| Répertoire | XSD | Première introduction observée dans Git |
| --- | ---: | --- |
| v2.3 | 14 | `210d325` (25 décembre 2021) |
| v2.3.1 | 37 | `210d325` |
| v2.4 | 160 | `210d325` |
| v2.5 | 194 | `210d325` |
| v2.5.1 | 193 | `a42d0dd` (24 décembre 2021) |
| v2.6 | 215 | `a42d0dd` |
| v2.7 | 196 | `210d325` |
| v2.7.1 | 196 | `210d325` |
| v2.8 | 207 | `210d325` |
| v2.8.1 | 211 | `210d325` |
| v2.8.2 | 193 | `a42d0dd` |

Ces commits établissent seulement l'entrée dans ce dépôt, pas la source amont.
Les en-têtes des XSD attribuent le copyright 1999–2016 à Health Level Seven et
indiquent une génération le 17 novembre 2016 par `HL7-Database`, à partir de
`hl7_92.mdb`. Aucune archive amont exacte, URL d'origine, empreinte de l'archive
ou licence spécifique accompagnant ces copies n'a été retrouvée dans le dépôt.

## Anomalie bloquante pour v2.8.2

Les 189 fichiers de `v2.8.2/messages/` portent dans leur en-tête « Version
2.5.1 » et sont tous identiques octet pour octet aux 189 fichiers homonymes
de `v2.5.1/messages/`. À l'inverse, les fichiers de tête de `v2.8.2`, tels
que `messages.xsd` et `fields.xsd`, annoncent la version 2.8.2. La collection
est donc incohérente : **ses définitions de messages ne doivent pas être
présentées comme qualifiées pour v2.8.2**. Cette observation ne suffit pas à
déterminer quelle archive officielle devrait les remplacer.

## Statut des sources et des droits

[HL7 décrit ses schémas de messages v2](https://dev3.hl7.org/implement/standards/product_brief.cfm?product_id=213)
comme des représentations de commodité, non normatives en elles-mêmes, et
signale des errata publiés en octobre 2019 pour v2.6 à v2.8.2. Les en-têtes
datés de 2016 ne démontrent donc pas que les corrections ultérieures sont
présentes dans cette copie.

La [politique de propriété intellectuelle de HL7](https://dev3.hl7.org/legal/ippolicy.cfm)
couvre notamment les documents XML et encadre l'incorporation et la
redistribution du matériel HL7. Les XSD sont actuellement copiés dans le
produit SwiftPM par `Package.swift`. La licence du code HL7Swift ne suffit pas
à démontrer un droit de redistribution de ces ressources tierces : les termes
applicables ou une autorisation écrite doivent être vérifiés avant de déclarer
la question résolue. Ce point est une incertitude à instruire, pas une
affirmation d'illégalité.

## Lot v2.8.2 fourni pour comparaison

Un dossier local nommé `HL7-xml v2.8.2` a été fourni le 9 octobre 2026. Il
contient 212 XSD à plat et un index `MessageStructureID.html`. Tous les XSD
portent un en-tête « Version 2.8.2 », un copyright HL7 1999–2022 et une
génération datée du 27 mai 2022 depuis `hl7_97.mdb`. L'empreinte SHA-256 de
l'arbre des 212 XSD, calculée comme dans le fichier `.lock` avec les noms de
fichiers à la racine, est
`2da4d8a9747b6a1dd577f3f321df212937efcbae1f28eccdd1971b5b431e5597`.
Il ne s'agit pas de l'empreinte de l'archive d'origine.

Comparé aux 193 XSD actuellement embarqués sous v2.8.2 : 150 noms sont
communs, sans fichier identique octet pour octet ; 62 noms n'existent que dans
le lot fourni et 43 seulement dans le dépôt. Le lot contient 208 définitions
de messages et quatre XSD communs (`messages`, `segments`, `fields`,
`datatypes`). Les 212 documents sont XML bien formés et leurs références
`schemaLocation` visent des fichiers présents dans le dossier. Ces contrôles
ne prouvent pas la validité XSD ni la conformité HL7.

Deux écarts techniques interdisent un remplacement aveugle :

- le code généré `V282.swift` référence `OMQ_O42`, `ORX_O43` et `OSU_O41`, là
  où le lot fourni contient `OMQ_O57`, `ORX_O58` et `OSU_O51` ;
- `datatypes.xsd` contient 13 extensions avec `base="-"`. `xmllint` signale
  cette valeur comme un QName invalide et ne peut pas compiler
  `messages.xsd` en schéma XSD.

La [fiche HL7 v2.8.2](https://dev3.hl7.org/implement/standards/product_brief.cfm?product_id=444)
annonce une archive et des errata, mais son téléchargement exige une
authentification ; nous n'avons donc pas établi l'égalité du dossier fourni
avec une archive officielle précise. Le dossier ne contient pas de licence
autorisant explicitement sa redistribution. Aucun de ses XSD n'a été copié
dans le package à ce stade.

## Suite de M2.1

1. Obtenir les archives officielles exactes et leurs conditions d'utilisation
   pour chaque version, en conservant URL, date et empreinte.
2. Comparer fichier par fichier les copies embarquées aux archives, y compris
   les errata de 2019 et le répertoire v2.8.2 incohérent ; qualifier les
   anomalies XSD et synchroniser le code généré avant remplacement.
3. Confirmer le droit de publier ces XSD dans le package ; à défaut, définir
   une distribution ou une génération compatible avec les droits obtenus.

Aucune ressource existante n'a été remplacée ou retirée dans cet inventaire.
