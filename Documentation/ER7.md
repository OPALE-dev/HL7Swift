# ER7 autonome pour les connecteurs

`ER7Message` est un type valeur `Sendable`, sans ressource de spécification.
Le message reste modifiable par positions HL7 et conserve sa version déclarée,
les champs vides finaux, les répétitions et les segments locaux.

```swift
import HL7V2

let policy = ER7ParsingPolicy(
    acceptedVersions: ["2.3", "2.5.1", "2.9.1"],
    interpretationVersion: "2.5.1"
)
var message = try ER7Message(wire, policy: policy)
let identifier = message.rawValue(segment: "PID", field: 3, component: 1)
let authority = message.rawValue(segment: "PID", field: 3, component: 4)
try message.setRawValue(message.escape("Nom|composé"), segment: "PID", field: 5)
let output = message.serialized()
```

La politique par défaut accepte CR/LF/CRLF et toute version non vide. La
politique `.strict` exige CR et une version connue. Une interprétation forcée
est conservée séparément de `declaredVersion` et produit une notice ; aucun
repli automatique vers une autre structure n'est réalisé.

L'interprétation forcée ne valide pas la forme du message. Le connecteur doit
qualifier les événements, champs, autorités et règles attendus avec son partenaire.
La bibliothèque n'infère pas une identité patient d'un identifiant sans autorité.

Les positions et occurrences commencent à 1. `ER7Value(raw:)` différencie
`.absent`, `.empty`, `.null` (`""`) et `.value`. La séparation en répétitions,
composants et sous-composants utilise MSH-1/2 ; `unescape` est explicite et
conserve les séquences locales/inconnues. Les octets doivent être décodés avec
le charset négocié, via `init(data:encoding:policy:)`. Un MSH-18 ne provoque
pas de transcodage implicite.

Cette première API conserve le texte ER7 ; elle n'est pas un moteur de groupes,
de batch, de contraintes de datatype ou de profils IHE. L'ancienne `Message`
reste disponible pour les intégrations existantes et les fonctionnalités à
métadonnées externes.
