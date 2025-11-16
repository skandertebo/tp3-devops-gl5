#!/bin/bash
# Script pour tester la détection Falco en simulant des comportements malveillants

echo "=== Test de détection Falco ==="
echo ""
echo "Ce script simule des comportements malveillants qui devraient être détectés par Falco"
echo ""

# Récupérer le nom d'un pod de l'application
POD_NAME=$(kubectl get pods -l app=tp3-secure-app -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "ERREUR: Aucun pod de l'application trouvé"
    exit 1
fi

echo "Pod utilisé: $POD_NAME"
echo ""

# Test 1: Exécution d'un shell interactif (comportement malveillant)
echo "=== Test 1: Exécution d'un shell interactif dans un conteneur ==="
echo "Cette action devrait générer une alerte Falco:"
echo "  - Rule: 'Launch shell in container'"
echo "  - Priority: Warning"
echo ""
kubectl exec -it $POD_NAME -- /bin/sh -c "echo 'Shell interactif exécuté'" 2>&1 | head -5
echo ""

# Test 2: Exécution de commandes système sensibles
echo "=== Test 2: Exécution de commandes système sensibles ==="
echo "Cette action devrait générer une alerte Falco:"
echo "  - Rule: 'Run shell untrusted'"
echo "  - Priority: Warning"
echo ""
kubectl exec $POD_NAME -- /bin/sh -c "whoami && id" 2>&1
echo ""

# Test 3: Accès à des fichiers sensibles
echo "=== Test 3: Tentative d'accès à /etc/shadow ==="
echo "Cette action devrait générer une alerte Falco:"
echo "  - Rule: 'Read sensitive file untrusted'"
echo "  - Priority: Warning"
echo ""
kubectl exec $POD_NAME -- /bin/sh -c "cat /etc/passwd 2>&1 | head -3" 2>&1
echo ""

# Test 4: Installation de packages
echo "=== Test 4: Tentative d'installation de packages ==="
echo "Cette action devrait générer une alerte Falco:"
echo "  - Rule: 'Package management process launched in container'"
echo "  - Priority: Notice"
echo ""
kubectl exec $POD_NAME -- /bin/sh -c "which apt-get || which yum || echo 'Package manager non disponible'" 2>&1
echo ""

echo "=== Vérification des alertes Falco ==="
echo "Pour voir les alertes générées, exécutez:"
echo "  kubectl logs -n falco-system -l app=falco | grep -i 'shell\|sensitive\|package'"
echo ""
echo "Ou pour voir toutes les alertes:"
echo "  kubectl logs -n falco-system -l app=falco --tail=100"

