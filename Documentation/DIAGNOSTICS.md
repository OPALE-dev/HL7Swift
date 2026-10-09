# Diagnostics communs

`HL7Core` est une target du package HL7Swift. Elle expose `HL7Diagnostic`, `HL7ValidationStage` et `HL7DiagnosticReport` sans dépendre de HL7 v2, FHIR ou CDA. Les quatre modules publics réexportent ces types.

Chaque diagnostic possède un code stable, une sévérité et un message lisible. Il peut préciser le standard, sa version, un profil, un emplacement dans l'entrée et la règle ou l'artefact qui motive le constat. `causeCode` sert à identifier une cause technique sans incorporer le contenu brut d'un document ou une erreur contenant des données sensibles.

Un rapport déclare les étapes que le producteur a prévu de réaliser. Chaque étape est `complete`, `incomplete` ou `notRun`. Son résultat calculé suit ces règles :

- `invalid` si au moins un diagnostic a la sévérité `error` ;
- `indeterminate` si aucune erreur n'a été trouvée, mais qu'une étape manque ou qu'aucune étape n'a été déclarée ;
- `valid` si toutes les étapes déclarées sont complètes et qu'aucune erreur n'a été trouvée.

Un rapport `valid` concerne uniquement les étapes effectivement déclarées. L'appelant doit donc connaître la portée du validateur avant de l'interpréter comme une preuve de conformité à un profil.

```swift
import HL7V2

let report = HL7DiagnosticReport(
    stages: [HL7ValidationStage(identifier: "syntax", status: .complete)],
    diagnostics: []
)
print(report.outcome)     // valid
print(report.renderText())
```

Le rapport et ses éléments sont `Codable`, `Equatable` et `Sendable`.

Le validateur HL7 v2 expose `DefaultValidator.validateReport(_:level:)` depuis la target `HL7V2`. Il appelle le validateur historique sans modifier `validate(_:level:)`, puis transforme ses constats en diagnostics `HL7V2-LEGACY-*`. Les étapes `v2.version`, `v2.segments`, `v2.fields` et `v2.datatypes` correspondent au niveau demandé. Seule la vérification de version peut être marquée `complete`, quand une spécification de message correspondant à la version déclarée est disponible. Les contrôles plus profonds restent `incomplete` : leur implémentation actuelle n'est pas exhaustive. Le parsing précède cet appel et ne figure pas parmi ses étapes.

```swift
import HL7V2

let hl7 = try HL7()
let message = try Message("MSH|^~\\&|||||||ACK|1|P|2.5.1\rMSA|AA|1", hl7: hl7)
let report = DefaultValidator().validateReport(message, level: .segments)
print(report.outcome) // indeterminate si aucun constat bloquant
```

Les messages textuels hérités sont conservés ; certains peuvent inclure une valeur du message HL7 d'origine. Traitez donc le rapport comme une donnée potentiellement sensible avant journalisation ou export. Les autres validateurs et mappings seront adaptés progressivement.

## Mapping HL7 v2 vers FHIR R4

`HL72FHIRR4Converter.mapWithReport(_:)`, dans `HL7Mapping`, renvoie un `HL7MappingResult<ModelsR4.Bundle>` avec le bundle éventuel, un `HL7DiagnosticReport`, la provenance du convertisseur et les pertes connues. La méthode historique `convert(_:)` garde son comportement. Le mapping actuel accepte `ORU_R01` et produit seulement les ressources issues de MSH, PID et PV1 ; les autres segments présents sont signalés sans copier leurs valeurs dans les diagnostics. Les répétitions de segments que le convertisseur ne traite pas sont également signalées.

```swift
import HL7Mapping

let result = try HL72FHIRR4Converter().mapWithReport(message)
print(result.provenance.targetVersion) // R4
print(result.losses.map(\.sourcePath))
```

L'étape `v2-to-fhir-r4` reste `incomplete`, même si aucune perte de segment n'est détectée : la couverture des champs et les invariants cliniques ne sont pas encore qualifiés. Un type de message non pris en charge renvoie `output == nil`, une perte explicite et un résultat `indeterminate`. Une exception du convertisseur produit un diagnostic d'erreur sans recopier l'exception potentiellement sensible. Ce rapport décrit la transformation, pas la validité normative du message source ni celle du bundle FHIR.

## Première validation FHIR R4

`FHIRR4Validator.validateJSON(_:)`, dans la target `FHIR`, contrôle que l'entrée est un objet JSON, possède un `resourceType` et peut être décodée par les modèles R4 embarqués. Les étapes `fhir.r4.json` et `fhir.r4.model` indiquent ces contrôles. Les étapes `fhir.r4.profiles`, `fhir.r4.invariants` et `fhir.r4.terminology` restent `notRun` ; une ressource décodée donne donc `indeterminate`, jamais une preuve de conformité FHIR complète.

```swift
import FHIR

let report = FHIRR4Validator().validateJSON(Data(#"{"resourceType":"Patient"}"#.utf8))
print(report.outcome) // indeterminate
```

Une entrée malformée, non objet, sans `resourceType` ou non décodable comme modèle R4 produit un diagnostic `error`. Un type de ressource inconnu des modèles embarqués produit un avertissement et reste `indeterminate` : il peut relever d'une autre version. Les diagnostics n'incorporent ni le JSON brut ni la description des exceptions de décodage.

## Analyse CDA R2

`CDAParser.parseWithReport(_:)` renvoie un `CDAParseResult` contenant l'enveloppe extraite, si disponible, et un rapport `HL7Core`. L'ancienne méthode levante `parse(_:)` reste inchangée.

```swift
import CDA

let result = CDAParser().parseWithReport(xml)
print(result.document?.title as Any)
print(result.report.outcome) // indeterminate pour une enveloppe extraite
```

Les étapes `cda.xml` et `cda.root-name` deviennent `complete` après parsing et reconnaissance du nom racine. `cda.envelope` reste `incomplete` : le modèle ne couvre qu'une partie de l'en-tête et ne vérifie pas encore l'espace de noms. Les étapes `cda.schema`, `cda.templates` et `cda.narrative` restent `notRun`. Un XML malformé ou un nom racine différent produit un diagnostic `error` sans recopier le contenu ni le message d'erreur brut du parseur. Le rapport ne constitue pas une qualification CDA R2.
