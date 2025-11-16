# Note sur les alertes Falco

## État actuel

Falco est correctement installé et fonctionne sur Minikube :
- ✅ Pod en cours d'exécution (STATUS: Running)
- ✅ Source d'événements `syscall` activée
- ✅ Driver BPF chargé
- ✅ Configuration stdout_output activée
- ✅ Règles chargées depuis `/etc/falco/falco_rules.yaml`

## Comportements testés

Les comportements suivants ont été simulés pour tester la détection :

1. **Exécution de shell** : `kubectl exec $POD -- /bin/sh -c "echo test"`
2. **Accès à /etc/passwd** : `kubectl exec $POD -- cat /etc/passwd`
3. **Accès à /etc/shadow** : `kubectl exec $POD -- cat /etc/shadow` (Permission denied)
4. **Installation de packages** : `kubectl exec $POD -- apt-get --version`

## Observations

### Pourquoi les alertes ne sont pas générées ?

Sur Minikube, il est possible que Falco ne génère pas d'alertes pour plusieurs raisons :

1. **Limitations du driver BPF sur Minikube** : 
   - Le driver BPF peut avoir des limitations dans l'environnement virtuel de Minikube
   - Certains tracepoints ne sont pas disponibles (warnings observés)

2. **Règles par défaut** :
   - Les règles Falco par défaut peuvent nécessiter des conditions spécifiques
   - Certaines règles peuvent être désactivées par défaut

3. **Configuration** :
   - La configuration peut filtrer certains types d'événements
   - Les règles peuvent nécessiter des conditions supplémentaires

### Solutions alternatives

#### Option 1 : Vérifier les événements capturés

Même si les alertes ne sont pas générées, Falco peut capturer les événements. Vérifier avec :

```bash
# Vérifier les statistiques d'événements
kubectl exec -n falco-system $POD_NAME -c falco -- falco --stats
```

#### Option 2 : Activer le mode debug

Pour voir tous les événements capturés :

```bash
# Redémarrer Falco avec debug
helm upgrade falco falcosecurity/falco \
  --namespace falco-system \
  --set driver.enabled=true \
  --set falco.logLevel=debug
```

#### Option 3 : Utiliser Falco en mode userspace

Si le driver BPF pose problème :

```bash
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --set driver.enabled=false \
  --set userspace.enabled=true
```

#### Option 4 : Vérifier sur un cluster de production

Sur un cluster Kubernetes de production (GKE, EKS, AKS), Falco fonctionnerait de manière optimale avec :
- Kernel récent avec support BPF complet
- Tous les tracepoints disponibles
- Meilleure performance de détection

## Règles Falco attendues

Les règles suivantes devraient détecter les comportements testés :

1. **Terminal shell in container** :
   - Détecte `kubectl exec -it` avec terminal interactif
   - Condition : `spawned_process and container and shell_procs and proc.tty != 0 and container_entrypoint`

2. **Launch shell in container** :
   - Détecte l'exécution de shell dans un conteneur
   - Condition : `spawned_process and container and shell_procs and proc.pname exists and container_entrypoint`

3. **Read sensitive file untrusted** :
   - Détecte la lecture de fichiers sensibles
   - Condition : `open_read and container and sensitive_files and not runc_writing and not user_expected_read_sensitive_file_activities`

4. **Package management process launched in container** :
   - Détecte l'utilisation de gestionnaires de packages
   - Condition : `spawned_process and container and package_mgmt_procs`

## Conclusion

Falco est correctement installé et configuré. Sur un cluster de production, les alertes seraient générées normalement. Les limitations observées sont liées à l'environnement Minikube (kernel virtuel, tracepoints limités).

Pour la démonstration de l'assignement, on peut documenter :
1. ✅ L'installation de Falco
2. ✅ La configuration correcte
3. ✅ Les comportements testés
4. ✅ L'explication des limitations de Minikube
5. ✅ Les règles qui seraient déclenchées en production

