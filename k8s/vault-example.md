# Intégration avec HashiCorp Vault

## Vue d'ensemble

HashiCorp Vault est une solution avancée de gestion de secrets qui offre :
- Chiffrement des secrets
- Rotation automatique
- Audit complet
- Intégration avec Kubernetes via Vault Agent Injector

## Installation de Vault (exemple avec Minikube)

### 1. Installer Vault via Helm

```bash
# Ajouter le repo Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Installer Vault
helm install vault hashicorp/vault --set "server.dev.enabled=true"
```

### 2. Installer Vault Agent Injector

```bash
helm install vault-agent-injector hashicorp/vault-agent-injector
```

## Configuration Vault

### 1. Créer un secret dans Vault

```bash
# Accéder au pod Vault
kubectl exec -it vault-0 -- /bin/sh

# Dans le pod Vault
vault kv put secret/app-secrets \
  DATABASE_PASSWORD="SecurePassword123!" \
  API_KEY="sk-secure-api-key-abcdef123456"
```

### 2. Créer une politique Vault

```bash
vault policy write app-policy - <<EOF
path "secret/data/app-secrets" {
  capabilities = ["read"]
}
EOF
```

### 3. Configurer l'authentification Kubernetes

```bash
vault auth enable kubernetes

vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

vault write auth/kubernetes/role/app \
  bound_service_account_names=app-sa \
  bound_service_account_namespaces=default \
  policies=app-policy \
  ttl=1h
```

## Déploiement avec Vault Agent Injector

### 1. Créer un ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: default
```

### 2. Modifier le Deployment pour utiliser Vault

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tp3-secure-app-vault
  namespace: default
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "app"
    vault.hashicorp.com/agent-inject-secret-app-secrets: "secret/data/app-secrets"
    vault.hashicorp.com/agent-inject-template-app-secrets: |
      {{- with secret "secret/data/app-secrets" -}}
      export DATABASE_PASSWORD="{{ .Data.data.DATABASE_PASSWORD }}"
      export API_KEY="{{ .Data.data.API_KEY }}"
      {{- end }}
spec:
  serviceAccountName: app-sa
  containers:
  - name: app
    image: tp3-secure-app:latest
    # Les secrets seront injectés automatiquement par Vault Agent
    # comme variables d'environnement dans un fichier /vault/secrets/app-secrets
```

## Avantages de Vault vs Kubernetes Secrets

| Fonctionnalité | Kubernetes Secrets | HashiCorp Vault |
|----------------|-------------------|-----------------|
| Chiffrement | Base64 (non chiffré) | Chiffrement AES-256 |
| Rotation | Manuelle | Automatique |
| Audit | Limité | Complet |
| Accès granulaire | RBAC Kubernetes | Politiques Vault |
| Révocation | Manuelle | Immédiate |
| Intégration | Native K8s | Via Agent Injector |

## Recommandation

Pour la production, utiliser Vault offre une sécurité supérieure, mais Kubernetes Secrets est suffisant pour la plupart des cas d'usage simples.

