# TP 3 : Sécurité des Conteneurs et Monitoring en Runtime

## Construction de l'image Docker vulnérable

Pour construire l'image Docker avec des vulnérabilités intentionnelles :

```bash
docker build -t tp3-vulnerable-app:latest .
```

## Exécution du conteneur

```bash
docker run -p 5000:5000 tp3-vulnerable-app:latest
```

L'application sera accessible sur http://localhost:5000

## Endpoints disponibles

- `GET /` - Page d'accueil
- `GET /health` - Vérification de santé
- `GET /info` - Expose des informations sensibles (vulnérable)
- `GET /env` - Expose les variables d'environnement (vulnérable)
- `POST /execute` - Exécute des commandes système (très vulnérable)

## Prochaines étapes

1. Scanner l'image avec Trivy : `trivy image tp3-vulnerable-app:latest`
2. Identifier les vulnérabilités
3. Créer un Dockerfile sécurisé
4. Mettre en place la gestion des secrets
5. Déployer un outil de monitoring (Falco)

