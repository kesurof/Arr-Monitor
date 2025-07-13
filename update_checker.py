#!/usr/bin/env python3
"""
Update Checker - Vérification automatique des mises à jour GitHub
"""

import requests
import json
import logging
from packaging import version
import sys
from pathlib import Path

class UpdateChecker:
    def __init__(self, repo="kesurof/Arr-Monitor", current_version="1.0.0"):
        self.repo = repo
        self.current_version = current_version
        self.api_url = f"https://api.github.com/repos/{repo}/releases/latest"
        self.logger = logging.getLogger(__name__)
        
    def get_latest_release(self):
        """Récupère les informations de la dernière release GitHub"""
        try:
            response = requests.get(self.api_url, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                self.logger.info("ℹ️  Aucune release disponible sur GitHub pour le moment")
                return None
            else:
                self.logger.error(f"❌ Erreur HTTP lors de la vérification des mises à jour : {e}")
                return None
        except requests.exceptions.RequestException as e:
            self.logger.error(f"❌ Erreur réseau lors de la vérification des mises à jour : {e}")
            return None
    
    def check_for_updates(self):
        """Vérifie s'il y a une nouvelle version disponible"""
        latest_release = self.get_latest_release()
        if not latest_release:
            # Pas d'erreur, juste pas de release disponible
            return None, None, None
            
        latest_version = latest_release.get('tag_name', '').lstrip('v')
        release_notes = latest_release.get('body', '')
        download_url = latest_release.get('html_url', '')
        
        try:
            if version.parse(latest_version) > version.parse(self.current_version):
                return latest_version, release_notes, download_url
            else:
                return None, None, None
        except Exception as e:
            self.logger.error(f"❌ Erreur comparaison versions : {e}")
            return None, None, None
    
    def save_version_info(self, version_file=".version"):
        """Sauvegarde la version actuelle"""
        try:
            with open(version_file, 'w') as f:
                f.write(self.current_version)
        except Exception as e:
            self.logger.error(f"❌ Erreur sauvegarde version : {e}")
    
    def load_version_info(self, version_file=".version"):
        """Charge la version depuis le fichier"""
        try:
            if Path(version_file).exists():
                with open(version_file, 'r') as f:
                    return f.read().strip()
            return "1.0.0"  # Version par défaut
        except Exception:
            return "1.0.0"

def main():
    """Test du vérificateur de mises à jour"""
    checker = UpdateChecker()
    
    print("🔍 Vérification des mises à jour...")
    latest_version, notes, url = checker.check_for_updates()
    
    if latest_version:
        print(f"🆕 Nouvelle version disponible : v{latest_version}")
        print(f"📋 Notes de version :\n{notes}")
        print(f"🔗 Télécharger : {url}")
    else:
        print("✅ Vous avez la dernière version (ou aucune release GitHub disponible)")

if __name__ == "__main__":
    main()
