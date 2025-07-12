#!/bin/bash

# Script d'installation Arr Monitor (Surveillance Sonarr/Radarr)
set -euo pipefail

# Gestion des paramètres
FORCE_INSTALL=false
for arg in "$@"; do
    case $arg in
        --update)
            FORCE_INSTALL=true
            shift
            ;;
        *)
            ;;
    esac
done

echo "🚀 Installation Arr Monitor - Surveillance Sonarr/Radarr"
echo ""
echo "📂 Ce script va :"
echo "   • Copier les fichiers depuis le répertoire courant"
echo "   • Les installer dans un répertoire de destination"
echo "   • Créer un environnement Python virtuel"
echo "   • Configurer l'application de manière interactive"
echo ""
echo "💡 Utilisation typique :"
echo "   git clone https://github.com/kesurof/Arr-Monitor.git"
echo "   cd Arr-Monitor"
echo "   ./install-arr.sh"
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
if [ "$FORCE_INSTALL" = true ]; then
    # Mode non-interactif pour --update
    SCRIPTS_DIR="/home/$USER/scripts"
    echo "📁 Mode mise à jour : utilisation du répertoire par défaut"
else
    read -p "📁 Répertoire d'installation des scripts [/home/$USER/scripts] : " SCRIPTS_DIR
fi
SCRIPTS_DIR=${SCRIPTS_DIR:-/home/$USER/scripts}

# Répertoire d'installation final
INSTALL_DIR="$SCRIPTS_DIR/Arr-Monitor"
echo "📁 Installation dans : $INSTALL_DIR"

# Création du répertoire d'installation
IS_UPDATE=false
if [ -d "$INSTALL_DIR" ]; then
    echo "📂 Installation existante détectée. Mode mise à jour activé."
    IS_UPDATE=true
    
    # Sauvegarde de la configuration existante si elle existe
    if [ -f "$INSTALL_DIR/config/config.yaml.local" ]; then
        BACKUP_FILE="$INSTALL_DIR/config/config.yaml.local.backup.$(date +%Y%m%d_%H%M%S)"
        echo "💾 Sauvegarde de la configuration : $(basename "$BACKUP_FILE")"
        cp "$INSTALL_DIR/config/config.yaml.local" "$BACKUP_FILE"
    fi
else
    echo "📥 Nouvelle installation..."
    mkdir -p "$INSTALL_DIR"
fi

# Maintenant on peut changer de répertoire
cd "$INSTALL_DIR"

# Copie des fichiers depuis le répertoire source
echo "📋 Copie des fichiers depuis $SOURCE_DIR vers $INSTALL_DIR..."
cp "$SOURCE_DIR/arr-monitor.py" ./
cp "$SOURCE_DIR/requirements.txt" ./

# Création du répertoire config et copie
mkdir -p config
cp "$SOURCE_DIR/config.yaml" config/

# Copier le fichier service pour installation
if [ -f "$SOURCE_DIR/arr-monitor.service" ]; then
    cp "$SOURCE_DIR/arr-monitor.service" arr-monitor.service.tmp
fi

echo "✅ Fichiers copiés avec succès"

# Application automatique de la correction du bug get_queue si nécessaire
echo "🔧 Vérification et correction du code Python..."
if grep -q "return response\.json()" arr-monitor.py && ! grep -q "isinstance(data, list)" arr-monitor.py; then
    echo "📝 Application de la correction pour le traitement des queues API..."
    
    # Créer une sauvegarde
    cp arr-monitor.py "arr-monitor.py.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Appliquer la correction avec sed
    sed -i.tmp 's/return response\.json()/data = response.json()\
                # L'\''API peut retourner une liste directement ou un objet avec '\''records'\''\
                if isinstance(data, list):\
                    return data\
                elif isinstance(data, dict) and '\''records'\'' in data:\
                    return data['\''records'\'']\
                else:\
                    # Si c'\''est un autre format, on retourne une liste vide\
                    self.logger.warning(f"⚠️  {app_name} format de queue inattendu : {type(data)}")\
                    return []/' arr-monitor.py
    
    # Nettoyer le fichier temporaire
    rm -f arr-monitor.py.tmp
    
    echo "✅ Correction appliquée avec succès"
