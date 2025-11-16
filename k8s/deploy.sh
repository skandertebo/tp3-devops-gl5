#!/bin/bash
# Script de déploiement pour l'application avec gestion des secrets

set -e

echo "=== Déploiement de l'application avec gestion des secrets ==="

# Vérifier que kubectl est disponible
if ! command -v kubectl &> /dev/null; then
    echo "ERREUR: kubectl n'est pas installé"
    exit 1
fi

# Vérifier la connexion au cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "ERREUR: Impossible de se connecter au cluster Kubernetes"
    echo "Assurez-vous qu'un cluster est disponible (Minikube, Kind, etc.)"
    exit 1
fi

echo "✓ Cluster Kubernetes détecté"

# 1. Créer les secrets
echo ""
echo "1. Création des secrets Kubernetes..."
kubectl apply -f secret.yaml
echo "✓ Secrets créés"

# Vérifier les secrets
echo ""
echo "Secrets créés :"
kubectl get secrets | grep app-secrets

# 2. Déployer l'application
echo ""
echo "2. Déploiement de l'application..."
kubectl apply -f deployment.yaml
echo "✓ Déploiement créé"

# Attendre que les pods soient prêts
echo ""
echo "Attente du démarrage des pods..."
kubectl wait --for=condition=ready pod -l app=tp3-secure-app --timeout=120s || true

# Afficher les pods
echo ""
echo "État des pods :"
kubectl get pods -l app=tp3-secure-app

# 3. Créer le service
echo ""
echo "3. Création du service..."
kubectl apply -f service.yaml
echo "✓ Service créé"

# Afficher le service
echo ""
echo "Service créé :"
kubectl get service tp3-secure-app

# 4. Vérifier que les secrets sont utilisés
echo ""
echo "4. Vérification de l'utilisation des secrets..."
POD_NAME=$(kubectl get pods -l app=tp3-secure-app -o jsonpath='{.items[0].metadata.name}')
if [ -n "$POD_NAME" ]; then
    echo "Pod: $POD_NAME"
    echo "Variables d'environnement contenant 'PASSWORD' ou 'KEY':"
    kubectl exec $POD_NAME -- env | grep -E "DATABASE_PASSWORD|API_KEY" || echo "  (Les valeurs ne sont pas affichées pour des raisons de sécurité)"
    
    echo ""
    echo "Vérification que l'application démarre correctement..."
    kubectl logs $POD_NAME --tail=20
fi

echo ""
echo "=== Déploiement terminé ==="
echo ""
echo "Pour accéder à l'application :"
echo "  kubectl port-forward service/tp3-secure-app 8080:80"
echo "  Puis ouvrir http://localhost:8080"
echo ""
echo "Pour supprimer le déploiement :"
echo "  kubectl delete -f service.yaml -f deployment.yaml -f secret.yaml"

