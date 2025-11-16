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

### Construction de l'image
L'image Docker a été construite avec succès :
```bash
docker build -t tp3-vulnerable-app:latest .
```

**Image créée** : `tp3-vulnerable-app:latest` (1.57 GB)
- Image ID : `ee92b8dca9c5`
- Taille importante due aux packages système inutiles installés

L'image contient maintenant toutes les vulnérabilités intentionnelles et est prête à être scannée avec Trivy ou Snyk.

## Étape 2 : Scan de Sécurité avec Trivy

### Installation de Trivy
Trivy a été installé via Homebrew :
```bash
brew install trivy
```

### Scan de l'image
Le scan de sécurité a été effectué avec la commande suivante :
```bash
trivy image tp3-vulnerable-app:latest --severity HIGH,CRITICAL
```

### Résultats du scan

Le scan a révélé un nombre important de vulnérabilités :

#### Vulnérabilités dans les packages système (Debian)
- **Total** : 931 vulnérabilités
- **CRITICAL** : 55
- **HIGH** : 876

**Exemples de vulnérabilités critiques identifiées** :
- `CVE-2023-45853` (CRITICAL) dans `zlib1g` : Integer overflow et heap-based buffer overflow
- Nombreuses vulnérabilités dans le kernel Linux (affectées ou fixes disponibles)
- Vulnérabilités dans les bibliothèques système (libc, openssl, etc.)

#### Vulnérabilités dans les dépendances Python
- **Total** : 6 vulnérabilités
- **CRITICAL** : 0
- **HIGH** : 6

**Vulnérabilités identifiées** :
1. **Flask 2.0.1** :
   - `CVE-2023-30861` (HIGH) : Possible disclosure of permanent session cookie due to missing Vary: Cookie header
   - **Fix** : Mettre à jour vers Flask 2.3.2 ou 2.2.5

2. **Werkzeug 2.0.1** :
   - `CVE-2023-25577` (HIGH) : High resource usage when parsing multipart form data with many fields
   - **Fix** : Mettre à jour vers Werkzeug 2.2.3
   - `CVE-2024-34069` (HIGH) : User may execute code on a developer's machine
   - **Fix** : Mettre à jour vers Werkzeug 3.0.3

3. **setuptools 57.5.0** :
   - `CVE-2022-40897` (HIGH) : Regular Expression Denial of Service (ReDoS) in package_index.py
   - **Fix** : Mettre à jour vers setuptools 65.5.1
   - `CVE-2024-6345` (HIGH) : Remote code execution via download functions
   - **Fix** : Mettre à jour vers setuptools 70.0.0
   - `CVE-2025-47273` (HIGH) : Path Traversal Vulnerability in setuptools PackageIndex
   - **Fix** : Mettre à jour vers setuptools 78.1.1

### Analyse des résultats

Le scan confirme que l'image contient effectivement de nombreuses vulnérabilités :

1. **Image de base vulnérable** : L'utilisation de `python:3.8` basée sur Debian 12.7 contient de nombreuses vulnérabilités système, notamment dans le kernel et les bibliothèques système.

2. **Dépendances Python obsolètes** : Les versions de Flask et Werkzeug utilisées sont anciennes et contiennent des vulnérabilités critiques de sécurité.

3. **Surface d'attaque importante** : L'installation de nombreux packages système inutiles augmente la surface d'attaque avec des vulnérabilités supplémentaires.

### Rapports générés
- Rapport JSON complet : `trivy-report.json`
- Résumé des vulnérabilités : `trivy-summary.json`

### Prochaines étapes
- Créer un Dockerfile sécurisé en suivant les bonnes pratiques
- Mettre à jour les dépendances Python vers des versions sécurisées
- Utiliser une image de base plus récente et minimale
- Documenter les améliorations apportées

