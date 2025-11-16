#!/usr/bin/env python3
"""
Application web simple avec des vulnérabilités intentionnelles
pour le TP de sécurité des conteneurs
"""

import json
import os
import subprocess

from flask import Flask, jsonify, request

app = Flask(__name__)

# Secrets lus depuis les variables d'environnement (bonne pratique)
# Ces valeurs proviennent de Kubernetes Secrets ou Vault
DATABASE_PASSWORD = os.getenv('DATABASE_PASSWORD', '')
API_KEY = os.getenv('API_KEY', '')

# Vérification que les secrets sont présents
if not DATABASE_PASSWORD or not API_KEY:
    import sys
    print("ERREUR: Les secrets DATABASE_PASSWORD et API_KEY doivent être définis", file=sys.stderr)
    sys.exit(1)

@app.route('/')
def index():
    return jsonify({
        "message": "Application de démonstration pour TP Sécurité",
        "version": "1.0.0"
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/info')
def info():
    """Endpoint qui expose des informations sensibles"""
    return jsonify({
        "database_password": DATABASE_PASSWORD,
        "api_key": API_KEY,
        "user": os.getenv("USER", "root"),
        "working_directory": os.getcwd()
    })

@app.route('/execute', methods=['POST'])
def execute():
    """Endpoint vulnérable - exécution de commandes système"""
    command = request.json.get('command', '')
    if command:
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=5
            )
            return jsonify({
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode
            })
        except Exception as e:
            return jsonify({"error": str(e)}), 500
    return jsonify({"error": "No command provided"}), 400

@app.route('/env')
def env():
    """Endpoint qui expose les variables d'environnement"""
    return jsonify(dict(os.environ))

if __name__ == '__main__':
    # Mode debug désactivé en production (bonne pratique)
    # Utiliser une variable d'environnement pour contrôler le mode debug
    debug_mode = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=5000, debug=debug_mode)

