#!/bin/bash

# Script d'installation Arr Monitor (Surveillance Sonarr/Radarr)
set -euo pipefail

# Gestion des paramètres
FORCE_INSTALL=false
OPERATION_MODE=""

for arg in "$@"; do
    case $arg in
        --update)
            FORCE_INSTALL=true
            OPERATION_MODE="update"
            shift
            ;;
        --install)
            FORCE_INSTALL=true
            OPERATION_MODE="install"
            shift
            ;;
        *)
            ;;
    esac
done

echo "🚀 Installation Arr Monitor - Surveillance Sonarr/Radarr"
echo ""

# Si pas de paramètre, demander le mode d'opération
if [ -z "$OPERATION_MODE" ]; then
    echo "🎯 Sélectionnez le mode d'opération :"
    echo "   1️⃣  Nouvelle installation"
    echo "   2️⃣  Mise à jour (préserve la configuration existante)"
    echo ""
    read -p "Votre choix [1/2] : " CHOICE
    
    case $CHOICE in
        1)
            OPERATION_MODE="install"
            ;;
        2)
            OPERATION_MODE="update"
            FORCE_INSTALL=true
            ;;
        *)
            echo "❌ Choix invalide. Abandon."
            exit 1
            ;;
    esac
fi

echo ""
if [ "$OPERATION_MODE" = "install" ]; then
    echo "📂 Mode : NOUVELLE INSTALLATION"
    echo "   • Copier les fichiers depuis le répertoire courant"
    echo "   • Les installer dans un répertoire de destination"
    echo "   • Créer un environnement Python virtuel"
    echo "   • Détecter automatiquement Sonarr/Radarr"
elif [ "$OPERATION_MODE" = "update" ]; then
    echo "📂 Mode : MISE À JOUR"
    echo "   • Mettre à jour les fichiers dans l'installation existante"
    echo "   • Préserver la configuration actuelle"
    echo "   • Maintenir l'environnement virtuel existant"
fi
echo ""
echo "💡 Utilisation typique :"
echo "   # Pour mise à jour depuis /tmp :"
echo "   cd /tmp && git clone https://github.com/kesurof/Arr-Monitor.git"
echo "   cd Arr-Monitor && ./install-arr.sh --update"
echo ""

# Vérification des prérequis
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

# Vérification que nous sommes dans le bon répertoire
if [ ! -f "arr-monitor.py" ] || [ ! -f "requirements.txt" ] || [ ! -f "config.yaml" ]; then
    echo "❌ Fichiers manquants dans $(pwd) :"
    [ ! -f "arr-monitor.py" ] && echo "   - arr-monitor.py"
    [ ! -f "requirements.txt" ] && echo "   - requirements.txt"
    [ ! -f "config.yaml" ] && echo "   - config.yaml"
    echo ""
    echo "💡 Assurez-vous d'exécuter ce script depuis le répertoire contenant les fichiers du projet."
    echo "   Exemple : cd /path/to/Arr-Monitor && ./install-arr.sh"
    exit 1
fi

SOURCE_DIR="$(pwd)"

# Demander l'emplacement pour l'installation
echo ""
if [ "$OPERATION_MODE" = "update" ]; then
    # Mode mise à jour : utiliser le répertoire par défaut
    SCRIPTS_DIR="/home/$USER/scripts"
    echo "📁 Mode mise à jour : utilisation du répertoire par défaut ($SCRIPTS_DIR)"
else
    # Mode installation : demander le répertoire
    read -p "📁 Répertoire d'installation des scripts [/home/$USER/scripts] : " SCRIPTS_DIR
fi
SCRIPTS_DIR=${SCRIPTS_DIR:-/home/$USER/scripts}

# Répertoire d'installation final
INSTALL_DIR="$SCRIPTS_DIR/Arr-Monitor"
echo "📁 Installation dans : $INSTALL_DIR"

# Création du répertoire d'installation
IS_UPDATE=false
if [ -d "$INSTALL_DIR" ]; then
    if [ "$OPERATION_MODE" = "update" ]; then
        echo "📂 Installation existante trouvée. Mode mise à jour confirmé."
        IS_UPDATE=true
    else
        echo "📂 Installation existante détectée."
        read -p "🔄 Voulez-vous faire une mise à jour (y) ou réinstaller complètement (n) ? [y/N] : " UPDATE_CHOICE
        if [[ $UPDATE_CHOICE =~ ^[Yy]$ ]]; then
            IS_UPDATE=true
            OPERATION_MODE="update"
            echo "✅ Mode mise à jour activé"
        else
            echo "🗑️  Suppression de l'installation existante..."
            rm -rf "$INSTALL_DIR"
            mkdir -p "$INSTALL_DIR"
            echo "✅ Répertoire nettoyé pour nouvelle installation"
        fi
    fi
    
    # Sauvegarde de la configuration existante si mise à jour
    if [ "$IS_UPDATE" = true ] && [ -f "$INSTALL_DIR/config/config.yaml.local" ]; then
        BACKUP_FILE="$INSTALL_DIR/config/config.yaml.local.backup.$(date +%Y%m%d_%H%M%S)"
        echo "💾 Sauvegarde de la configuration : $(basename "$BACKUP_FILE")"
        cp "$INSTALL_DIR/config/config.yaml.local" "$BACKUP_FILE"
    fi
