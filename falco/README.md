# Déploiement de Falco pour la Surveillance au Runtime

## Vue d'ensemble

Falco est un outil de détection d'intrusion au runtime qui surveille les conteneurs et génère des alertes en cas de comportements suspects ou malveillants.

## Installation sur Minikube

### Méthode 1 : Via Helm (recommandé)

```bash
# Ajouter le repo Helm
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# Créer le namespace
kubectl create namespace falco-system

# Installer Falco avec eBPF (recommandé pour Minikube)
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --set driver.enabled=false \
  --set ebpf.enabled=true
```

### Méthode 2 : Via les manifests Kubernetes

```bash
kubectl apply -f https://raw.githubusercontent.com/falcosecurity/falco/master/deploy/falco.yaml
```

## Vérification de l'installation

```bash
# Vérifier que Falco est en cours d'exécution
kubectl get pods -n falco-system

# Vérifier les logs
kubectl logs -n falco-system -l app=falco
```

## Comportements détectés par Falco

Falco détecte automatiquement plusieurs types de comportements suspects :

### 1. Exécution de shell interactif dans un conteneur
**Règle** : `Launch shell in container`
**Priorité** : Warning
**Description** : Détecte l'exécution d'un shell interactif dans un conteneur en production

### 2. Exécution de commandes système
**Règle** : `Run shell untrusted`
**Priorité** : Warning
**Description** : Détecte l'exécution de commandes shell non approuvées

### 3. Accès à des fichiers sensibles
**Règle** : `Read sensitive file untrusted`
**Priorité** : Warning
**Description** : Détecte la lecture de fichiers sensibles comme `/etc/shadow`, `/etc/passwd`

### 4. Installation de packages
**Règle** : `Package management process launched in container`
**Priorité** : Notice
**Description** : Détecte l'utilisation de gestionnaires de packages dans un conteneur

### 5. Modification de fichiers système
**Règle** : `Write below binary dir`
**Priorité** : Warning
**Description** : Détecte l'écriture dans des répertoires système

## Simulation de comportements malveillants

### Test 1 : Shell interactif

```bash
# Récupérer le nom d'un pod
POD_NAME=$(kubectl get pods -l app=tp3-secure-app -o jsonpath='{.items[0].metadata.name}')

# Exécuter un shell interactif (comportement suspect)
kubectl exec -it $POD_NAME -- /bin/sh
```

**Alerte Falco attendue** :
```
Rule: Launch shell in container
Priority: Warning
Output: Shell spawned in container
```

### Test 2 : Commande système

```bash
kubectl exec $POD_NAME -- /bin/sh -c "whoami && id"
```

**Alerte Falco attendue** :
```
Rule: Run shell untrusted
Priority: Warning
Output: Shell spawned in container
```

### Test 3 : Accès à des fichiers sensibles

```bash
kubectl exec $POD_NAME -- /bin/sh -c "cat /etc/passwd"
```

**Alerte Falco attendue** :
```
Rule: Read sensitive file untrusted
Priority: Warning
Output: Sensitive file opened for reading
```

## Consultation des alertes

### Voir toutes les alertes

```bash
kubectl logs -n falco-system -l app=falco
```

### Filtrer les alertes par type

```bash
# Alertes de priorité Warning ou Critical
kubectl logs -n falco-system -l app=falco | grep -E "Warning|Critical"

# Alertes concernant les shells
kubectl logs -n falco-system -l app=falco | grep -i shell

# Alertes concernant les fichiers sensibles
kubectl logs -n falco-system -l app=falco | grep -i "sensitive\|shadow\|passwd"
```

### Format des alertes Falco

Les alertes Falco suivent ce format :
```
{
  "output": "Shell spawned in container",
  "priority": "Warning",
  "rule": "Launch shell in container",
  "time": "2025-11-16T14:50:49.930956Z",
  "output_fields": {
    "container.id": "...",
    "container.name": "tp3-secure-app",
    "evt.type": "execve",
    "proc.name": "sh"
  }
}
```

## Intégration avec Falcosidekick

Pour envoyer les alertes vers des systèmes externes (Slack, Kafka, etc.) :

```bash
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --set falcosidekick.enabled=true \
  --set falcosidekick.webui.enabled=true
```

## Personnalisation des règles

Les règles Falco peuvent être personnalisées en créant une ConfigMap :

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-rules
  namespace: falco-system
data:
  custom_rules.yaml: |
    - rule: Custom suspicious activity
      desc: Detect custom suspicious activity
      condition: evt.type = execve and proc.name = suspicious_command
      output: Suspicious command executed
      priority: Warning
```

## Dépannage

### Falco ne démarre pas

1. Vérifier les logs :
   ```bash
   kubectl logs -n falco-system -l app=falco
   ```

2. Vérifier les privilèges :
   ```bash
   kubectl describe pod -n falco-system -l app=falco
   ```

3. Sur Minikube, utiliser eBPF au lieu du driver kernel :
   ```bash
   helm install falco falcosecurity/falco \
     --namespace falco-system \
     --set driver.enabled=false \
     --set ebpf.enabled=true
   ```

### Pas d'alertes générées

1. Vérifier que Falco est en cours d'exécution
2. Vérifier que les règles sont chargées
3. Tester avec un comportement connu pour générer une alerte

## Références

- Documentation officielle : https://falco.org/docs/
- Règles Falco : https://github.com/falcosecurity/rules
- Helm Chart : https://github.com/falcosecurity/charts

