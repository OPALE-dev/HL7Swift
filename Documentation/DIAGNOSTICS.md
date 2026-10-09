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

Le rapport et ses éléments sont `Codable`, `Equatable` et `Sendable`. Les validateurs actuels conservent encore leurs résultats historiques ; leur migration vers ce format sera progressive.
