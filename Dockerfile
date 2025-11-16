# Dockerfile avec des vulnérabilités intentionnelles
# Ce Dockerfile contient plusieurs mauvaises pratiques de sécurité

# Utilisation d'une image de base ancienne avec des vulnérabilités connues
FROM python:3.8

# Installation de packages système non nécessaires et potentiellement vulnérables
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    vim \
    netcat-openbsd \
    telnet \
    nmap \
    && rm -rf /var/lib/apt/lists/*

# Création d'un utilisateur mais on ne l'utilise pas (on reste root)
RUN useradd -m -u 1000 appuser

# Copie des fichiers de l'application
WORKDIR /app
COPY requirements.txt .
COPY app.py .

# Installation des dépendances Python (sans vérification de sécurité)
RUN pip install --no-cache-dir -r requirements.txt

# Exposition du port
EXPOSE 5000

# Exécution en tant que root (mauvaise pratique)
CMD ["python", "app.py"]

