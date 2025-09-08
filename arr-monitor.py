#!/usr/bin/env python3
"""
Arr Monitor - Surveillance automatique des erreurs Sonarr/Radarr
Détecte et corrige automatiquement les téléchargements échoués ou bloqués
Version: Définie dans .version - Optimisé pour ARM64
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
        self.config_path = config_path  # NOUVELLE LIGNE: stocker le chemin
        self.config = self.load_config(config_path)
        self.setup_logging()
        self.session = requests.Session()
        self.version = self._read_version_file()
        self.anonymize_enabled = self.config.get('privacy', {}).get('anonymize_logs', True)

        # Optimisations ARM64
        if platform.machine() in ['aarch64', 'arm64']:
            self.setup_arm64_optimizations()
        
        # Vérification des mises à jour au démarrage
        self.check_for_updates_async()
        
    def _read_version_file(self):
        """Lit la version depuis le fichier .version"""
        try:
            version_file = Path(__file__).parent / '.version'
            if version_file.exists():
                version = version_file.read_text().strip()
                return version
        except Exception:
            pass
        return "1.1.4"  # Fallback
        
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
    
    def call_refresh_config(self):
        """Appelle la fonction refresh_config d'arr-launcher.sh en mode non-interactif"""
        try:
            import subprocess
            script_dir = Path(__file__).parent
            launcher_script = script_dir / "arr-launcher.sh"
            
            if launcher_script.exists():
                self.logger.info("🔄 Appel de la fonction refresh_config...")
                
                # Préparer l'environnement avec mode automatique
                env = os.environ.copy()
                env["REFRESH_AUTOMATIC"] = "true"  # MODE NON-INTERACTIF
                
                # Appeler la fonction refresh_config du script arr-launcher.sh
                result = subprocess.run([
                    "bash", "-c", 
                    f"source {launcher_script} && refresh_config"
                ], capture_output=True, text=True, timeout=60, env=env)  # Timeout augmenté à 60s
                
                if result.returncode == 0:
                    self.logger.info("✅ Refresh config terminé avec succès")
                    # Recharger la configuration mise à jour
                    self.config = self.load_config(self.config_path)
                    return True
                else:
                    self.logger.warning(f"⚠️ Refresh config a échoué : {result.stderr}")
                    return False
            else:
                self.logger.warning("⚠️ Script arr-launcher.sh non trouvé")
                return False
                
        except subprocess.TimeoutExpired:
            self.logger.error("❌ Timeout lors du refresh config (>60s)")
            return False
        except Exception as e:
            self.logger.error(f"❌ Erreur lors du refresh config : {e}")
            return False

    def get_queue(self, app_name, url, api_key):
        """Récupère la queue des téléchargements avec pagination complète"""
        try:
            headers = {'X-Api-Key': api_key, 'Content-Type': 'application/json'}
            all_items = []
            page = 1
            page_size = 50
            
            while True:
                # Utiliser la pagination pour récupérer tous les éléments
                params = {
                    'page': page, 
                    'pageSize': page_size,
                    'sortKey': 'timeleft',
                    'sortDirection': 'ascending'
                }
                
                response = self.session.get(f"{url}/api/v3/queue", 
                                          headers=headers, 
                                          params=params, 
                                          timeout=15)
                
                if response.status_code == 200:
                    data = response.json()
                    
                    if isinstance(data, dict):
                        records = data.get('records', [])
                        total_records = data.get('totalRecords', 0)
                        
                        if not records:
                            break
                            
                        all_items.extend(records)
                        self.logger.debug(f"📄 {app_name} Page {page}: {len(records)} éléments (Total: {len(all_items)}/{total_records})")
                        
                        # Si on a récupéré tous les éléments
                        if len(all_items) >= total_records:
                            break
                            
                        page += 1
                    else:
                        # Format liste directe (fallback)
                        all_items = data
                        break
                else:
                    self.logger.error(f"❌ {app_name} erreur récupération queue page {page} : {response.status_code}")
                    break
                    
            self.logger.debug(f"📊 {app_name} Total récupéré: {len(all_items)} éléments")
            return all_items
            
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
        """Bloque la release défaillante et lance une nouvelle recherche"""
        try:
            headers = {'X-Api-Key': api_key, 'Content-Type': 'application/json'}
            
            # Étape 1: Supprimer avec blocklist (comme dans votre script)
            params = {
                'removeFromClient': 'true',
                'blocklist': 'true'
            }
            
            response = self.session.delete(f"{url}/api/v3/queue/{download_id}", 
                                         headers=headers, 
                                         params=params, 
                                         timeout=15)
            
            if response.status_code in [200, 204]:
                self.logger.info(f"🚫 {app_name} release {download_id} bloquée et supprimée")
                
                # Étape 2: Lancer une recherche de nouveaux téléchargements
                self.trigger_missing_search(app_name, url, api_key)
                
                return True
            else:
                self.logger.error(f"❌ {app_name} erreur blocklist {download_id} : {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            self.logger.error(f"❌ {app_name} erreur blocklist {download_id} : {e}")
            return False
    
    def trigger_missing_search(self, app_name, url, api_key):
        """Lance une recherche pour les éléments manqués"""
        try:
            headers = {'X-Api-Key': api_key, 'Content-Type': 'application/json'}
            
            # Commande différente selon l'application
            if app_name.lower() == 'radarr':
                search_command = {'name': 'MissingMoviesSearch'}
            elif app_name.lower() == 'sonarr':
                search_command = {'name': 'MissingEpisodeSearch'}
            else:
                search_command = {'name': 'MissingEpisodeSearch'}  # Fallback
            
            response = self.session.post(f"{url}/api/v3/command", 
                                       headers=headers, 
                                       json=search_command, 
                                       timeout=30)
            
            if response.status_code == 201:
                self.logger.info(f"🔍 {app_name} recherche de nouveaux téléchargements lancée")
                return True
            else:
                self.logger.warning(f"⚠️ {app_name} impossible de lancer la recherche automatique : {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            self.logger.warning(f"⚠️ {app_name} erreur lors du lancement de recherche : {e}")
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
        """Vérifie si un téléchargement a l'erreur qBittorrent spécifique UNIQUEMENT"""
        error_message = item.get('errorMessage', '')
        
        # DÉTECTION STRICTE : Seulement l'erreur qBittorrent spécifique
        is_qbittorrent_error = (
            error_message and "qBittorrent is reporting an error" in error_message
        )
        
        if is_qbittorrent_error:
            # Log pour confirmer la détection
            self.logger.debug(f"🎯 Erreur qBittorrent détectée - Error: {error_message}")
        
        return is_qbittorrent_error
    
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
        
        # Statistiques des statuts pour diagnostic
        status_count = {}
        for item in queue:
            status = item.get('status', 'unknown').lower()
            status_count[status] = status_count.get(status, 0) + 1
        
        self.logger.debug(f"📊 {app_name} Statuts: {dict(sorted(status_count.items()))}")
        
        actions_config = self.config.get('actions', {})
        processed_items = 0
        
        for item in queue:
            item_id = item.get('id')
            title = item.get('title', item.get('movieTitle', 'Unknown'))
            status = item.get('status', 'unknown')
            error_message = item.get('errorMessage', '')
            
            # Vérification des erreurs avec détection élargie
            if self.is_download_failed(item):
                self.logger.warning(f"❌ {app_name} erreur détectée : {title}")
                self.logger.warning(f"   📊 Status: {status}")
                if error_message:
                    # Anonymiser le message d'erreur s'il contient des infos sensibles
                    safe_error = self.anonymize_sensitive_data(error_message)
                    self.logger.warning(f"   🚨 Erreur: {safe_error}")
                
                if actions_config.get('auto_retry', True):
                    self.logger.info(f"🔄 {app_name} traitement de l'erreur pour: {title}")
                    if self.blocklist_and_search(app_name, url, api_key, item_id):
                        processed_items += 1
                        # Délai plus long pour éviter la surcharge de l'API
                        time.sleep(2)
                    else:
                        self.logger.error(f"❌ {app_name} échec du traitement pour: {title}")
        
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
        """Exécute la surveillance en continu avec refresh automatique des IPs et clés API"""
        check_interval = self.config.get('monitoring', {}).get('check_interval', 300)
        self.logger.info(f"🔄 Démarrage surveillance continue (intervalle: {check_interval}s)")

        try:
            while True:
                # ÉTAPE 1: APPELER LA FONCTION REFRESH EXISTANTE D'ARR-LAUNCHER
                self.logger.info("🌐 Réactualisation automatique des IPs et clés API...")
                refresh_success = self.call_refresh_config()
                
                if refresh_success:
                    # Mettre à jour l'intervalle potentiellement modifié
                    check_interval = self.config.get('monitoring', {}).get('check_interval', 300)
                
                # ÉTAPE 2: EXÉCUTER LE CYCLE AVEC LA CONFIGURATION MISE À JOUR
                self.run_cycle()

                # ÉTAPE 3: PAUSE AVANT LE PROCHAIN CYCLE
                self.logger.info(f"⏰ Attente {check_interval} secondes...")
                time.sleep(check_interval)
                
        except KeyboardInterrupt:
            self.logger.info("🛑 Arrêt demandé par l'utilisateur")
        except Exception as e:
            self.logger.error(f"❌ Erreur fatale : {e}")
            sys.exit(1)
    
    def diagnose_queue(self, app_name, app_config):
        """Mode diagnostic pour analyser la queue en détail"""
        url = app_config.get('url')
        api_key = app_config.get('api_key')
        
        if not url or not api_key:
            self.logger.error(f"❌ {app_name} configuration incomplète pour diagnostic")
            return
        
        self.logger.info(f"🔬 DIAGNOSTIC {app_name}...")
        self.logger.info(f"📡 URL: {url}")
        self.logger.info(f"🔑 API Key: {api_key[:8]}***")
        
        # Test de connexion
        if not self.test_connection(app_name, url, api_key):
            return
        
        # Récupération de la queue
        queue = self.get_queue(app_name, url, api_key)
        if not queue:
            self.logger.info(f"📭 {app_name} queue vide")
            return
        
        self.logger.info(f"📊 {app_name} DIAGNOSTIC COMPLET:")
        self.logger.info(f"📋 Total éléments: {len(queue)}")
        
        # Analyse des statuts
        status_count = {}
        error_items = []
        
        for item in queue:
            status = item.get('status', 'unknown').lower()
            status_count[status] = status_count.get(status, 0) + 1
            
            if self.is_download_failed(item):
                error_items.append(item)
        
        # Affichage des statistiques
        self.logger.info("📊 STATUTS COMPLETS:")
        for status, count in sorted(status_count.items()):
            self.logger.info(f"   {status}: {count}")
        
        self.logger.info(f"🚨 ERREURS DÉTECTÉES: {len(error_items)}")
        
        if error_items:
            self.logger.info("📋 Détail des erreurs:")
            for i, error in enumerate(error_items[:5], 1):  # Limiter à 5 pour l'affichage
                title = error.get('title', error.get('movieTitle', 'Titre inconnu'))
                status = error.get('status', 'N/A')
                error_msg = error.get('errorMessage', '')
                tracked_status = error.get('trackedDownloadStatus', '')
                tracked_state = error.get('trackedDownloadState', '')
                
                self.logger.info(f"   {i}. {title}")
                self.logger.info(f"      Status: {status}")
                if error_msg:
                    safe_error = self.anonymize_sensitive_data(error_msg)
                    self.logger.info(f"      Erreur: {safe_error}")
                if tracked_status:
                    self.logger.info(f"      Tracked Status: {tracked_status}")
                if tracked_state:
                    self.logger.info(f"      Tracked State: {tracked_state}")
                self.logger.info("")
            
            if len(error_items) > 5:
                self.logger.info(f"   ... et {len(error_items) - 5} autres erreurs")
        
        return len(error_items)

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
    parser.add_argument('--diagnose', action='store_true', 
                       help='Mode diagnostic complet de la queue')
    
    args = parser.parse_args()
    
    # Mode debug
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        monitor = ArrMonitor(args.config)
        
        if args.diagnose:
            # Mode diagnostic spécial
            monitor.logger.info("🔬 MODE DIAGNOSTIC ACTIVÉ")
            applications = monitor.config.get('applications', {})
            
            total_errors = 0
            for app_name, app_config in applications.items():
                if app_config.get('enabled', False):
                    errors = monitor.diagnose_queue(app_name, app_config)
                    if errors:
                        total_errors += errors
            
            monitor.logger.info(f"🎯 DIAGNOSTIC TERMINÉ - Total erreurs trouvées: {total_errors}")
            
        elif args.dry_run:
            monitor.logger.info("🧪 Mode simulation activé - aucune action ne sera effectuée")
            # TODO: Implémenter le mode dry-run complet
            
        elif args.test:
            monitor.run_cycle()
        else:
            monitor.run_continuous()
            
    except Exception as e:
        print(f"❌ Erreur fatale : {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