else
    echo "✅ Code déjà corrigé ou à jour"
fi

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
if [ ! -f "config/config.yaml.local" ]; then
    cp config/config.yaml config/config.yaml.local
    CONFIG_CREATED=true
else
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
    echo "📋 Configuration des applications :"
    
    # Détection automatique
    detect_containers
    detect_api_keys
    
    # Configuration Sonarr
    echo ""
    read -p "📺 Activer Sonarr ? [Y/n] : " ENABLE_SONARR
    ENABLE_SONARR=${ENABLE_SONARR:-Y}
    
    if [[ $ENABLE_SONARR =~ ^[Yy]$ ]]; then
        DEFAULT_SONARR_URL=${SONARR_DETECTED:-http://localhost:8989}
        read -p "📺 URL Sonarr [$DEFAULT_SONARR_URL] : " SONARR_URL
        SONARR_URL=${SONARR_URL:-$DEFAULT_SONARR_URL}
        
        if [ -n "$SONARR_API_DETECTED" ]; then
            read -p "🔑 Clé API Sonarr [détectée automatiquement] : " SONARR_API
            SONARR_API=${SONARR_API:-$SONARR_API_DETECTED}
        else
            read -p "🔑 Clé API Sonarr : " SONARR_API
        fi
        
        # Test de connexion
        echo "🧪 Test de connexion Sonarr..."
        if python -c "
import requests
try:
    response = requests.get('$SONARR_URL/api/v3/system/status', headers={'X-Api-Key': '$SONARR_API'}, timeout=5)
    if response.status_code == 200:
        print('✅ Connexion Sonarr réussie')
        exit(0)
    else:
        print('⚠️  Réponse inattendue de Sonarr (code: {})'.format(response.status_code))
        exit(1)
except Exception as e:
    print('⚠️  Impossible de se connecter à Sonarr (vérifiez l'\''URL et la clé API)')
    exit(1)
" 2>/dev/null; then
            :
        else
            :
        fi
    fi
    
    # Configuration Radarr
    echo ""
    read -p "🎬 Activer Radarr ? [Y/n] : " ENABLE_RADARR
    ENABLE_RADARR=${ENABLE_RADARR:-Y}
    
    if [[ $ENABLE_RADARR =~ ^[Yy]$ ]]; then
        DEFAULT_RADARR_URL=${RADARR_DETECTED:-http://localhost:7878}
        read -p "🎬 URL Radarr [$DEFAULT_RADARR_URL] : " RADARR_URL
        RADARR_URL=${RADARR_URL:-$DEFAULT_RADARR_URL}
        
        if [ -n "$RADARR_API_DETECTED" ]; then
            read -p "🔑 Clé API Radarr [détectée automatiquement] : " RADARR_API
            RADARR_API=${RADARR_API:-$RADARR_API_DETECTED}
        else
            read -p "🔑 Clé API Radarr : " RADARR_API
        fi
        
        # Test de connexion
        echo "🧪 Test de connexion Radarr..."
        if python -c "
import requests
try:
    response = requests.get('$RADARR_URL/api/v3/system/status', headers={'X-Api-Key': '$RADARR_API'}, timeout=5)
    if response.status_code == 200:
        print('✅ Connexion Radarr réussie')
        exit(0)
    else:
        print('⚠️  Réponse inattendue de Radarr (code: {})'.format(response.status_code))
        exit(1)
except Exception as e:
    print('⚠️  Impossible de se connecter à Radarr (vérifiez l'\''URL et la clé API)')
    exit(1)
" 2>/dev/null; then
            :
        else
            :
        fi
    fi
    
    # Configuration des actions automatiques
    echo ""
    read -p "🤖 Activer les actions automatiques (relance/suppression) ? [Y/n] : " AUTO_ACTIONS
    AUTO_ACTIONS=${AUTO_ACTIONS:-Y}
    
    # Mise à jour du fichier de configuration
    echo "📝 Mise à jour de la configuration..."
    
    if [[ $ENABLE_SONARR =~ ^[Yy]$ ]]; then
        sed -i.bak1 "s|url: \"http://localhost:8989\"|url: \"$SONARR_URL\"|" config/config.yaml.local
        sed -i.bak2 "s|api_key: \"your_sonarr_api_key\"|api_key: \"$SONARR_API\"|" config/config.yaml.local
    else
        sed -i.bak1 "/sonarr:/,/radarr:/ s|enabled: true|enabled: false|" config/config.yaml.local
    fi
    
    if [[ $ENABLE_RADARR =~ ^[Yy]$ ]]; then
        sed -i.bak3 "s|url: \"http://localhost:7878\"|url: \"$RADARR_URL\"|" config/config.yaml.local
        sed -i.bak4 "s|api_key: \"your_radarr_api_key\"|api_key: \"$RADARR_API\"|" config/config.yaml.local
    else
        sed -i.bak3 "/radarr:/,/monitoring:/ s|enabled: true|enabled: false|" config/config.yaml.local
    fi
    
    if [[ $AUTO_ACTIONS =~ ^[Nn]$ ]]; then
        sed -i.bak5 "s|auto_retry: true|auto_retry: false|" config/config.yaml.local
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
echo "🔧 Pour créer un service système (optionnel) :"
echo ""
if [ "$FORCE_INSTALL" = true ]; then
    # Mode non-interactif pour --update - ne pas installer le service automatiquement
    INSTALL_SERVICE="N"
    echo "📋 Mode mise à jour : service systemd non modifié"
else
    read -p "🛠️  Voulez-vous installer le service systemd ? [y/N] : " INSTALL_SERVICE
fi
INSTALL_SERVICE=${INSTALL_SERVICE:-N}

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
        
        # Nettoyer les fichiers temporaires
        rm -f arr-monitor.service.final*
        rm -f arr-monitor.service.tmp
        
        echo "✅ Service systemd installé et activé"
        echo "   sudo systemctl start arr-monitor    # Démarrer"
        echo "   sudo systemctl status arr-monitor   # Vérifier le statut"
        echo "   sudo journalctl -u arr-monitor -f   # Voir les logs"
        
        # Test du service
        echo ""
        echo "🧪 Test du service systemd..."
        if sudo systemctl start arr-monitor && sleep 2 && sudo systemctl is-active --quiet arr-monitor; then
            echo "✅ Service démarré avec succès"
        else
            echo "⚠️  Problème de démarrage du service"
            echo "📋 Vérification des logs :"
            sudo journalctl -u arr-monitor -n 10 --no-pager
        fi
    else
        echo "⚠️  Fichier service non disponible"
        echo "💡 Vous pouvez créer le service manuellement avec les instructions ci-dessous"
    fi
else
    echo "📋 Service systemd non installé"
    echo ""
    echo "💡 Pour installer le service plus tard :"
    echo "   cd $INSTALL_DIR"
    echo "   sudo cp arr-monitor.service /etc/systemd/system/"
    echo "   sudo sed -i 's/%USER%/$USER/g' /etc/systemd/system/arr-monitor.service"
    echo "   sudo sed -i 's|%INSTALL_DIR%|$INSTALL_DIR|g' /etc/systemd/system/arr-monitor.service"
    echo "   sudo systemctl daemon-reload"
    echo "   sudo systemctl enable arr-monitor"
    echo "   sudo systemctl start arr-monitor"
fi

echo ""
echo "🎉 Installation terminée !"
echo ""
echo "📖 Consultez le README.md pour plus d'informations et la documentation complète"
