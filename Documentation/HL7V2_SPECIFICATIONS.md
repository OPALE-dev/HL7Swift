# Implémentation HL7 v2 autonome

La bibliothèque ne charge et ne redistribue aucune spécification HL7 v2.
Aucun répertoire, XSD ou téléchargement n'est nécessaire pour parser, écrire,
construire, contrôler ou transporter les messages pris en charge.

Les documents fournis localement servent de référence au développement.
L'implémentation native est écrite en Swift ; elle n'est pas une conversion
des XSD en tables normatives embarquées. Les anciennes API de chargement
externe ont été supprimées après clarification de cette contrainte.

## API native prioritaire

`ER7Message` conserve les messages, y compris versions inconnues et segments
locaux. `V2MessageBuilder` produit les événements ADT A01/A02/A03/A04/A05/A08/
A28/A31/A40, ORM O01, OMI O23, ORU R01 et MDM T02. Ses primitives patient,
ordre, résultat textuel et identifiants antérieurs échappent les valeurs avant
composition. Un segment partenaire peut être ajouté explicitement.

`V2NativeValidator` exécute des contrôles de contrat implémentés dans le code :
enveloppe, présence des segments ciblés, identifiants patient/ordre, autorité
requise selon la politique et codes ACK. Son rapport décrit précisément ces
contrôles ; les contraintes de profils non implémentées restent `notRun`.
Un rapport sans erreur ne signifie pas une conformité complète au standard.

## Compatibilité

`HL7()` installe ses modèles de travail natifs pour les familles prioritaires.
Les noms de champs courants, la construction historique et les accès Terser
plats fonctionnent sans fichiers. Les arbres de groupes anciennement issus
des XSD ne sont plus annoncés comme disponibles : utiliser les projections
patient/ordre/résultat pour les contextes cliniques.

`Versioned.loadXML()` est seulement une méthode de compatibilité dépréciée :
elle recharge les modèles natifs et ne lit aucun XML. `HL7CodeGen` peut exporter
les symboles de ces modèles via `--output-directory` ; il ne lit pas de lot HL7.

Les contrôles historiques restent partiels. Privilégier la validation native
et des corpus partenaires qualifiés plutôt qu'une supposée conformité issue
de la seule présence d'un symbole de version.
