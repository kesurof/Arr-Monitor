# 🚀 Arr Monitor v1.1.3 - Surveillance Sonarr/Radarr

[![Version](https://img.shields.io/badge/version-1.1.3-blue.svg)](https://github.com/kesurof/Arr-Monitor)
[![Python](https://img.shields.io/badge/python-3.8+-green.svg)](https://python.org)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)
[![ARM64](https://img.shields.io/badge/ARM64-optimized-green.svg)](https://arm.com)

## 📝 Description

**Arr Monitor** est un outil de surveillance et de gestion automatique optimisé pour les serveurs ARM64. Il surveille Sonarr et Radarr, détecte les erreurs qBittorrent spécifiques, et applique l'action "Blocklist and Search" pour une résolution intelligente.

## ✨ Fonctionnalités

### 🔍 **Surveillance Intelligente**
- 🎯 **Détection spécifique** : "qBittorrent is reporting an error"
- 🚫 **Action intelligente** : Blocklist + Search automatique  
- 📊 **Surveillance continue** avec intervalle de 5 minutes
- 🔧 **Optimisé ARM64** pour votre serveur

### ⚡ **Actions Automatiques**
- 🚫 **Blocklist automatique** des releases défaillantes
- 🔍 **Recherche automatique** de nouvelles releases
- 🎯 **Résolution définitive** au lieu de retry en boucle
- ⏰ **Seuils configurables** pour chaque action

### 🐳 **Intégration Docker**
- 🔍 **Détection automatique** des conteneurs Sonarr/Radarr
- 🌐 **Support multi-réseaux** : traefik_proxy, bridge, custom
- 🔑 **Extraction automatique** des clés API depuis les configs
- 📁 **Support SETTINGS_STORAGE** pour infrastructures personnalisées

### 🔧 **Installation & Maintenance**
- 🚀 **Installation en une ligne** 
- 🐍 **Gestion intelligente** des environnements Python
- 🔗 **Réutilisation venv existants** (seedbox-compose compatible)
- ⚙️ **Service systemd** intégré avec auto-configuration

### 📱 **Interface & Monitoring**
- 🎯 **Menu interactif** avec toutes les fonctions
- 🔄 **Réactualisation automatique** des IPs et clés API
- 📊 **Logs structurés** avec niveaux configurables
- 🐛 **Mode debug** avancé pour diagnostic

## 🚀 Installation

### **Installation Recommandée**

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
# Depuis un répertoire temporaire (recommandé)
cd /tmp
git clone https://github.com/kesurof/Arr-Monitor.git
cd Arr-Monitor
./install-arr.sh --update
```

## 🎯 Utilisation

### **Commandes Bashrc (après installation)**

```bash
# Accès direct au menu interactif
arr-monitor

# Commandes directes
arr-monitor start      # Démarrer le monitoring
arr-monitor test       # Test de configuration
arr-monitor refresh    # Réactualiser IPs et clés API
arr-monitor logs       # Voir les logs en temps réel
arr-monitor help       # Aide complète
```

### **Menu Interactif**

Le launcher propose :
- 🔄 **Lancer Arr Monitor** (mode continu)
- 🧪 **Test unique** (mode debug)
- 🔬 **Diagnostic complet** de la queue
- ⚙️ **Configuration** interactive
- 🔄 **Réactualiser IPs et clés API** automatiquement
- 📊 **État du système**
- 🔍 **Vérifier les mises à jour**
- 🧹 **Nettoyer les logs**
- 📋 **Logs en temps réel**
- 🛠️ **Installation/Configuration systemd**
- 🎯 **Configurer commandes bashrc**

### **Service Systemd**

```bash
# Gestion du service (installé automatiquement)
sudo systemctl status arr-monitor     # Vérifier le statut  
sudo systemctl restart arr-monitor    # Redémarrer
sudo systemctl stop arr-monitor       # Arrêter

# Consulter les logs
sudo journalctl -u arr-monitor -f     # Logs en temps réel
```

## ⚙️ Configuration

### **Configuration Automatique**

Le fichier `config/config.yaml.local` est créé automatiquement avec :

```yaml
# Configuration détectée automatiquement
applications:
  sonarr:
    enabled: true
    url: "http://172.18.0.5:8989"  # IP détectée automatiquement
    api_key: "abc12345..."         # Clé extraite automatiquement
  radarr:
    enabled: true  
    url: "http://172.18.0.6:7878"  # IP détectée automatiquement
    api_key: "def67890..."         # Clé extraite automatiquement

# Surveillance
monitoring:
  check_interval: 300        # Vérification toutes les 5 minutes

# Actions automatiques  
actions:
  auto_retry: true           # Blocklist + Search automatique
  retry_delay: 60            # Délai entre actions (1min)
  max_retries: 3             # Maximum 3 tentatives
```

### **Réactualisation Automatique**

Utilisez `arr-monitor refresh` ou l'option 5 du menu pour :
- 🔍 **Redétecter** les conteneurs Docker
- 🔑 **Réextraire** les clés API
- 🔄 **Mettre à jour** automatiquement la configuration
- 🧪 **Tester** les nouvelles connexions

## 🔧 Maintenance

### **Diagnostic**

```bash
# Test de la configuration
arr-monitor test

# Mode debug détaillé
cd /home/$USER/scripts/Arr-Monitor
python arr-monitor.py --debug --config config/config.yaml.local

# Vérifier les conteneurs Docker
docker ps | grep -E "(sonarr|radarr)"
```

### **Dépannage**

```bash
# Réinstaller les dépendances
cd /home/$USER/scripts/Arr-Monitor
source venv/bin/activate
pip install -r requirements.txt

# Réactualiser la configuration
arr-monitor refresh

# Reconfigurer complètement
rm config/config.yaml.local
./install-arr.sh  # Relancer la configuration
```

## 🗑️ Désinstallation

### **Désinstallation Automatique**

```bash
# Télécharger et exécuter le script de désinstallation
curl -sL https://raw.githubusercontent.com/kesurof/Arr-Monitor/main/uninstall-arr.sh | bash
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

# Supprimer les commandes bashrc
sed -i '/^# Arr Monitor function$/,/^alias arr=/d' ~/.bashrc
```

## 🛠️ Dépendances

### **Système**
- **Python 3.8+**
- **pip3** pour la gestion des packages
- **Docker** (optionnel, pour détection automatique)
- **systemd** (optionnel, pour service automatique)

### **Python**
```txt
PyYAML >= 6.0.2
requests >= 2.32.0
packaging >= 21.0
```

### **APIs**
- **Sonarr API v3** : `/api/v3/*`
- **Radarr API v3** : `/api/v3/*`
- **Permissions** : lecture queue/history, écriture commands

## 📁 Structure du Projet

```
/home/$USER/scripts/Arr-Monitor/
├── 📄 arr-monitor.py          # Script principal de surveillance
├── 📄 arr-launcher.sh         # Menu interactif unifié
├── 📄 update_checker.py       # Vérification des mises à jour
├── 📄 requirements.txt        # Dépendances Python
├── 📁 config/
│   ├── 📄 config.yaml         # Configuration par défaut
│   └── 📄 config.yaml.local   # Configuration personnalisée
├── 📁 logs/
│   └── 📄 arr-monitor.log     # Logs de l'application
└── 🔗 venv/                   # Environnement virtuel
```

## 📝 Licence

**MIT License** - Voir le fichier [LICENSE](LICENSE)

## 🤝 Support

- **📋 Issues** : [GitHub Issues](https://github.com/kesurof/Arr-Monitor/issues)
- **💡 Discussions** : [GitHub Discussions](https://github.com/kesurof/Arr-Monitor/discussions)

---

**⭐ Si ce projet vous aide, n'hésitez pas à lui donner une étoile !**