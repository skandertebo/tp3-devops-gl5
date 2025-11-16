# Troubleshooting Falco sur Minikube

## Problème : CrashLoopBackOff

### Cause identifiée

L'erreur principale était :
```
Error: Must enable at least one event source
```

### Solution appliquée

Falco nécessite qu'au moins une source d'événements soit activée. La configuration initiale avec `ebpf.enabled=true` et `driver.enabled=false` ne fonctionnait pas correctement.

**Configuration corrigée** :
```bash
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --set driver.enabled=true \
  --set driver.loader.enabled=true \
  --set driver.loader.initContainer.enabled=true
```

### État actuel

Après la correction :
- ✅ Falco démarre correctement
- ✅ Les deux containers sont prêts (falco + falcoctl-artifact-follow)
- ✅ La source d'événements `syscall` est activée
- ✅ Le webserver de santé écoute sur le port 8765

### Warnings observés

Des warnings apparaissent concernant certains tracepoints :
```
libbpf: failed to determine tracepoint 'syscalls/sys_enter_creat' perf event ID
libbpf: failed to determine tracepoint 'syscalls/sys_enter_open' perf event ID
```

**Impact** : Ces warnings n'empêchent pas Falco de fonctionner. Ils indiquent que certains tracepoints spécifiques ne sont pas disponibles sur cette version de kernel, mais la détection continue de fonctionner.

### Vérification du fonctionnement

Pour vérifier que Falco fonctionne :

```bash
# Vérifier l'état des pods
kubectl get pods -n falco-system

# Vérifier les logs
kubectl logs -n falco-system -l app=falco -c falco

# Vérifier que la source syscall est activée
kubectl logs -n falco-system -l app=falco -c falco | grep "Enabled event sources"
```

### Génération d'alertes

Pour générer des alertes et tester Falco :

```bash
# Exécuter un shell dans un conteneur (comportement suspect)
APP_POD=$(kubectl get pods -l app=tp3-secure-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $APP_POD -- /bin/sh -c "echo 'test'"

# Vérifier les alertes
kubectl logs -n falco-system -l app=falco -c falco --tail=50 | grep -i "shell\|warning\|alert"
```

### Notes importantes

1. **Sur Minikube** : Falco peut avoir des limitations dues à l'environnement virtuel
2. **Kernel requirements** : Certaines fonctionnalités nécessitent un kernel récent
3. **Performance** : Sur un cluster de production, Falco fonctionnerait de manière optimale

### Alternative : Falco en mode userspace

Si le driver kernel continue à poser problème, on peut utiliser Falco en mode userspace (moins performant mais plus compatible) :

```bash
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --set driver.enabled=false \
  --set userspace.enabled=true
```

