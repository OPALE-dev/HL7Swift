# MLLP pour les connecteurs asynchrones

```swift
import HL7V2
import NIOSSL

let connection = MLLPConnection(responseTimeout: .seconds(15))
try await connection.connect(host: "ris.example", port: 2575,
    tls: TLSConfiguration.makeClientConfiguration())
let reply = try await connection.send(try ER7Message(wire))
// Inspect MSA-1: AA/AE/AR or CA/CE/CR. Receiving an ACK is not necessarily
// successful business processing.
try await connection.close()
```

L'application peut fournir son `EventLoopGroup` et une configuration TLS
(trust roots, identité client, politique partenaire). Le groupe fourni reste
propriété de l'application ; le groupe singleton par défaut reste partagé.
Le client vérifie la chaîne et le nom du serveur par défaut lorsqu'une
configuration TLS cliente standard est fournie. `tls: nil` signifie TCP clair.

Un seul échange est autorisé à la fois. MSA-2 doit correspondre à MSH-10.
Un ACK d'erreur applicative reste une réponse reçue, disponible pour la politique
outbox. Après timeout, annulation ou ACK invalide, la socket est fermée : un
ACK tardif ne peut pas valider l'envoi suivant. Il n'y a pas de retry automatique.

Les `MLLPFrameDecoder`/`MLLPFrameEncoder` publics exposent les octets bruts pour
les listeners NIO/Vapor. Le charset et la version déclarée sont interprétés
après le framing par `ER7Message`. Les limites, FS/CR fragmentés, frames
concaténées et EOF tronqués utilisent le même framer que l'adaptateur historique.

Un listener peut produire `message.acknowledgment(code:sendingApplication:
sendingFacility:)`. Les six codes AA/AE/AR et CA/CE/CR sont disponibles ; la
réponse conserve séparateurs, version et événement, et utilise son propre
MSH-10. L'application choisit la phase selon son contrat MSH-15/16 et sa
persistance ; aucune émission automatique des deux phases n'est présumée.

Les essais locaux couvrent framing, deux échanges, version inconnue conservée,
AE, timeout, corrélation et TLS accepté/refusé (confiance et hostname). Les clés
PEM sous `Tests` sont des fixtures publiques générées pour localhost, utilisables
uniquement pour ces essais ; elles ne font pas partie des produits bibliothèque.

Le serveur historique `HL7Server` reste disponible mais son delegate synchrone
ne constitue pas une inbox durable. Un listener applicatif doit attester la
persistance requise avant l'ACK positif. Le client doit être fermé explicitement
par son propriétaire, notamment à l'arrêt du service.
