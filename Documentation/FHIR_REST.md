# Client FHIR R4 REST

Le nouveau `FHIRR4RESTClient` utilise `async/await` et les modèles `ModelsR4`.
Le transport est injectable. L'application possède le cycle de vie du client
HTTP et sa politique TLS/authentification ; aucun compte ou serveur FHIR externe
n'est requis par la bibliothèque.

Ce client ne monte pas d'endpoints HTTP. Pour le rôle serveur en lecture,
voir [les primitives serveur R4](FHIR_SERVER.md).

```swift
import FHIR
import ModelsR4
import AsyncHTTPClient

let http = HTTPClient(eventLoopGroupProvider: .singleton)
let api = try FHIRR4RESTClient(
    baseURL: URL(string: "https://hospital.example/fhir")!,
    transport: AsyncFHIRHTTPTransport(client: http),
    headers: ["Authorization": "Bearer <application-token>"]
)
let page = try await api.search("ServiceRequest", parameters: [
    URLQueryItem(name: "subject", value: "Patient/example")
])
if let bundle = page.resource?.get(if: ModelsR4.Bundle.self) {
    // All entries, links and totals are available, including empty searchsets.
    let next = try await api.nextPage(bundle)
}
// The HTTP owner shuts down `http` when its application/service stops.
```

Interactions : lecture, création POST, mise à jour PUT, suppression, recherche,
CapabilityStatement, historique, lecture versionnée et Bundles batch/transaction.
`If-Match` et `If-None-Exist` sont explicites. Les réponses minimales de création,
mise à jour et suppression peuvent avoir un corps vide ; Location, ETag et
Last-Modified restent disponibles.

Un statut HTTP d'échec lève `FHIRRESTError.http(status:outcome:)`, avec
OperationOutcome si présent. Le client n'écrit ni corps de réponse ni token
dans les journaux. La pagination refuse les liens hors de l'origine et du
chemin de base afin de protéger les headers d'autorisation. Le transport AHC
borne le corps reçu à 16 Mio et utilise un délai de 30 secondes par défaut.

Le client applique les interactions du [REST FHIR R4 officiel](https://hl7.org/fhir/R4/http.html).
Les tests couvrent les requêtes, les réponses et des erreurs synthétiques ; ils
ne démontrent pas une intégration avec un serveur partenaire ni une conformité
à un profil. L'authentification OAuth/SMART, les opérations personnalisées, le
PATCH et la validation de profils restent à compléter. L'ancien `FHIRClient`
reste une API historique ; privilégier cette API pour le code serveur nouveau.

`FHIRR4ReferenceResolver(bundle:)` résout sans réseau les références contained,
les URN/fullUrl et les références relatives déjà présentes dans un Bundle.
Une ambiguïté d'identifiant entre serveurs est refusée ; fournir le fullUrl
de la ressource contenant la référence pour sélectionner la base appropriée.
Les références versionnées ne sont pas encore résolues par cet index.

Les tests HTTP par défaut créent leur propre serveur loopback sur port aléatoire.
Les anciens essais d'écriture vers un service FHIR sont ignorés tant que
`HL7_TEST_FHIR_BASE_URL` ne désigne pas explicitement un serveur jetable.
