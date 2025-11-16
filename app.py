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

# Secret hardcodé (mauvaise pratique)
DATABASE_PASSWORD = "admin123"
API_KEY = "sk-1234567890abcdef"

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
    app.run(host='0.0.0.0', port=5000, debug=True)