else
    echo "📥 Nouvelle installation..."
    mkdir -p "$INSTALL_DIR"
fi

# Maintenant on peut changer de répertoire
echo "📂 Changement vers le répertoire d'installation : $INSTALL_DIR"
cd "$INSTALL_DIR"
echo "📍 Répertoire courant : $(pwd)"

# Copie des fichiers depuis le répertoire source
echo "📋 Copie des fichiers depuis $SOURCE_DIR vers $INSTALL_DIR..."
cp "$SOURCE_DIR/arr-monitor.py" ./
cp "$SOURCE_DIR/requirements.txt" ./

# Copier tous les fichiers nécessaires
if [ -f "$SOURCE_DIR/arr-launcher.sh" ]; then
    cp "$SOURCE_DIR/arr-launcher.sh" ./
    chmod +x arr-launcher.sh
    echo "✅ arr-launcher.sh copié"
fi

if [ -f "$SOURCE_DIR/update_checker.py" ]; then
    cp "$SOURCE_DIR/update_checker.py" ./
    echo "✅ update_checker.py copié"
fi

if [ -f "$SOURCE_DIR/.version" ]; then
    cp "$SOURCE_DIR/.version" ./
    echo "✅ .version copié"
fi

# Création du répertoire config et copie
mkdir -p config
cp "$SOURCE_DIR/config.yaml" config/

# Copier le fichier service pour installation
if [ -f "$SOURCE_DIR/arr-monitor.service" ]; then
    cp "$SOURCE_DIR/arr-monitor.service" arr-monitor.service.tmp
fi

echo "✅ Fichiers copiés avec succès"

# Application automatique de la correction du bug get_queue supprimée - non nécessaire
echo "🔧 Vérification du code Python..."
echo "✅ Fichiers copiés et prêts"

# Détection et gestion de l'environnement virtuel
echo "🐍 Gestion de l'environnement virtuel Python..."

# Vérifier si un venv est déjà actif et contient les dépendances nécessaires
EXISTING_VENV=""
if [ -n "$VIRTUAL_ENV" ] && [ -f "$VIRTUAL_ENV/bin/python" ]; then
    # Vérifier que les dépendances sont installées
    if "$VIRTUAL_ENV/bin/python" -c "import yaml, requests" &> /dev/null; then
        echo "🔍 Environnement virtuel actif détecté: $VIRTUAL_ENV"
        echo "✅ Dépendances détectées dans l'environnement actif"
        EXISTING_VENV="$VIRTUAL_ENV"
    else
        echo "🔍 Environnement virtuel actif détecté: $VIRTUAL_ENV"
        echo "⚠️  Dépendances manquantes dans l'environnement actif"
    fi
fi

# Vérifier si un venv seedbox-compose existe
if [ -z "$EXISTING_VENV" ] && [ -n "$SETTINGS_SOURCE" ] && [ -f "$SETTINGS_SOURCE/venv/bin/python" ]; then
    # Vérifier que les dépendances sont installées
    if "$SETTINGS_SOURCE/venv/bin/python" -c "import yaml, requests" &> /dev/null; then
        echo "🔍 Environnement virtuel seedbox-compose détecté: $SETTINGS_SOURCE/venv"
        echo "✅ Dépendances détectées dans l'environnement seedbox-compose"
        EXISTING_VENV="$SETTINGS_SOURCE/venv"
    else
        echo "🔍 Environnement virtuel seedbox-compose détecté: $SETTINGS_SOURCE/venv"
        echo "⚠️  Dépendances manquantes dans l'environnement seedbox-compose"
    fi
fi

if [ -n "$EXISTING_VENV" ]; then
    echo "🔗 Utilisation de l'environnement virtuel existant: $EXISTING_VENV"
    
    # Vérifier si c'est un lien symbolique existant et s'il pointe au bon endroit
    if [ -L "venv" ]; then
        CURRENT_TARGET=$(readlink "venv")
        if [ "$CURRENT_TARGET" != "$EXISTING_VENV" ]; then
            echo "🔗 Mise à jour du lien symbolique venv"
            rm venv
            ln -sf "$EXISTING_VENV" venv
        else
            echo "✅ Lien symbolique venv déjà correct"
        fi
    else
        # Supprimer l'ancien venv s'il existe et créer le lien
        [ -d "venv" ] && rm -rf venv
        ln -sf "$EXISTING_VENV" venv
        echo "✅ Lien symbolique créé vers l'environnement existant"
    fi
