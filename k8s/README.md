# Déploiement Kubernetes avec Gestion des Secrets

## Prérequis

- Cluster Kubernetes (Minikube, Kind, ou cluster cloud)
- `kubectl` configuré et connecté au cluster
- Image Docker `tp3-secure-app:latest` disponible (localement ou dans un registry)

## Déploiement

### 1. Créer les secrets

```bash
kubectl apply -f secret.yaml
```

Vérifier que les secrets sont créés :
```bash
kubectl get secrets
kubectl describe secret app-secrets
```

**Note de sécurité** : Les secrets sont stockés en base64 dans etcd. Pour la production, utilisez :
- Encryption at rest pour etcd
- RBAC pour limiter l'accès aux secrets
- Vault ou autres solutions de gestion de secrets

### 2. Déployer l'application

```bash
kubectl apply -f deployment.yaml
```

Vérifier le déploiement :
```bash
kubectl get deployments
kubectl get pods
kubectl logs -l app=tp3-secure-app
```

### 3. Exposer le service

```bash
kubectl apply -f service.yaml
```

Vérifier le service :
```bash
kubectl get services
```

### 4. Accéder à l'application

#### Avec port-forward (pour test local)
```bash
kubectl port-forward service/tp3-secure-app 8080:80
```

Puis accéder à : http://localhost:8080

#### Avec Minikube
```bash
minikube service tp3-secure-app
```

### 5. Vérifier que les secrets sont utilisés

```bash
# Vérifier les variables d'environnement dans un pod
kubectl exec -it <pod-name> -- env | grep -E "DATABASE_PASSWORD|API_KEY"

# Note: Les valeurs ne seront pas affichées pour des raisons de sécurité
# mais on peut vérifier qu'elles sont définies
```

## Mise à jour des secrets

Pour mettre à jour un secret :

```bash
# Méthode 1 : Modifier le fichier secret.yaml et réappliquer
kubectl apply -f secret.yaml

# Méthode 2 : Mettre à jour directement
kubectl create secret generic app-secrets \
  --from-literal=DATABASE_PASSWORD='NewPassword123!' \
  --from-literal=API_KEY='sk-new-api-key' \
  --dry-run=client -o yaml | kubectl apply -f -

# Redémarrer les pods pour prendre en compte les nouveaux secrets
kubectl rollout restart deployment/tp3-secure-app
```

## Sécurité

### Bonnes pratiques appliquées

1. ✅ **Secrets dans Kubernetes Secrets** : Pas de secrets hardcodés dans le code
2. ✅ **Utilisateur non-root** : `runAsNonRoot: true` et `runAsUser: 1000`
3. ✅ **Limites de ressources** : CPU et mémoire limitées
4. ✅ **Health checks** : Liveness et readiness probes
5. ✅ **Variables d'environnement** : Secrets injectés via `secretKeyRef`

### Recommandations pour la production

1. **Encryption at rest** : Activer l'encryption pour etcd
2. **RBAC** : Limiter l'accès aux secrets avec des rôles Kubernetes
3. **Vault** : Utiliser HashiCorp Vault pour une gestion avancée des secrets
4. **Rotation des secrets** : Mettre en place une rotation automatique
5. **Audit** : Activer l'audit logging pour les accès aux secrets

## Nettoyage

Pour supprimer toutes les ressources :

```bash
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f secret.yaml
```

