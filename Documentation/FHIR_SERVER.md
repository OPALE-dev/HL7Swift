# Primitives serveur FHIR R4

`FHIRR4ReadServer` fournit une couche HTTP **en lecture**, sans serveur à lancer,
sans dépendance Vapor et sans persistance FHIR parallèle. Importer `FHIR` et
`ModelsR4`. Le client REST existant et cette couche serveur sont indépendants.

## Configuration explicite

```swift
let api = try FHIRR4ReadServer(
    baseURL: URL(string: "https://elena.example/fhir/R4")!,
    capabilities: [
        .init(resourceType: "Patient", parameters: [
            .init(name: "identifier", type: .token)
        ]),
        .init(resourceType: "ImagingStudy", parameters: [
            .init(name: "patient", type: .reference),
            .init(name: "started", type: .date)
        ]),
        .init(resourceType: "Endpoint", search: false)
    ],
    publicationDate: deploymentDate
)
```

Ne déclarer que les recherches effectivement implémentées. `_id` est annoncé
pour chaque ressource recherchable : le backend doit assurer sa correspondance
exacte. Une recherche `identifier` conserve son système et sa valeur ; une
référence `patient` doit être résolue selon les identités FHIR du domaine.
Le parseur conserve les expressions, il n'exécute pas leurs prédicats.

## Contrat d'intégration

Après authentification et autorisation, appeler `respond(to:read:search:)` avec
un `FHIRHTTPRequest` et deux callbacks **scopés au principal courant** :

```swift
let response = await api.respond(to: wireRequest,
    read: { type, id in
        // Lire/projeter le domaine autorisé. nil => 404.
        try await authorizedRepository.readFHIR(type: type, id: id)
    },
    search: { query in
        // Appliquer les critères FHIR et le curseur à la requête autorisée.
        try await authorizedRepository.searchFHIR(query)
    }
)
```

`authorizedRepository` est une abstraction de l'application, pas un objet
fourni par HL7Swift. Le résultat de lecture est un `ResourceProxy`. La recherche
renvoie `FHIRR4ServerSearchPage(resources:total:nextPageToken:)`. Les objets
ModelsR4 sont des classes : ne pas les modifier pendant la sérialisation.

Dans Vapor, l'adaptateur ELENA traduit méthode, URL, en-têtes et corps vers
`FHIRHTTPRequest`, puis statut, en-têtes et octets de `FHIRHTTPResponse` vers
la réponse Vapor. Monter les routes sous la même base `/fhir/R4` ; transmettre
le chemin complet, pas seulement l'identifiant. Ne pas réencoder le corps JSON.
Authentification, 401/challenge OAuth, autorisations, TLS, limites du corps HTTP,
audit et masquage des journaux de recherche restent dans les middlewares ELENA.

## Sous-ensemble implémenté

- `GET [base]/metadata` : CapabilityStatement R4 4.0.1 JSON avec ressources,
  interactions read/search-type et recherches configurées ; pas de capacité d'écriture.
- `GET [base]/[type]/[id]` : lecture, 404, ETag faible dérivé de `meta.versionId`,
  Last-Modified dérivé de `meta.lastUpdated`, If-None-Match/If-Modified-Since et
  304 sans corps. La version et l'horodatage viennent du domaine, pas d'un compteur local.
- `GET [base]/[type]` et `POST [base]/[type]/_search` form-encodé : expressions
  répétées conservées, paramètres supportés explicites, `_count` borné
  (20 par défaut, maximum 200), `_count=0` et curseur opaque `_pageToken`.
- Bundle searchset avec matches, total facultatif et liens self/next.
  Les URL sortantes viennent de la base canonique configurée, jamais du Host
  reçu ni d'une URL proposée par le backend. Les fullUrl ne sont pas versionnés.
- Négociation JSON via Accept ou `_format`, 406/415, 405 avec Allow et
  OperationOutcome sans réflexion des données patient ou erreurs de stockage.