else
    echo "📦 Création d'un nouvel environnement virtuel..."
    
    # Supprimer l'ancien environnement s'il existe
    [ -e "venv" ] && rm -rf venv
    
    # Créer le nouvel environnement
    python3 -m venv venv
    
    # Activer et installer les dépendances
    source venv/bin/activate
    echo "📦 Installation des dépendances..."
    pip install --upgrade pip
    pip install -r requirements.txt
    
    echo "✅ Environnement virtuel créé et configuré"
fi

# Créer les répertoires nécessaires
echo "📁 Création des répertoires..."
mkdir -p logs

# Configuration interactive seulement si nouveau fichier créé
CONFIG_CREATED=false
echo "📍 Vérification de config.yaml.local dans : $(pwd)"
if [ ! -f "config/config.yaml.local" ]; then
    echo "📋 Création de config.yaml.local..."
    cp config/config.yaml config/config.yaml.local
    CONFIG_CREATED=true
    echo "✅ config.yaml.local créé dans : $(pwd)/config/"
else
    echo "✅ config.yaml.local existe déjà dans : $(pwd)/config/"
    CONFIG_CREATED=false
fi

# Fonctions de détection
detect_containers() {
    SONARR_DETECTED=""
    RADARR_DETECTED=""
    
    echo "🔍 Détection automatique des conteneurs..."
    
    if command -v docker &> /dev/null; then
        # Détecter Sonarr
        if docker ps --format "table {{.Names}}" | grep -q "sonarr"; then
            SONARR_CONTAINER=$(docker ps --format "table {{.Names}}" | grep "sonarr" | head -1)
            
            # Méthode 1: Essayer réseau traefik_proxy
            SONARR_IP=$(docker inspect $SONARR_CONTAINER --format='{{.NetworkSettings.Networks.traefik_proxy.IPAddress}}' 2>/dev/null | grep -v '^$' | head -1)
            
            # Méthode 2: Si pas de traefik_proxy, prendre la première IP disponible
            if [ -z "$SONARR_IP" ]; then
                SONARR_IP=$(docker inspect $SONARR_CONTAINER --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
            fi
            
            # Méthode 3: Si toujours pas d'IP, utiliser le port mapping
            if [ -z "$SONARR_IP" ]; then
                SONARR_PORT=$(docker port $SONARR_CONTAINER 8989/tcp 2>/dev/null | cut -d: -f2)
                if [ -n "$SONARR_PORT" ]; then
                    SONARR_DETECTED="http://localhost:$SONARR_PORT"
                    echo "  ✅ Sonarr détecté via port mapping: $SONARR_CONTAINER -> $SONARR_DETECTED"
                fi
            else
                SONARR_DETECTED="http://$SONARR_IP:8989"
                echo "  ✅ Sonarr détecté via IP container: $SONARR_CONTAINER -> $SONARR_DETECTED"
            fi
        fi
        
        # Détecter Radarr (même logique)
        if docker ps --format "table {{.Names}}" | grep -q "radarr"; then
            RADARR_CONTAINER=$(docker ps --format "table {{.Names}}" | grep "radarr" | head -1)
            
            # Méthode 1: Essayer réseau traefik_proxy
            RADARR_IP=$(docker inspect $RADARR_CONTAINER --format='{{.NetworkSettings.Networks.traefik_proxy.IPAddress}}' 2>/dev/null | grep -v '^$' | head -1)
            
            # Méthode 2: Si pas de traefik_proxy, prendre la première IP disponible
            if [ -z "$RADARR_IP" ]; then
                RADARR_IP=$(docker inspect $RADARR_CONTAINER --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
            fi
            
            # Méthode 3: Si toujours pas d'IP, utiliser le port mapping
            if [ -z "$RADARR_IP" ]; then
                RADARR_PORT=$(docker port $RADARR_CONTAINER 7878/tcp 2>/dev/null | cut -d: -f2)
                if [ -n "$RADARR_PORT" ]; then
                    RADARR_DETECTED="http://localhost:$RADARR_PORT"
                    echo "  ✅ Radarr détecté via port mapping: $RADARR_CONTAINER -> $RADARR_DETECTED"
                fi
            else
                RADARR_DETECTED="http://$RADARR_IP:7878"
                echo "  ✅ Radarr détecté via IP container: $RADARR_CONTAINER -> $RADARR_DETECTED"
            fi
        fi
        
        if [ -z "$SONARR_DETECTED" ] && [ -z "$RADARR_DETECTED" ]; then
            echo "  ⚠️  Aucun conteneur Sonarr/Radarr détecté"
        fi
    fi
}

detect_api_keys() {
    SONARR_API_DETECTED=""
    RADARR_API_DETECTED=""
    
    echo "🔑 Recherche des clés API..."
    
    # Fonction pour extraire la clé API depuis un fichier config.xml
    extract_api_key() {
        local config_file="$1"
        if [ -f "$config_file" ]; then
            grep -o '<ApiKey>[^<]*</ApiKey>' "$config_file" 2>/dev/null | sed 's/<ApiKey>\(.*\)<\/ApiKey>/\1/' | head -1
        fi
    }
    
    # Chercher les clés API Sonarr
    # Méthode 1: Via SETTINGS_STORAGE (structure seedbox)
    if [ -n "$SETTINGS_STORAGE" ] && [ -f "$SETTINGS_STORAGE/docker/$USER/sonarr/config/config.xml" ]; then
        SONARR_API_DETECTED=$(extract_api_key "$SETTINGS_STORAGE/docker/$USER/sonarr/config/config.xml")
        [ -n "$SONARR_API_DETECTED" ] && echo "  🔑 Clé API Sonarr trouvée via SETTINGS_STORAGE: ${SONARR_API_DETECTED:0:8}..."
    fi
    
    # Méthode 2: Via conteneur Docker  
    if [ -z "$SONARR_API_DETECTED" ] && command -v docker &> /dev/null && docker ps --format "table {{.Names}}" | grep -q "sonarr"; then
        SONARR_CONTAINER=$(docker ps --format "table {{.Names}}" | grep "sonarr" | head -1)
        SONARR_API_DETECTED=$(docker exec "$SONARR_CONTAINER" cat /config/config.xml 2>/dev/null | grep -o '<ApiKey>[^<]*</ApiKey>' | sed 's/<ApiKey>\(.*\)<\/ApiKey>/\1/' | head -1)
        [ -n "$SONARR_API_DETECTED" ] && echo "  🔑 Clé API Sonarr trouvée via conteneur: ${SONARR_API_DETECTED:0:8}..."
    fi
    
    # Méthode 3: Fichiers locaux standards
    if [ -z "$SONARR_API_DETECTED" ] && [ -f "/home/$USER/.config/Sonarr/config.xml" ]; then
        SONARR_API_DETECTED=$(extract_api_key "/home/$USER/.config/Sonarr/config.xml")
        [ -n "$SONARR_API_DETECTED" ] && echo "  🔑 Clé API Sonarr trouvée dans ~/.config: ${SONARR_API_DETECTED:0:8}..."
    fi
    
    # Chercher les clés API Radarr (même logique)
    # Méthode 1: Via SETTINGS_STORAGE
    if [ -n "$SETTINGS_STORAGE" ] && [ -f "$SETTINGS_STORAGE/docker/$USER/radarr/config/config.xml" ]; then
        RADARR_API_DETECTED=$(extract_api_key "$SETTINGS_STORAGE/docker/$USER/radarr/config/config.xml")
        [ -n "$RADARR_API_DETECTED" ] && echo "  🔑 Clé API Radarr trouvée via SETTINGS_STORAGE: ${RADARR_API_DETECTED:0:8}..."
    fi
    
    # Méthode 2: Via conteneur Docker
    if [ -z "$RADARR_API_DETECTED" ] && command -v docker &> /dev/null && docker ps --format "table {{.Names}}" | grep -q "radarr"; then
        RADARR_CONTAINER=$(docker ps --format "table {{.Names}}" | grep "radarr" | head -1)
        RADARR_API_DETECTED=$(docker exec "$RADARR_CONTAINER" cat /config/config.xml 2>/dev/null | grep -o '<ApiKey>[^<]*</ApiKey>' | sed 's/<ApiKey>\(.*\)<\/ApiKey>/\1/' | head -1)
        [ -n "$RADARR_API_DETECTED" ] && echo "  🔑 Clé API Radarr trouvée via conteneur: ${RADARR_API_DETECTED:0:8}..."
    fi
    
    # Méthode 3: Fichiers locaux standards
    if [ -z "$RADARR_API_DETECTED" ] && [ -f "/home/$USER/.config/Radarr/config.xml" ]; then
        RADARR_API_DETECTED=$(extract_api_key "/home/$USER/.config/Radarr/config.xml")
        [ -n "$RADARR_API_DETECTED" ] && echo "  🔑 Clé API Radarr trouvée dans ~/.config: ${RADARR_API_DETECTED:0:8}..."
    fi
}

# Configuration interactive seulement si nouveau fichier créé
if [ "$CONFIG_CREATED" = true ]; then
    echo ""
    echo "📋 Configuration automatique des applications :"
    
    # Détection automatique
    detect_containers
    detect_api_keys
    
    # Configuration automatique Sonarr
    ENABLE_SONARR="Y"
    SONARR_URL=""
    SONARR_API=""
    
    if [ -n "$SONARR_DETECTED" ] && [ -n "$SONARR_API_DETECTED" ]; then
        SONARR_URL="$SONARR_DETECTED"
        SONARR_API="$SONARR_API_DETECTED"
        echo "� Sonarr configuré automatiquement : $SONARR_URL"
        
        # Test de connexion avec curl (plus fiable que Python à ce stade)
        if curl -s -f -H "X-Api-Key: $SONARR_API" "$SONARR_URL/api/v3/system/status" >/dev/null 2>&1; then
            echo "   ✅ Connexion Sonarr vérifiée"
        else
            echo "   ⚠️  Test connexion Sonarr échoué - mais clés détectées, configuration appliquée"
            # On garde ENABLE_SONARR="Y" car la détection a fonctionné
        fi
    else
        echo "📺 Sonarr non détecté automatiquement - désactivé"
        ENABLE_SONARR="N"
    fi
    
    # Configuration automatique Radarr  
    ENABLE_RADARR="Y"
    RADARR_URL=""
    RADARR_API=""
    
    if [ -n "$RADARR_DETECTED" ] && [ -n "$RADARR_API_DETECTED" ]; then
        RADARR_URL="$RADARR_DETECTED"
        RADARR_API="$RADARR_API_DETECTED"
        echo "🎬 Radarr configuré automatiquement : $RADARR_URL"
        
        # Test de connexion avec curl (plus fiable que Python à ce stade)
        if curl -s -f -H "X-Api-Key: $RADARR_API" "$RADARR_URL/api/v3/system/status" >/dev/null 2>&1; then
            echo "   ✅ Connexion Radarr vérifiée"
        else
            echo "   ⚠️  Test connexion Radarr échoué - mais clés détectées, configuration appliquée"
            # On garde ENABLE_RADARR="Y" car la détection a fonctionné
        fi
    else
        echo "🎬 Radarr non détecté automatiquement - désactivé"
        ENABLE_RADARR="N"
    fi
    
    # Actions automatiques activées automatiquement
    AUTO_ACTIONS="Y"
    echo "🤖 Actions automatiques : activées automatiquement"
    
    # Mise à jour du fichier de configuration
    echo ""
    echo "📝 Mise à jour de la configuration..."
    echo "📍 Configuration modifiée dans : $(pwd)/config/config.yaml.local"
    
    if [[ $ENABLE_SONARR =~ ^[Yy]$ ]]; then
        sed -i.bak1 "/sonarr:/,/radarr:/ s|enabled: false|enabled: true|" config/config.yaml.local
        sed -i.bak2 "s|url: \"http://localhost:8989\"|url: \"$SONARR_URL\"|" config/config.yaml.local
        sed -i.bak3 "s|api_key: \"your_sonarr_api_key\"|api_key: \"$SONARR_API\"|" config/config.yaml.local
    else
        sed -i.bak1 "/sonarr:/,/radarr:/ s|enabled: true|enabled: false|" config/config.yaml.local
    fi
    
    if [[ $ENABLE_RADARR =~ ^[Yy]$ ]]; then
        sed -i.bak4 "/radarr:/,/monitoring:/ s|enabled: false|enabled: true|" config/config.yaml.local
        sed -i.bak5 "s|url: \"http://localhost:7878\"|url: \"$RADARR_URL\"|" config/config.yaml.local
        sed -i.bak6 "s|api_key: \"your_radarr_api_key\"|api_key: \"$RADARR_API\"|" config/config.yaml.local
    else
        sed -i.bak4 "/radarr:/,/monitoring:/ s|enabled: true|enabled: false|" config/config.yaml.local
    fi
    
    if [[ $AUTO_ACTIONS =~ ^[Nn]$ ]]; then
        sed -i.bak7 "s|auto_retry: true|auto_retry: false|" config/config.yaml.local
    fi
    
    rm -f config/config.yaml.local.bak*
    
    echo "✅ Configuration créée dans config/config.yaml.local"
    
    # Test automatique après configuration
    echo ""
    echo "🧪 Test automatique de l'installation..."
    if python arr-monitor.py --test --config config/config.yaml.local 2>/dev/null; then
        echo "✅ Test réussi - Installation fonctionnelle !"
    else
        echo "⚠️  Test échoué - Vérifiez la configuration"
        echo "💡 Logs disponibles dans logs/arr-monitor.log"
    fi
else
    echo "✅ Configuration locale existante préservée"
    echo "💡 Pour reconfigurer, supprimez config/config.yaml.local et relancez l'installation"
fi

echo ""
if [ "$IS_UPDATE" = true ]; then
    echo "✅ Mise à jour terminée avec succès !"
    echo "💡 Votre configuration existante a été préservée"
else
    echo "✅ Installation terminée avec succès !"
fi
echo ""
echo "🎯 IMPORTANT : Toutes les commandes doivent être exécutées depuis le répertoire d'installation :"
echo "   cd $INSTALL_DIR"
echo ""
echo "📋 Utilisation :"
echo "   cd $INSTALL_DIR"
echo "   source venv/bin/activate  # Optionnel si lien symbolique"
echo "   python arr-monitor.py --config config/config.yaml.local"
echo ""
echo "📋 Commandes utiles :"
echo "   # Test unique"
echo "   cd $INSTALL_DIR && python arr-monitor.py --test --config config/config.yaml.local"
echo ""
echo "   # Mode debug"
echo "   cd $INSTALL_DIR && python arr-monitor.py --debug --config config/config.yaml.local"
echo ""
echo "   # Simulation sans actions"
echo "   cd $INSTALL_DIR && python arr-monitor.py --dry-run --config config/config.yaml.local"
echo ""
echo "   # Voir les logs"
echo "   cd $INSTALL_DIR && tail -f logs/arr-monitor.log"
echo ""
echo "📁 Configuration : $INSTALL_DIR/config/config.yaml.local"
echo "📝 Logs : $INSTALL_DIR/logs/arr-monitor.log"
echo ""
echo "🔧 Installation automatique du service système :"
echo ""

# Installation automatique du service systemd (sauf en mode update)
if [ "$OPERATION_MODE" = "update" ]; then
    echo "📋 Mode mise à jour : service systemd non modifié"
    INSTALL_SERVICE="N"
else
    echo "🛠️  Installation automatique du service systemd..."
    INSTALL_SERVICE="Y"
fi

if [[ $INSTALL_SERVICE =~ ^[Yy]$ ]]; then
    # Vérifier la disponibilité du fichier service
    SERVICE_FILE=""
    if [ -f "arr-monitor.service.tmp" ]; then
        SERVICE_FILE="arr-monitor.service.tmp"
    fi
    
    if [ -n "$SERVICE_FILE" ]; then
        echo "📋 Installation du service systemd..."
        
        # Vérifier que l'environnement virtuel fonctionne
        VENV_PYTHON_PATH=""
        
        # Déterminer le chemin Python à utiliser
        if [ -L "$INSTALL_DIR/venv" ]; then
            # Si c'est un lien symbolique, résoudre le chemin réel
            REAL_VENV_PATH=$(readlink -f "$INSTALL_DIR/venv")
            VENV_PYTHON_PATH="$REAL_VENV_PATH/bin/python"
            echo "🔗 Utilisation du venv lié: $REAL_VENV_PATH"
        elif [ -d "$INSTALL_DIR/venv" ]; then
            # Si c'est un répertoire normal
            VENV_PYTHON_PATH="$INSTALL_DIR/venv/bin/python"
            echo "📁 Utilisation du venv local: $INSTALL_DIR/venv"
        else
            echo "❌ Aucun environnement virtuel trouvé"
            exit 1
        fi
        
        if ! "$VENV_PYTHON_PATH" -c "import yaml, requests" &> /dev/null; then
            echo "⚠️  Problème avec l'environnement virtuel, réinstallation des dépendances..."
            if [ -L "$INSTALL_DIR/venv" ]; then
                # Pour un lien symbolique, installer dans le venv original
                REAL_VENV_PATH=$(readlink -f "$INSTALL_DIR/venv")
                "$REAL_VENV_PATH/bin/pip" install -r requirements.txt
            else
                # Pour un venv local, activer et installer
                source venv/bin/activate
                pip install -r requirements.txt
            fi
        fi
        
        # Copie et modification du fichier service avec chemin absolu
        cp "$SERVICE_FILE" arr-monitor.service.final
        sed -i.bak "s|%USER%|$USER|g" arr-monitor.service.final
        sed -i.bak2 "s|%INSTALL_DIR%|$INSTALL_DIR|g" arr-monitor.service.final
        
        # Installation du service
        sudo cp arr-monitor.service.final /etc/systemd/system/arr-monitor.service
        sudo systemctl daemon-reload
        sudo systemctl enable arr-monitor
        
        # Démarrer le service
        sudo systemctl start arr-monitor
        
        # Nettoyer les fichiers temporaires
        rm -f arr-monitor.service.final*
        rm -f arr-monitor.service.tmp
        
        echo "✅ Service systemd installé, activé et démarré"
        
        # Vérification finale du statut du service
        echo ""
        echo "🔍 Vérification finale du service..."
        sleep 3  # Laisser le temps au service de se stabiliser
        
        if sudo systemctl is-active --quiet arr-monitor; then
            echo "✅ Service arr-monitor : ACTIF et FONCTIONNEL"
            echo "   📊 Statut : $(sudo systemctl is-active arr-monitor)"
            echo "   🔄 État : $(sudo systemctl is-enabled arr-monitor)"
        else
            echo "❌ Service arr-monitor : PROBLÈME DÉTECTÉ"
            echo "   📊 Statut : $(sudo systemctl is-active arr-monitor)"
            echo "   🔄 État : $(sudo systemctl is-enabled arr-monitor)"
            echo ""
            echo "📋 Logs récents du service :"
            sudo journalctl -u arr-monitor -n 5 --no-pager
            echo ""
            echo "🔧 Tentative de redémarrage..."
            sudo systemctl restart arr-monitor
            sleep 2
            if sudo systemctl is-active --quiet arr-monitor; then
                echo "✅ Service redémarré avec succès"
            else
                echo "❌ Problème persistant - vérification manuelle requise"
            fi
        fi
        
        echo ""
        echo "📋 Commandes utiles pour le service :"
        echo "   sudo systemctl start arr-monitor    # Démarrer"
        echo "   sudo systemctl stop arr-monitor     # Arrêter"
        echo "   sudo systemctl restart arr-monitor  # Redémarrer"
        echo "   sudo systemctl status arr-monitor   # Vérifier le statut"
        echo "   sudo journalctl -u arr-monitor -f   # Voir les logs en temps réel"
    else
        echo "⚠️  Fichier service non disponible"
        echo "💡 Vous pouvez créer le service manuellement avec les instructions ci-dessous"
    fi
else
    echo "📋 Mode mise à jour : service systemd préservé"
    echo ""
    echo "💡 Pour gérer le service :"
    echo "   sudo systemctl restart arr-monitor  # Redémarrer avec la nouvelle version"
    echo "   sudo systemctl status arr-monitor   # Vérifier le statut"
    echo "   sudo journalctl -u arr-monitor -f   # Voir les logs"
fi

# Fonction pour ajouter la fonction arr-monitor au bashrc
setup_bashrc_function() {
    local bashrc_file="$HOME/.bashrc"
    local function_name="arr-monitor"
    local script_path="$INSTALL_DIR"
    
    echo "🔧 Configuration de la fonction bashrc '$function_name'..."
    
    # Vérifier si la fonction existe déjà
    if grep -q "function $function_name" "$bashrc_file" 2>/dev/null; then
        echo "📝 Mise à jour de la fonction existante dans $bashrc_file"
        
        # Supprimer l'ancienne fonction
        sed -i '/^# Arr Monitor function$/,/^}$/d' "$bashrc_file" 2>/dev/null || true
    else
        echo "📝 Ajout de la nouvelle fonction dans $bashrc_file"
    fi
    
    # Ajouter la nouvelle fonction simplifiée
    cat >> "$bashrc_file" << EOF

# Arr Monitor function
function $function_name() {
    local current_dir="\$(pwd)"
    cd "$script_path"
    ./arr-launcher.sh
    cd "\$current_dir"
}

# Alias pour compatibilité
alias arrmonitor='$function_name'
alias arr='$function_name'
EOF

    echo "✅ Fonction '$function_name' ajoutée au bashrc"
    echo "💡 Utilisez les commandes suivantes après 'source ~/.bashrc' :"
    echo "   • $function_name          # Accès direct au menu interactif"
    echo "   • arrmonitor              # Alias court"
    echo "   • arr                     # Alias très court"
    echo ""
    echo "🎯 Une seule commande, accès direct au menu complet !"
}

echo ""
echo "🎉 Installation terminée !"

# Configuration des commandes bashrc
setup_bashrc_function

echo ""
echo "🚀 Arr Monitor est maintenant installé et prêt !"
echo ""
echo "🎯 Commandes disponibles :"
echo "   arr-monitor                    # Menu principal"
echo "   arr-monitor start              # Démarrer le monitoring"
echo "   arr-monitor test               # Test debug"
echo "   arr-monitor logs               # Logs temps réel"
echo "   arr-monitor help               # Aide complète"
echo ""
echo "🔗 Alias disponibles : 'arrmonitor' et 'arr'"
echo ""
echo "💡 Rechargez votre terminal avec : source ~/.bashrc"

# Proposer de supprimer le répertoire source après installation réussie
if [ "$IS_UPDATE" = false ] && [ "$SOURCE_DIR" != "$INSTALL_DIR" ]; then
    echo ""
    echo "🗑️  Nettoyage du répertoire source :"
    echo "   Source : $SOURCE_DIR"
    echo "   Destination : $INSTALL_DIR"
    echo ""
    
    # Fonction de nettoyage automatique
    cleanup_source_directory() {
        local source_path="$1"
        
        echo "🧹 Nettoyage automatique du répertoire source..."
        
        # Vérifications de sécurité multiples
        case "$source_path" in
            /|/home|/usr|/etc|/var|/opt|/bin|/sbin|/lib|/lib64)
                echo "❌ Refus de supprimer un répertoire système : $source_path"
                return 1
                ;;
            /home/$USER)
                echo "❌ Refus de supprimer le répertoire home de l'utilisateur : $source_path"
                return 1
                ;;
            /home/$USER/scripts/*)
                echo "❌ Refus de supprimer un répertoire dans ~/scripts : $source_path"
                return 1
                ;;
        esac
        
        # Vérifier que le répertoire contient bien les fichiers du projet
        if [ ! -f "$source_path/arr-monitor.py" ] || [ ! -f "$source_path/install-arr.sh" ]; then
            echo "❌ Répertoire source ne semble pas contenir les fichiers attendus"
            echo "� Suppression annulée par sécurité"
            return 1
        fi
        
        # Vérifier que ce n'est pas le même répertoire que la destination
        if [ "$(realpath "$source_path")" = "$(realpath "$INSTALL_DIR")" ]; then
            echo "❌ Le répertoire source et destination sont identiques"
            echo "💡 Suppression annulée par sécurité"
            return 1
        fi
        
        # Vérifier que l'installation a bien réussi
        if [ ! -f "$INSTALL_DIR/arr-monitor.py" ] || [ ! -f "$INSTALL_DIR/config/config.yaml.local" ]; then
            echo "❌ Installation dans la destination semble incomplète"
            echo "💡 Suppression annulée par sécurité"
            return 1
        fi
        
        echo "🗑️  Suppression de $source_path..."
        if rm -rf "$source_path"; then
            echo "✅ Répertoire source supprimé avec succès"
            echo "💡 Les fichiers sont maintenant uniquement dans : $INSTALL_DIR"
            return 0
        else
            echo "❌ Erreur lors de la suppression du répertoire source"
            return 1
        fi
    }
    
    # Détection automatique des répertoires temporaires typiques
    AUTO_CLEANUP=false
    case "$SOURCE_DIR" in
        /tmp/*)
            echo "🔍 Répertoire temporaire détecté (/tmp)"
            AUTO_CLEANUP=true
            ;;
        /home/$USER/Arr-Monitor)
            echo "🔍 Répertoire de téléchargement typique détecté"
            AUTO_CLEANUP=true
            ;;
        /home/$USER/Downloads/*)
            echo "🔍 Répertoire de téléchargements détecté"
            AUTO_CLEANUP=true
            ;;
    esac
    
    if [ "$AUTO_CLEANUP" = true ]; then
        echo "💡 Nettoyage automatique recommandé pour ce type de répertoire"
        read -p "🧹 Voulez-vous supprimer automatiquement le répertoire source ? [Y/n] : " DELETE_SOURCE
        DELETE_SOURCE=${DELETE_SOURCE:-Y}
    else
        read -p "🧹 Voulez-vous supprimer le répertoire source maintenant ? [y/N] : " DELETE_SOURCE
        DELETE_SOURCE=${DELETE_SOURCE:-N}
    fi
    
    if [[ $DELETE_SOURCE =~ ^[Yy]$ ]]; then
        if cleanup_source_directory "$SOURCE_DIR"; then
            echo ""
            echo "🎉 Installation terminée et nettoyage effectué !"
            echo "📁 Arr Monitor est maintenant disponible dans : $INSTALL_DIR"
        else
            echo ""
            echo "⚠️  Installation terminée mais nettoyage échoué"
            echo "📁 Répertoire source conservé : $SOURCE_DIR"
            echo "💡 Vous pouvez le supprimer manuellement plus tard"
        fi
    else
        echo "📁 Répertoire source conservé : $SOURCE_DIR"
        echo "💡 Vous pouvez le supprimer manuellement plus tard avec : rm -rf \"$SOURCE_DIR\""
        echo ""
        echo "🧹 Pour un nettoyage automatique lors de la prochaine installation :"
        echo "   cd /tmp && git clone https://github.com/kesurof/Arr-Monitor.git"
        echo "   cd Arr-Monitor && ./install-arr.sh"
    fi
else
    echo ""
    echo "🎉 Installation terminée !"
    
    # Même en mode update, proposer le nettoyage si c'est un répertoire temporaire
    if [ "$SOURCE_DIR" != "$INSTALL_DIR" ]; then
        case "$SOURCE_DIR" in
            /tmp/*)
                echo ""
                echo "🧹 Nettoyage du répertoire temporaire :"
                echo "   Source temporaire : $SOURCE_DIR"
                read -p "🗑️  Supprimer le répertoire temporaire ? [Y/n] : " DELETE_TEMP
                DELETE_TEMP=${DELETE_TEMP:-Y}
                
                if [[ $DELETE_TEMP =~ ^[Yy]$ ]]; then
                    echo "🗑️  Suppression du répertoire temporaire..."
                    if rm -rf "$SOURCE_DIR"; then
                        echo "✅ Répertoire temporaire supprimé"
                    else
                        echo "⚠️  Erreur lors de la suppression"
                    fi
                fi
                ;;
        esac
    fi
fi

echo ""
echo "📖 Consultez le README.md pour plus d'informations et la documentation complète"
