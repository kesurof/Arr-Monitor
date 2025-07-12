#!/usr/bin/env python3
"""
Arr Monitor - Surveillance automatique des erreurs Sonarr/Radarr
Détecte et corrige automatiquement les téléchargements échoués ou bloqués
Version: 1.0.0 - Optimisé pour ARM64
"""

import argparse
import logging
import time
import sys
import os
import re
import platform
from pathlib import Path
import yaml
import requests
from datetime import datetime, timedelta
import json

class ArrMonitor:
    def __init__(self, config_path="config/config.yaml"):
        self.config = self.load_config(config_path)
        self.setup_logging()
        self.session = requests.Session()
        self.version = "1.0.0"
        self.anonymize_enabled = self.config.get('privacy', {}).get('anonymize_logs', True)
        
        # Optimisations ARM64
        if platform.machine() in ['aarch64', 'arm64']:
            self.setup_arm64_optimizations()
        
        # Vérification des mises à jour au démarrage
        self.check_for_updates_async()
        
    def setup_arm64_optimizations(self):
        """Optimisations spécifiques pour ARM64"""
        # Timeout plus élevés pour ARM64
        self.session.timeout = 15
        
        # Headers optimisés pour ARM64
        self.session.headers.update({
            'User-Agent': f'Arr-Monitor/{self.version} (ARM64; Linux)'
        })
        
        self.logger.info("🔧 Optimisations ARM64 activées")
    
    def check_for_updates_async(self):
        """Vérifie les mises à jour GitHub en arrière-plan"""
        try:
            import subprocess
            import threading
            
            def check_updates():
                try:
                    # Utilise le script update_checker en subprocess
                    result = subprocess.run([
                        sys.executable, 
                        os.path.join(os.path.dirname(__file__), 'update_checker.py')
                    ], capture_output=True, text=True, timeout=10)
                    
                    if "Nouvelle version disponible" in result.stdout:
                        self.logger.info("🆕 Mise à jour disponible ! Lancez le menu pour plus d'infos.")
                except Exception:
                    pass  # Ignore les erreurs de vérification silencieusement
            
            # Lance la vérification en arrière-plan
            threading.Thread(target=check_updates, daemon=True).start()
            
        except Exception:
            pass  # Ignore les erreurs d'importation
    
    def anonymize_sensitive_data(self, data):
        """Anonymise les données sensibles dans les logs"""
        if not self.anonymize_enabled:
            return data
            
        if isinstance(data, str):
            # Anonymise les adresses IP
            data = re.sub(r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b', 'xxx.xxx.xxx.xxx', data)
            
            # Anonymise les noms d'utilisateur
            data = re.sub(r'/home/[^/\s]+', '/home/[USER]', data)
            
            # Anonymise les hostnames
            data = re.sub(r'@[a-zA-Z0-9.-]+', '@[HOSTNAME]', data)
            
            # Anonymise les API keys partiellement (garde les 4 premiers caractères)
            data = re.sub(r'([a-zA-Z0-9]{4})[a-zA-Z0-9]{20,}', r'\1***', data)
            
        return data
    
    def load_config(self, config_path):
        """Charge la configuration depuis le fichier YAML"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
            return config
        except FileNotFoundError:
            print(f"❌ Fichier de configuration non trouvé : {config_path}")
            sys.exit(1)
        except yaml.YAMLError as e:
            print(f"❌ Erreur dans la configuration YAML : {e}")
            sys.exit(1)
    
    def setup_logging(self):
        """Configure le système de logs"""
        log_config = self.config.get('logging', {})
        log_level = getattr(logging, log_config.get('level', 'INFO'))
        log_file = log_config.get('file', 'logs/arr-monitor.log')
        
        # Créer le répertoire des logs s'il n'existe pas
        Path(log_file).parent.mkdir(exist_ok=True)
        
        # Configuration du logging avec rotation
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file, encoding='utf-8'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def test_connection(self, app_name, url, api_key):
        """Test la connexion à l'API d'une application"""
        try:
            headers = {'X-Api-Key': api_key}
            response = self.session.get(f"{url}/api/v3/system/status", headers=headers, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                version = data.get('version', 'Unknown')
                self.logger.info(f"✅ {app_name} connecté (v{version})")
                return True
            else:
                self.logger.error(f"❌ {app_name} erreur HTTP {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            self.logger.error(f"❌ {app_name} connexion échouée : {e}")
            return False
    
    def get_queue(self, app_name, url, api_key):
        """Récupère la queue des téléchargements"""
        try:
            headers = {'X-Api-Key': api_key}
            response = self.session.get(f"{url}/api/v3/queue", headers=headers, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                # L'API peut retourner une liste directement ou un objet avec 'records'
                if isinstance(data, list):
                    return data
                elif isinstance(data, dict) and 'records' in data:
                    return data['records']
                else:
                    # Si c'est un autre format, on retourne une liste vide
                    self.logger.warning(f"⚠️  {app_name} format de queue inattendu : {type(data)}")
                    return []
            else:
                self.logger.error(f"❌ {app_name} erreur récupération queue : {response.status_code}")
                return []
                
        except requests.exceptions.RequestException as e:
            self.logger.error(f"❌ {app_name} erreur queue : {e}")
            return []
    
    def get_history(self, app_name, url, api_key, since_hours=24):
        """Récupère l'historique des téléchargements"""
        try:
            headers = {'X-Api-Key': api_key}
            since_date = datetime.now() - timedelta(hours=since_hours)
            params = {
                'since': since_date.isoformat(),
                'pageSize': 100
            }
            response = self.session.get(f"{url}/api/v3/history", headers=headers, params=params, timeout=10)
            
            if response.status_code == 200:
                return response.json().get('records', [])
            else:
                self.logger.error(f"❌ {app_name} erreur récupération historique : {response.status_code}")
                return []
                
        except requests.exceptions.RequestException as e:
            self.logger.error(f"❌ {app_name} erreur historique : {e}")
            return []
    
    def blocklist_and_search(self, app_name, url, api_key, download_id):
        """Bloque la release défaillante et recherche une nouvelle release"""
        try:
            headers = {'X-Api-Key': api_key}
            # Utilise l'endpoint pour bloquer et rechercher une nouvelle release
            data = {
                'removeFromClient': True,
                'blacklist': True,
                'skipRedownload': False
            }
            response = self.session.delete(f"{url}/api/v3/queue/{download_id}", 
                                         headers=headers, json=data, timeout=10)
            
            if response.status_code in [200, 204]:
                self.logger.info(f"� {app_name} release {download_id} bloquée et nouvelle recherche lancée")
                return True
            else:
                self.logger.error(f"❌ {app_name} erreur blocklist {download_id} : {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            self.logger.error(f"❌ {app_name} erreur blocklist {download_id} : {e}")
            return False
    
    def remove_download(self, app_name, url, api_key, download_id):
        """Supprime un téléchargement de la queue"""
        try:
            headers = {'X-Api-Key': api_key}
            response = self.session.delete(f"{url}/api/v3/queue/{download_id}", headers=headers, timeout=10)
            
            if response.status_code in [200, 204]:
                self.logger.info(f"🗑️  {app_name} téléchargement {download_id} supprimé")
                return True
            else:
                self.logger.error(f"❌ {app_name} erreur suppression {download_id} : {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            self.logger.error(f"❌ {app_name} erreur suppression {download_id} : {e}")
            return False
    
    def is_download_failed(self, item):
        """Vérifie si un téléchargement a l'erreur qBittorrent spécifique"""
        status = item.get('status', '').lower()
        error_message = item.get('errorMessage', '')
        
        # Détection spécifique de l'erreur qBittorrent
        if error_message and "qBittorrent is reporting an error" in error_message:
            return True
        
        return False
    
    def process_application(self, app_name, app_config):
        """Traite une application (Sonarr ou Radarr)"""
        if not app_config.get('enabled', False):
            self.logger.debug(f"⏭️  {app_name} désactivé")
            return
        
        url = app_config.get('url')
        api_key = app_config.get('api_key')
        
        if not url or not api_key or api_key == f"your_{app_name.lower()}_api_key":
            self.logger.warning(f"⚠️  {app_name} configuration incomplète")
            return
        
        self.logger.info(f"🔍 Analyse de {app_name}...")
        
        # Test de connexion
        if not self.test_connection(app_name, url, api_key):
            return
        
        # Récupération de la queue
        queue = self.get_queue(app_name, url, api_key)
        if not queue:
            self.logger.info(f"📭 {app_name} queue vide")
            return
        
        self.logger.info(f"📋 {app_name} {len(queue)} éléments en queue")
        
        actions_config = self.config.get('actions', {})
        processed_items = 0
        
        for item in queue:
            item_id = item.get('id')
            title = item.get('title', 'Unknown')
            
            # Vérification de l'erreur qBittorrent spécifique
            if self.is_download_failed(item):
                self.logger.warning(f"❌ {app_name} erreur qBittorrent détectée : {title}")
                
                if actions_config.get('auto_retry', True):
                    if self.blocklist_and_search(app_name, url, api_key, item_id):
                        processed_items += 1
                        time.sleep(1)  # Délai entre actions
        
        if processed_items > 0:
            self.logger.info(f"✅ {app_name} {processed_items} éléments traités")
        else:
            self.logger.info(f"✅ {app_name} aucun problème détecté")
    
    def run_cycle(self):
        """Exécute un cycle complet de surveillance"""
        self.logger.info("🚀 Début du cycle de surveillance")
        
        applications = self.config.get('applications', {})
        
        for app_name, app_config in applications.items():
            try:
                self.process_application(app_name, app_config)
            except Exception as e:
                self.logger.error(f"❌ Erreur traitement {app_name} : {e}")
        
        self.logger.info("✅ Cycle terminé")
    
    def run_continuous(self):
        """Exécute la surveillance en continu"""
        check_interval = self.config.get('monitoring', {}).get('check_interval', 300)
        
        self.logger.info(f"🔄 Démarrage surveillance continue (intervalle: {check_interval}s)")
        
        try:
            while True:
                self.run_cycle()
                self.logger.info(f"⏰ Attente {check_interval} secondes...")
                time.sleep(check_interval)
                
        except KeyboardInterrupt:
            self.logger.info("🛑 Arrêt demandé par l'utilisateur")
        except Exception as e:
            self.logger.error(f"❌ Erreur fatale : {e}")
            sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Arr Monitor - Surveillance Sonarr/Radarr")
    parser.add_argument('--config', '-c', default='config/config.yaml', 
                       help='Chemin du fichier de configuration')
    parser.add_argument('--test', '-t', action='store_true', 
                       help='Exécuter un seul cycle de test')
    parser.add_argument('--debug', '-d', action='store_true', 
                       help='Mode debug (logs verbeux)')
    parser.add_argument('--dry-run', '-n', action='store_true', 
                       help='Mode simulation (aucune action)')
    
    args = parser.parse_args()
    
    # Mode debug
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        monitor = ArrMonitor(args.config)
        
        if args.dry_run:
            monitor.logger.info("🧪 Mode simulation activé - aucune action ne sera effectuée")
            # TODO: Implémenter le mode dry-run
        
        if args.test:
            monitor.run_cycle()
        else:
            monitor.run_continuous()
            
    except Exception as e:
        print(f"❌ Erreur fatale : {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