Le backend doit fournir des ressources du bon type avec des ids FHIR stables
et uniques, respecter `_count` et garantir des curseurs liés au principal,
aux critères et à un ordre stable. `total` compte les correspondances autorisées,
pas les seules ressources de cette page. Ne pas exposer les données d'un
autre patient dans les compteurs ou tokens. Ne pas utiliser un UID DICOM comme
identité patient et ne pas fusionner implicitement les autorités d'identifiants.

Les recherches inconnues, modifiers/chains non déclarés et paramètres comme
`_include` sont refusés (400), même avec `Prefer: handling=lenient`. C'est une
politique stricte explicite, pas une annonce de toutes les possibilités FHIR.
Les valeurs vides des paramètres supportés sont ignorées. Le backend interprète
les dates, tokens, références, échappements et AND/OR ; éviter toute concaténation SQL.
Pour déclarer un modifier/chaînage réellement implémenté, utiliser `acceptedNames`.

Les expressions sont limitées à 100 paramètres, 16 Kio de query/form et 4 Kio
par valeur. Les réponses normales sont bornées à 16 Mio après encodage
(`maximumResponseBytes` configurable) ; une erreur de contrat produit un
OperationOutcome fixe. Cette borne ne remplace pas une projection backend
bornée avant allocation/encodage, notamment pour les instances d'une étude.

## Projection d'imagerie

`FHIRR4ImagingProjection.imagingStudy` construit une représentation d'échange
à partir d'un snapshot fourni par l'application : id FHIR, Study Instance UID,
id patient FHIR, statut explicite, références Endpoint, séries et instances.
Le Study UID utilise l'identifiant `urn:dicom:uid`/`urn:oid:` ; les UID des séries
et instances restent bruts et la classe SOP utilise `urn:ietf:rfc:3986`.

```swift
let study = try FHIRR4ImagingProjection.imagingStudy(
    id: studyFHIRID, studyUID: studyInstanceUID, patientID: patientFHIRID,
    status: .available, endpointIDs: ["wado"],
    series: [.init(uid: seriesInstanceUID, modality: "CT", instances: [
        .init(uid: sopInstanceUID, sopClassUID: sopClassUID)
    ])]
)
let endpoint = try FHIRR4ImagingProjection.wadoRSEndpoint(
    id: "wado", address: dicomwebBaseURL, status: .active
)
```

Ces noms d'identifiants/URL sont des entrées du domaine applicatif. Le helper
ne choisit pas le patient, la disponibilité ou les droits. Les tableaux fournis
décrivent le sous-ensemble complet représenté ; les compteurs portent sur ce
sous-ensemble autorisé, pas sur le nombre de frames ni un total caché.
`series: nil` ou `instances: nil` signifie inconnu/non chargé, et n'est pas
transformé en zéro. Le helper ne génère pas de liens signés ni d'en-têtes secrets.
Il vérifie la forme des UID et les doublons, pas leur autorité d'enregistrement
ni toutes les contraintes/profils DICOM/FHIR. Les modalités ne sont pas validées
contre une terminologie. Patient se construit directement avec les modèles R4,
selon les identités/autorités conservées dans ELENA.

## Limites et qualification

Pas d'écriture, vread/history, batch/transaction serveur, XML, recherche système,
compartiments, `_include`, FHIRPath, validation exhaustive de profils ou actor IHE.
Le CapabilityStatement n'est pas un certificat de conformité. MHD et les profils
d'imagerie doivent être choisis et qualifiés par cas d'usage, pas déduits du mot PACS.

Les tests couvrent les modèles JSON des réponses, la négociation, les paramètres,
le contrat backend, la pagination, les conditions HTTP et les erreurs sûres.
Un test connecte le client public au serveur via un transport en mémoire ; un
autre effectue réellement metadata/read/search/404 sur HTTP loopback avec NIO.
L'intégration Vapor/PostgreSQL d'ELENA et un client FHIR indépendant restent à qualifier.

Références : [REST FHIR R4](https://hl7.org/fhir/R4/http.html),
[recherche R4](https://hl7.org/fhir/R4/search.html).
Projection : [ImagingStudy R4](https://hl7.org/fhir/R4/imagingstudy.html) et
[Endpoint WADO-RS](https://hl7.org/fhir/R4/endpoint-example-wadors.json.html).
