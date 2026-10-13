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

Les tests Linux et macOS publient un rapport JUnit visible dans l'onglet de tests GitLab. Le job iOS conserve son bundle `xcresult` pendant 30 jours, y compris en cas d'échec, afin de permettre l'analyse détaillée dans Xcode.

Lors du lot serveur FHIR du 13 octobre, des exécutions locales Linux Swift 6.1.3
sont restées bloquées, aussi bien en parallèle qu'en série. Une trace LLDB montre
`XCTestCase.performTearDownSequence` attendant `awaitUsingExpectation` dans
XCTWaiter/CFRunLoop, sans frame de code HL7Swift sur la pile bloquée. Des tests
concernés réussissent isolément, dont le serveur HTTP réel. Cela localise
l'attente mais ne prouve pas sa cause. Le passage en série n'ayant pas résolu
le problème, la configuration CI parallèle bornée est conservée. Ne pas
assimiler un build Linux réussi ou ces tests isolés à une suite Linux complète verte.

La pipeline ne remplace pas une matrice de conformité aux standards HL7. Elle établit que le commit compile en release et que les tests automatisés passent sur les plateformes annoncées.
