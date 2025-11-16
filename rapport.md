# Rapport TP 3 : Sécurité des Conteneurs et Monitoring en Runtime

## Étape 1 : Création d'une Image Docker avec Vulnérabilités

### Objectif
Créer une application Docker intentionnellement vulnérable pour pouvoir ensuite identifier et corriger les problèmes de sécurité.

### Application créée
J'ai développé une application web simple en Python Flask (`app.py`) qui présente plusieurs vulnérabilités intentionnelles :

1. **Secrets hardcodés** : Mots de passe et clés API directement dans le code source
2. **Exposition d'informations sensibles** : Endpoints `/info` et `/env` qui révèlent des secrets
3. **Exécution de commandes système** : Endpoint `/execute` qui permet l'exécution arbitraire de commandes shell
4. **Mode debug activé** : Flask est lancé en mode debug en production

### Dockerfile vulnérable
Le `Dockerfile` créé contient plusieurs mauvaises pratiques de sécurité :

1. **Image de base ancienne** : Utilisation de `python:3.8` qui peut contenir des vulnérabilités connues
2. **Packages système inutiles** : Installation d'outils comme `nmap`, `netcat`, `telnet` qui ne sont pas nécessaires pour l'application mais peuvent être utilisés à des fins malveillantes
3. **Exécution en tant que root** : Le conteneur s'exécute avec les privilèges root au lieu d'un utilisateur non-privilégié
4. **Utilisateur créé mais non utilisé** : Un utilisateur `appuser` est créé mais jamais utilisé
5. **Pas de vérification d'intégrité** : Installation des dépendances Python sans vérification

### Prochaines étapes
- Scanner l'image avec Trivy ou Snyk pour identifier les vulnérabilités
- Créer un Dockerfile sécurisé en suivant les bonnes pratiques
- Documenter les améliorations apportées

