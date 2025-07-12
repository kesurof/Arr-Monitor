# 🔄 Arr Monitor - Surveillance Sonarr/Radarr

[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/kesurof/Arr-Monitor)
[![Python](https://img.shields.io/badge/python-3.8+-green.svg)](https://python.org)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-supported-blue.svg)](https://docker.com)

## 📝 Description

**Arr Monitor** est un outil de surveillance et de gestion automatique des erreurs pour **Sonarr** et **Radarr**. Il surveille les files d'attente, détecte les téléchargements en erreur ou bloqués, et peut automatiquement relancer ou supprimer les éléments problématiques.

### 🎯 **Nouveautés v2.0**
- ✅ **Détection automatique** des conteneurs Docker
- ✅ **Extraction automatique** des clés API
- ✅ **Support environnements virtuels** existants
- ✅ **Installation zéro-configuration** 
- ✅ **Service systemd** intégré
- ✅ **Script de désinstallation** complet

## ✨ Fonctionnalités

### 🔍 **Surveillance Intelligente**
- 📊 **Surveillance temps réel** des files d'attente Sonarr/Radarr
- 🔍 **Détection avancée** des erreurs de téléchargement
- 🎯 **Identification** des téléchargements bloqués
- 📈 **Métriques détaillées** et historique

### ⚡ **Actions Automatiques**
- 🔄 **Relance automatique** des téléchargements en erreur
- 🗑️ **Suppression intelligente** des éléments bloqués
- ⏰ **Seuils configurables** pour chaque action
- �️ **Modes de fonctionnement** : auto, semi-auto, manuel

### 🐳 **Intégration Docker**
- 🔍 **Détection automatique** des conteneurs Sonarr/Radarr
- 🌐 **Support multi-réseaux** : traefik_proxy, bridge, custom
- 🔑 **Extraction automatique** des clés API depuis les configs
- 📁 **Support SETTINGS_STORAGE** pour infrastructures personnalisées

### 🔧 **Installation & Maintenance**
- 🚀 **Installation en une ligne** 
- � **Gestion intelligente** des environnements Python
- 🔗 **Réutilisation venv existants** (seedbox-compose compatible)
- �️ **Service systemd** intégré avec auto-configuration
- 📦 **Script de désinstallation** complet

### 📱 **Notifications & Monitoring**
- 📧 **Notifications email** personnalisables  
- 🔔 **Webhooks** pour intégrations externes
- 📊 **Logs structurés** avec niveaux configurables
- 🐛 **Mode debug** avancé pour diagnostic

## 🚀 Installation

### **Installation Automatique (Recommandée)**

```bash
# Installation en une ligne
curl -sL https://raw.githubusercontent.com/kesurof/Arr-Monitor/main/install-arr.sh | bash
```

### **Installation Manuelle**

```bash
# 1. Cloner le projet
git clone https://github.com/kesurof/Arr-Monitor.git
cd Arr-Monitor

# 2. Lancer l'installation interactive
chmod +x install-arr.sh
./install-arr.sh
```

### **Mise à jour**

```bash
# Mise à jour automatique (préserve la configuration)
curl -sL https://raw.githubusercontent.com/kesurof/Arr-Monitor/main/install-arr.sh | bash -s -- --update
```

### **🎯 Détection Automatique**

L'installation détecte automatiquement :
- 🐳 **Conteneurs Docker** Sonarr/Radarr (via IP/ports)
- 🔑 **Clés API** depuis les fichiers de configuration
- 🐍 **Environnements virtuels** existants (VIRTUAL_ENV, SETTINGS_SOURCE)
- 🌐 **Configuration réseau** (traefik_proxy, bridge, port mapping)

### **💾 Environnements Virtuels**

Le script détecte et réutilise automatiquement :
```bash
# Environnement actif
$VIRTUAL_ENV (/home/user/seedbox-compose/venv)

# Structure seedbox-compose
$SETTINGS_SOURCE/venv (/home/user/seedbox-compose/venv)
```

**Avantages** :
- ✅ **Pas de duplication** des dépendances Python
- ✅ **Économie d'espace disque**
- ✅ **Compatibilité** avec infrastructures existantes
- ✅ **Lien symbolique** intelligent vers venv existant

## ⚙️ Configuration

### **Configuration Automatique**

Le fichier `config/config.yaml.local` est créé automatiquement avec :

```yaml
# Configuration détectée automatiquement
sonarr:
  enabled: true
  url: "http://172.18.0.5:8989"  # IP détectée automatiquement
  api_key: "abc12345..."         # Clé extraite automatiquement

radarr:
  enabled: true  
  url: "http://172.18.0.6:7878"  # IP détectée automatiquement
  api_key: "def67890..."         # Clé extraite automatiquement
```

### **Personnalisation**

```yaml
# Seuils de surveillance
monitoring:
  check_interval: 300        # Vérification toutes les 5 minutes
  stuck_threshold: 3600      # Téléchargement bloqué après 1h
  retry_threshold: 1800      # Nouvelle tentative après 30min

# Actions automatiques  
actions:
  auto_retry: true           # Relance automatique
  auto_remove: true          # Suppression automatique
  max_retries: 3             # Maximum 3 tentatives

# Notifications
notifications:
  webhook:
    enabled: true
    url: "https://hooks.slack.com/..."
  email:
    enabled: false
    smtp_server: "smtp.gmail.com"
```

## 📋 Utilisation

### **Commandes de Base**

```bash
# Navigation vers l'installation
cd /home/$USER/scripts/Arr-Monitor

# Surveillance en temps réel
./venv/bin/python arr-monitor.py --config config/config.yaml.local

# Test de configuration  
./venv/bin/python arr-monitor.py --test --config config/config.yaml.local

# Mode debug pour diagnostic
./venv/bin/python arr-monitor.py --debug --config config/config.yaml.local

# Mode simulation (sans actions)
./venv/bin/python arr-monitor.py --dry-run --config config/config.yaml.local
```

### **Service Systemd**

```bash
# Installation du service (lors de l'installation initiale)
sudo systemctl enable arr-monitor
sudo systemctl start arr-monitor

# Gestion du service
sudo systemctl status arr-monitor     # Vérifier le statut  
sudo systemctl stop arr-monitor      # Arrêter
sudo systemctl restart arr-monitor   # Redémarrer

# Consulter les logs
sudo journalctl -u arr-monitor -f    # Logs en temps réel
sudo journalctl -u arr-monitor -n 50 # 50 dernières lignes
```

### **Logs et Monitoring**

```bash
# Logs de l'application
tail -f logs/arr-monitor.log

# Statistiques en temps réel
grep "STATS" logs/arr-monitor.log | tail -10

# Erreurs uniquement
grep "ERROR\|CRITICAL" logs/arr-monitor.log
```

## 🔧 Maintenance

### **Mise à jour**

```bash
# Mise à jour automatique (recommandée)
curl -sL https://raw.githubusercontent.com/kesurof/Arr-Monitor/main/install-arr.sh | bash -s -- --update

# Mise à jour manuelle
cd Arr-Monitor
git pull origin main
./install-arr.sh --update
```

### **Sauvegarde de Configuration**

```bash
# Sauvegarder la configuration
cp config/config.yaml.local ~/arr-monitor-backup-$(date +%Y%m%d).yaml

# Restaurer la configuration 
cp ~/arr-monitor-backup-20250712.yaml config/config.yaml.local
```

### **Diagnostic**

```bash
# Vérifier l'état du système
./venv/bin/python arr-monitor.py --test

# Vérifier les conteneurs Docker
docker ps | grep -E "(sonarr|radarr)"

# Vérifier les APIs
curl -H "X-Api-Key: YOUR_API_KEY" "http://localhost:8989/api/v3/system/status"
curl -H "X-Api-Key: YOUR_API_KEY" "http://localhost:7878/api/v3/system/status"
```

### **Dépannage**

```bash
# Problème de dépendances Python
./venv/bin/pip install -r requirements.txt

# Recréer l'environnement virtuel
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Réinitialiser la configuration
rm config/config.yaml.local
./install-arr.sh  # Relancer la configuration
```

## 🗑️ Désinstallation

### **Désinstallation Automatique**

```bash
# Télécharger et exécuter le script de désinstallation
curl -sL https://raw.githubusercontent.com/kesurof/Arr-Monitor/main/uninstall-arr.sh | bash

# Ou depuis le répertoire local
./uninstall-arr.sh
```

### **Désinstallation Manuelle**

```bash
# Arrêter et supprimer le service
sudo systemctl stop arr-monitor
sudo systemctl disable arr-monitor  
sudo rm -f /etc/systemd/system/arr-monitor.service
sudo systemctl daemon-reload

# Supprimer l'installation
rm -rf /home/$USER/scripts/Arr-Monitor

# Tuer les processus restants
pkill -f "arr-monitor.py"
```

### **Le script de désinstallation :**
- ✅ **Détecte automatiquement** les installations
- ✅ **Sauvegarde optionnelle** de la configuration  
- ✅ **Préserve** les environnements virtuels externes
- ✅ **Supprime proprement** le service systemd
- ✅ **Nettoie** les processus et logs
- ✅ **Rapport détaillé** des actions effectuées

# Mode test (une vérification uniquement)
python arr-monitor.py --test --config config/config.yaml.local

# Mode debug (logs détaillés)
python arr-monitor.py --debug --config config/config.yaml.local

# Mode simulation (sans actions)
python arr-monitor.py --dry-run --config config/config.yaml.local
```

## 🔧 Service Système

Pour une surveillance continue, installez comme service :

```bash
# Copier le fichier service
sudo cp arr-monitor.service /etc/systemd/system/

# Éditer les chemins dans le service
sudo nano /etc/systemd/system/arr-monitor.service

# Activer et démarrer
sudo systemctl enable arr-monitor
sudo systemctl start arr-monitor
sudo systemctl status arr-monitor
```

## 📊 Surveillance

### Logs
```bash
# Voir les logs en temps réel
tail -f logs/arr-monitor.log

# Voir les logs du service
sudo journalctl -u arr-monitor -f
```

### Métriques surveillées
- **Files d'attente** : éléments en cours
- **Erreurs** : téléchargements échoués
- **Bloqués** : éléments sans progression
- **Historique** : téléchargements récents

## 🛠️ Dépendances

- Python 3.6+
- requests >= 2.28.0
## 🎛️ Fonctionnement Avancé

### **Modes de Détection Docker**

L'installation utilise **3 méthodes** de détection pour maximiser la compatibilité :

1. **🌐 Réseau traefik_proxy** (priorité haute)
   ```bash
   # Récupération IP via réseau traefik_proxy
   docker inspect container --format='{{.NetworkSettings.Networks.traefik_proxy.IPAddress}}'
   ```

2. **🔗 Réseau par défaut** (fallback)  
   ```bash
   # Récupération IP via premier réseau disponible
   docker inspect container --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
   ```

3. **🔌 Port mapping** (dernier recours)
   ```bash
   # Utilisation ports exposés sur localhost
   docker port container 8989/tcp
   ```

### **Extraction Automatique des Clés API**

```bash
# Méthode 1 : Via SETTINGS_STORAGE (structure seedbox)
$SETTINGS_STORAGE/docker/$USER/sonarr/config/config.xml

# Méthode 2 : Via conteneur Docker
docker exec container cat /config/config.xml

# Méthode 3 : Fichiers locaux standards  
/home/$USER/.config/Sonarr/config.xml
```

### **Gestion Intelligente des Erreurs**

Le monitoring corrige automatiquement le bug **"'str' object has no attribute 'get'"** :

```python
# Correction automatique appliquée  
data = response.json()
if isinstance(data, list):
    return data
elif isinstance(data, dict) and 'records' in data:
    return data['records']
else:
    return []  # Format inattendu
```

## 📊 Exemples d'Usage

### **Infrastructure Docker Classique**

```bash
# Structure type
docker-compose.yml:
  sonarr:
    image: lscr.io/linuxserver/sonarr
    ports: ["8989:8989"]
  radarr:  
    image: lscr.io/linuxserver/radarr
    ports: ["7878:7878"]

# Détection automatique
✅ Sonarr détecté via port mapping: sonarr -> http://localhost:8989
✅ Radarr détecté via port mapping: radarr -> http://localhost:7878
```

### **Infrastructure Traefik**

```bash
# Réseau traefik_proxy
networks:
  traefik_proxy:
    external: true

# Détection automatique  
✅ Sonarr détecté via IP container: sonarr -> http://172.18.0.5:8989
✅ Radarr détecté via IP container: radarr -> http://172.18.0.6:7878
```

### **Structure Seedbox-Compose**

```bash
# Variables d'environnement
SETTINGS_SOURCE=/home/user/seedbox-compose
SETTINGS_STORAGE=/home/user/seedbox/

# Détection automatique
🔍 Environnement virtuel détecté: /home/user/seedbox-compose/venv
🔑 Clé API Sonarr trouvée via SETTINGS_STORAGE: abc12345...
🔗 Utilisation du venv existant (lien symbolique créé)
```

## 🔧 Configuration Avancée

### **Variables d'Environnement**

```bash
# Pour infrastructures personnalisées
export SETTINGS_SOURCE="/path/to/seedbox-compose"
export SETTINGS_STORAGE="/path/to/seedbox/data"

# Pour environnements virtuels spécifiques  
export VIRTUAL_ENV="/path/to/custom/venv"
```

### **Configuration Personnalisée**

```yaml
# config/config.yaml.local
monitoring:
  # Intervalle de vérification (secondes)
  check_interval: 300
  
  # Seuil téléchargement bloqué (secondes)  
  stuck_threshold: 3600
  
  # Seuil nouvelle tentative (secondes)
  retry_threshold: 1800
  
  # Applications à surveiller
  apps: ["sonarr", "radarr"]

actions:
  # Actions automatiques
  auto_retry: true
  auto_remove: true
  
  # Limites de sécurité
  max_retries: 3
  max_removals_per_run: 5

logging:
  # Niveau de log
  level: "INFO"  # DEBUG, INFO, WARNING, ERROR
  
  # Rotation des logs
  max_size_mb: 10
  backup_count: 5
```

## 🛠️ Dépendances & Prérequis

### **Système**
- **Python 3.8+** (testé sur 3.8, 3.9, 3.10, 3.11, 3.12)
- **pip3** pour la gestion des packages
- **Docker** (optionnel, pour détection automatique)
- **systemd** (optionnel, pour service automatique)

### **Python**
```txt
# requirements.txt
PyYAML >= 6.0.2
requests >= 2.32.0
```

### **APIs**
- **Sonarr API v3** : `/api/v3/*`
- **Radarr API v3** : `/api/v3/*`
- **Permissions** : lecture queue/history, écriture commands

## 📁 Structure du Projet

```
arr-monitor/
├── 📄 arr-monitor.py          # 🔵 Script principal de surveillance
├── 📄 install-arr.sh          # 🟢 Installation automatique  
├── 📄 uninstall-arr.sh        # 🔴 Désinstallation complète
├── 📄 arr-monitor.service     # ⚙️  Template service systemd
├── 📄 requirements.txt        # 📦 Dépendances Python
├── 📄 config.yaml             # ⚙️  Configuration par défaut
├── 📄 MANUAL_CLEANUP.md       # 📋 Commandes nettoyage manuel
├── 📄 README.md               # 📖 Documentation complète
├── 📄 CHANGELOG.md            # 📋 Historique des versions
└── 📁 Structure post-installation:
    ├── 📁 config/
    │   ├── 📄 config.yaml         # Configuration par défaut
    │   └── 📄 config.yaml.local   # Configuration personnalisée
    ├── 📁 logs/
    │   └── 📄 arr-monitor.log     # Logs de l'application
    ├── 🔗 venv/                   # Environnement virtuel (lien/dossier)
    └── 📄 arr-monitor.py          # Script copié localement
```

## 🔗 APIs et Intégrations

### **Sonarr API v3**
```bash
# Endpoints utilisés
GET  /api/v3/system/status      # Vérification connexion
GET  /api/v3/queue             # File d'attente
GET  /api/v3/history           # Historique  
POST /api/v3/command           # Commandes (retry, delete)
```

### **Radarr API v3** 
```bash
# Endpoints utilisés (identiques à Sonarr)
GET  /api/v3/system/status      # Vérification connexion
GET  /api/v3/queue             # File d'attente
GET  /api/v3/history           # Historique
POST /api/v3/command           # Commandes (retry, delete)
```

### **Webhooks & Notifications**
```bash
# Format webhook (JSON)
{
  "event": "download_retry",
  "app": "sonarr", 
  "title": "Episode Title",
  "status": "failed",
  "action": "retried",
  "timestamp": "2025-07-12T22:30:00Z"
}
```

## 🎯 Roadmap

### **🔄 Version 2.1 (Prochaine)**
- [ ] **Interface Web** pour configuration et monitoring
- [ ] **Métriques Prometheus** pour monitoring avancé  
- [ ] **Support Lidarr** et autres applications *arr
- [ ] **Notifications Discord/Telegram** intégrées
- [ ] **Règles personnalisées** par catégorie de contenu

### **🚀 Version 3.0 (Future)**  
- [ ] **API REST** pour intégrations externes
- [ ] **Dashboard temps réel** avec graphiques
- [ ] **Plugin système** pour gestionnaires de seedbox
- [ ] **Support multi-instances** Sonarr/Radarr
- [ ] **Machine Learning** pour prédiction des erreurs

## 📝 Changelog

### **v2.0.0** (2025-07-12)
- ✅ **Détection automatique** conteneurs Docker & APIs
- ✅ **Support environnements virtuels** existants  
- ✅ **Installation zéro-configuration**
- ✅ **Script désinstallation** complet
- ✅ **Service systemd** auto-configuré
- ✅ **Correction bug** format queue API

### **v1.0.0** (2025-07-01)
- ✅ **Surveillance** Sonarr/Radarr basique
- ✅ **Actions automatiques** retry/remove
- ✅ **Configuration YAML** 
- ✅ **Logging** structuré

## 📝 Licence

**MIT License** - Voir le fichier [LICENSE](LICENSE)

## 🤝 Contribution

Les **contributions** sont les bienvenues ! 

1. **Fork** le projet
2. **Créer** une branche feature (`git checkout -b feature/amazing`)  
3. **Commit** les changements (`git commit -m 'Add amazing feature'`)
4. **Push** la branche (`git push origin feature/amazing`)
5. **Ouvrir** une Pull Request

### **🐛 Rapport de Bug**
- Utiliser les **issues GitHub**
- Inclure les **logs** (`logs/arr-monitor.log`)
- Préciser la **configuration** (sans les clés API)
- Mentionner l'**environnement** (OS, Python, Docker)

## 💬 Support

- **📋 Issues** : [GitHub Issues](https://github.com/kesurof/Arr-Monitor/issues)
- **💡 Discussions** : [GitHub Discussions](https://github.com/kesurof/Arr-Monitor/discussions)  
- **📧 Email** : Voir profil GitHub

---

## 🎉 Remerciements

- **Sonarr/Radarr teams** pour les excellentes APIs
- **LinuxServer.io** pour les images Docker
- **Traefik** pour l'inspiration réseau
- **Communauté seedbox** pour les retours et tests

---

**⭐ Si ce projet vous aide, n'hésitez pas à lui donner une étoile !**
