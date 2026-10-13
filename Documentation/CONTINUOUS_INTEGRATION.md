# Intégration continue GitLab

La pipeline définie dans `.gitlab-ci.yml` qualifie le package sur les trois plateformes annoncées. Les jobs sont indépendants et s'exécutent en parallèle.

| Job | Runner | Vérifications |
| --- | --- | --- |
| `linux-package` | Docker, tag `deploy` | Swift 6.1, build release et tests SwiftPM |
| `macos-package` | macOS, tag `swift` | build release et tests SwiftPM avec la toolchain Xcode installée |
| `ios-package` | macOS, tag `swift` | build de tout le package pour iOS et tests sur le simulateur le plus récent |

## Prérequis des runners

Le runner `deploy` doit accepter les images Docker et pouvoir récupérer l'image officielle `swift:6.1` ainsi que les dépendances Swift Package Manager.

Le runner `swift` doit utiliser l'exécuteur shell sur macOS et fournir :

- Xcode et ses outils en ligne de commande ;
- au moins un runtime iOS avec un simulateur iPhone disponible ;
- un accès réseau aux dépôts des dépendances SwiftPM.

Aucun certificat ni profil de provisioning n'est requis : la compilation iOS désactive explicitement la signature. Le runner choisit dynamiquement le premier iPhone du runtime iOS installé le plus récent afin de ne pas dépendre d'un nom de modèle particulier.

## Résultats conservés

Les tests macOS publient un rapport JUnit visible dans l'onglet de tests GitLab.
Linux conserve le journal complet sous `.reports/linux-tests.log` et exécute
XCTest en série : des processus enfants sont restés bloqués de façon intermittente
avec le runner parallèle Swift 6.1 lors des vérifications locales, y compris avec
deux workers, alors que le test concerné réussit isolément. La cause reste à
diagnostiquer ; ce changement n'est pas une preuve que le problème vient de SwiftPM.
SwiftPM n'émet pas le rapport xUnit XCTest dans le mode série testé.
Le job iOS conserve son bundle `xcresult` pendant 30 jours, y compris en cas
d'échec, afin de permettre l'analyse détaillée dans Xcode.

La pipeline ne remplace pas une matrice de conformité aux standards HL7. Elle établit que le commit compile en release et que les tests automatisés passent sur les plateformes annoncées.
