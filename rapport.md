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

## Étape 3 : Création d'un Dockerfile Sécurisé

### Objectif
Créer un Dockerfile sécurisé en appliquant les bonnes pratiques de sécurité identifiées lors du scan.

### Améliorations apportées

#### 1. Image de base minimale et récente
- **Avant** : `python:3.8` (Debian 12.7, 1.57 GB)
- **Après** : `python:3.12-slim` (Debian 13.2, 248 MB)
- **Bénéfice** : 
  - Image 6x plus petite (248 MB vs 1.57 GB)
  - Version Python plus récente (3.12 vs 3.8)
  - Distribution Debian plus récente avec moins de vulnérabilités
  - Image minimale avec seulement les packages essentiels

#### 2. Mise à jour des dépendances Python
- **Flask** : 2.0.1 → 3.0.3 (corrige CVE-2023-30861)
- **Werkzeug** : 2.0.1 → 3.0.3 (corrige CVE-2023-25577 et CVE-2024-34069)
- **Bénéfice** : Toutes les vulnérabilités HIGH dans les dépendances Python sont corrigées

#### 3. Exécution en tant qu'utilisateur non-root
- **Avant** : Conteneur exécuté en tant que root (UID 0)
- **Après** : Utilisateur dédié `appuser` (UID 1000) avec groupe dédié
- **Bénéfice** : En cas de compromission, l'attaquant n'a pas les privilèges root

#### 4. Suppression des packages système inutiles
- **Avant** : Installation de `nmap`, `netcat`, `telnet`, `vim`, `curl`, `wget`
- **Après** : Seulement `ca-certificates` pour la sécurité TLS
- **Bénéfice** : Réduction drastique de la surface d'attaque

#### 5. Mise à jour des packages système
- **Ajout** : `apt-get upgrade -y` pour appliquer les correctifs de sécurité
- **Bénéfice** : Les packages système sont à jour avec les derniers correctifs

#### 6. Healthcheck
- **Ajout** : Healthcheck configuré pour surveiller la santé du conteneur
- **Bénéfice** : Détection automatique des problèmes de santé

#### 7. Mode debug désactivé
- **Avant** : `debug=True` en dur dans le code
- **Après** : Contrôle via variable d'environnement `FLASK_DEBUG`
- **Bénéfice** : Pas d'exposition d'informations de débogage en production

#### 8. Optimisation des couches Docker
- **Avant** : Installation des packages et copie du code dans le désordre
- **Après** : Copie des `requirements.txt` d'abord pour optimiser le cache
- **Bénéfice** : Builds plus rapides lors des modifications de code

### Comparaison des images

| Critère | Image Vulnérable | Image Sécurisée | Amélioration |
|---------|------------------|-----------------|--------------|
| **Taille** | 1.57 GB | 248 MB | **84% de réduction** |
| **Vulnérabilités CRITICAL** | 55 | 0 | **100% corrigées** |
| **Vulnérabilités HIGH** | 882 | 0 | **100% corrigées** |
| **Total vulnérabilités** | 937 | 0 | **100% corrigées** |
| **Utilisateur** | root | appuser | **Sécurité renforcée** |
| **Packages système** | 453 | 87 | **81% de réduction** |
| **Python version** | 3.8 | 3.12 | **Version récente** |
| **Flask version** | 2.0.1 | 3.0.3 | **Vulnérabilités corrigées** |
| **Werkzeug version** | 2.0.1 | 3.0.3 | **Vulnérabilités corrigées** |

### Résultats du scan de l'image sécurisée

Le scan Trivy de l'image sécurisée montre :
- **0 vulnérabilité CRITICAL**
- **0 vulnérabilité HIGH**
- **0 vulnérabilité dans les packages système** (Debian 13.2)
- **0 vulnérabilité dans les dépendances Python**

### Bonnes pratiques appliquées

1. ✅ **Image de base minimale** : Utilisation de `-slim` pour réduire la taille
2. ✅ **Utilisateur non-root** : Exécution avec un utilisateur dédié
3. ✅ **Versions spécifiques** : Pas d'utilisation de `latest` implicite
4. ✅ **Mise à jour des packages** : `apt-get upgrade` pour les correctifs
5. ✅ **Suppression des outils inutiles** : Pas de packages système non nécessaires
6. ✅ **Healthcheck** : Surveillance de la santé du conteneur
7. ✅ **Optimisation du cache** : Ordre des instructions optimisé
8. ✅ **Dépendances à jour** : Versions récentes sans vulnérabilités connues
9. ✅ **Mode debug contrôlé** : Variable d'environnement au lieu de hardcodé
10. ✅ **Permissions correctes** : `chown` pour les fichiers de l'application

### Fichiers créés

- `Dockerfile.secure` : Dockerfile sécurisé avec toutes les bonnes pratiques
- `requirements.txt` : Mis à jour avec Flask 3.0.3 et Werkzeug 3.0.3
- `app.py` : Mode debug contrôlé par variable d'environnement

### Construction de l'image sécurisée

```bash
docker build -f Dockerfile.secure -t tp3-secure-app:latest .
```

**Image créée** : `tp3-secure-app:latest` (248 MB)
- Image ID : `e17197ae83b1`
- Taille réduite de 84% par rapport à l'image vulnérable
- Aucune vulnérabilité HIGH ou CRITICAL détectée

### Rapports générés pour l'image sécurisée
- Rapport JSON complet : `trivy-secure-report.json`
- Résumé des vulnérabilités : `trivy-secure-summary.json`

**Résumé du scan** :
- Packages système (Debian) : 0 vulnérabilité (CRITICAL: 0, HIGH: 0)
- Dépendances Python : 0 vulnérabilité (CRITICAL: 0, HIGH: 0)
- **Total : 0 vulnérabilité HIGH ou CRITICAL**

### Prochaines étapes
- Mettre en place la gestion des secrets avec Kubernetes Secrets ou Vault
- Déployer un outil de monitoring au runtime (Falco)
- Documenter la gestion des secrets

