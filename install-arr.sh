#!/bin/bash

# Script d'installation Arr Monitor (Surveillance Sonarr/Radarr)
set -euo pipefail

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

# Demander l'emplacement pour l'installation
echo ""
read -p "📁 Répertoire d'installation des scripts [/home/$USER/scripts] : " SCRIPTS_DIR
SCRIPTS_DIR=${SCRIPTS_DIR:-/home/$USER/scripts}

# Répertoire d'installation final
INSTALL_DIR="$SCRIPTS_DIR/Arr-Monitor"
echo "📁 Installation dans : $INSTALL_DIR"

# Déterminer le répertoire source AVANT de changer de répertoire
SOURCE_DIR="$(dirname "$0")"
SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
echo "📋 Répertoire source : $SOURCE_DIR"

# Vérification des fichiers requis dans le répertoire source
REQUIRED_FILES=("arr-monitor.py" "requirements.txt" "config.yaml")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SOURCE_DIR/$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    echo "❌ Fichiers manquants dans $SOURCE_DIR :"
    printf "   - %s\n" "${MISSING_FILES[@]}"
    echo ""
    echo "💡 Assurez-vous d'exécuter ce script depuis le répertoire contenant les fichiers du projet."
    echo "   Exemple : cd /path/to/Arr-Monitor && ./install-arr.sh"
    exit 1
fi

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

# Création de l'environnement virtuel
echo "🐍 Création de l'environnement virtuel Python..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activation de l'environnement virtuel
echo "⚡ Activation de l'environnement virtuel..."
source venv/bin/activate

# Installation des dépendances
echo "📦 Installation des dépendances Python..."
pip install --upgrade pip
pip install -r requirements.txt

# Création des répertoires
echo "📁 Création des répertoires..."
mkdir -p logs

# Configuration
if [ ! -f "config/config.yaml.local" ]; then
    echo "⚙️  Création de la configuration locale..."
    cp config/config.yaml config/config.yaml.local
    CONFIG_CREATED=true
else
    echo "✅ Configuration locale existante trouvée"
    echo "💡 La configuration existante a été préservée"
    CONFIG_CREATED=false
fi

# Fonction de détection automatique des conteneurs
detect_containers() {
    echo "🔍 Détection automatique des conteneurs..."
    
    # Détection Sonarr
    SONARR_DETECTED=""
    SONARR_PORT=""
    if command -v docker &> /dev/null; then
        # Recherche conteneur Sonarr
        SONARR_CONTAINER=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -i sonarr | head -1)
        if [ -n "$SONARR_CONTAINER" ]; then
            SONARR_NAME=$(echo "$SONARR_CONTAINER" | awk '{print $1}')
            SONARR_PORT=$(echo "$SONARR_CONTAINER" | grep -o '0.0.0.0:[0-9]*->8989' | cut -d':' -f2 | cut -d'-' -f1)
            if [ -n "$SONARR_PORT" ]; then
                SONARR_DETECTED="http://localhost:$SONARR_PORT"
                echo "  ✅ Sonarr détecté: $SONARR_NAME -> $SONARR_DETECTED"
            fi
        fi
    fi
    
    # Détection Radarr
    RADARR_DETECTED=""
    RADARR_PORT=""
    if command -v docker &> /dev/null; then
        # Recherche conteneur Radarr
        RADARR_CONTAINER=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -i radarr | head -1)
        if [ -n "$RADARR_CONTAINER" ]; then
            RADARR_NAME=$(echo "$RADARR_CONTAINER" | awk '{print $1}')
            RADARR_PORT=$(echo "$RADARR_CONTAINER" | grep -o '0.0.0.0:[0-9]*->7878' | cut -d':' -f2 | cut -d'-' -f1)
            if [ -n "$RADARR_PORT" ]; then
                RADARR_DETECTED="http://localhost:$RADARR_PORT"
                echo "  ✅ Radarr détecté: $RADARR_NAME -> $RADARR_DETECTED"
            fi
        fi
    fi
    
    # Vérification des processus locaux si Docker ne trouve rien
    if [ -z "$SONARR_DETECTED" ] && netstat -tlnp 2>/dev/null | grep -q ":8989 "; then
        SONARR_DETECTED="http://localhost:8989"
        echo "  ✅ Sonarr détecté (processus local): $SONARR_DETECTED"
    fi
    
    if [ -z "$RADARR_DETECTED" ] && netstat -tlnp 2>/dev/null | grep -q ":7878 "; then
        RADARR_DETECTED="http://localhost:7878"
        echo "  ✅ Radarr détecté (processus local): $RADARR_DETECTED"
    fi
    
    if [ -z "$SONARR_DETECTED" ] && [ -z "$RADARR_DETECTED" ]; then
        echo "  ⚠️  Aucun conteneur Sonarr/Radarr détecté automatiquement"
    fi
}

# Fonction pour détecter les clés API
detect_api_keys() {
    echo "🔑 Recherche des clés API..."
    
    # Recherche clé API Sonarr
    SONARR_API_DETECTED=""
    if command -v docker &> /dev/null; then
        SONARR_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i sonarr | head -1)
        if [ -n "$SONARR_CONTAINER" ]; then
            # Tente de récupérer la clé API depuis le conteneur
            SONARR_API_DETECTED=$(docker exec "$SONARR_CONTAINER" cat /config/config.xml 2>/dev/null | grep -o '<ApiKey>[^<]*</ApiKey>' | sed 's/<[^>]*>//g' | head -1)
            if [ -n "$SONARR_API_DETECTED" ]; then
                echo "  🔑 Clé API Sonarr détectée: ${SONARR_API_DETECTED:0:8}..."
            fi
        fi
    fi
    
    # Recherche clé API Radarr
    RADARR_API_DETECTED=""
    if command -v docker &> /dev/null; then
        RADARR_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i radarr | head -1)
        if [ -n "$RADARR_CONTAINER" ]; then
            # Tente de récupérer la clé API depuis le conteneur
            RADARR_API_DETECTED=$(docker exec "$RADARR_CONTAINER" cat /config/config.xml 2>/dev/null | grep -o '<ApiKey>[^<]*</ApiKey>' | sed 's/<[^>]*>//g' | head -1)
            if [ -n "$RADARR_API_DETECTED" ]; then
                echo "  🔑 Clé API Radarr détectée: ${RADARR_API_DETECTED:0:8}..."
            fi
        fi
    fi
    
    # Recherche dans les fichiers locaux communs
    if [ -z "$SONARR_API_DETECTED" ]; then
        for config_path in "/home/$USER/.config/Sonarr/config.xml" "/opt/Sonarr/config.xml" "/var/lib/sonarr/config.xml"; do
            if [ -f "$config_path" ]; then
                SONARR_API_DETECTED=$(grep -o '<ApiKey>[^<]*</ApiKey>' "$config_path" 2>/dev/null | sed 's/<[^>]*>//g' | head -1)
                if [ -n "$SONARR_API_DETECTED" ]; then
                    echo "  🔑 Clé API Sonarr trouvée dans $config_path"
                    break
                fi
            fi
        done
    fi
    
    if [ -z "$RADARR_API_DETECTED" ]; then
        for config_path in "/home/$USER/.config/Radarr/config.xml" "/opt/Radarr/config.xml" "/var/lib/radarr/config.xml"; do
            if [ -f "$config_path" ]; then
                RADARR_API_DETECTED=$(grep -o '<ApiKey>[^<]*</ApiKey>' "$config_path" 2>/dev/null | sed 's/<[^>]*>//g' | head -1)
                if [ -n "$RADARR_API_DETECTED" ]; then
                    echo "  🔑 Clé API Radarr trouvée dans $config_path"
                    break
                fi
            fi
        done
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
            read -p "📺 Clé API Sonarr [Détectée: ${SONARR_API_DETECTED:0:8}...] : " SONARR_API
            SONARR_API=${SONARR_API:-$SONARR_API_DETECTED}
        else
            read -p "📺 Clé API Sonarr : " SONARR_API
        fi
        
        # Test de connexion Sonarr
        if [ -n "$SONARR_API" ]; then
            echo "🧪 Test de connexion Sonarr..."
            if curl -s -H "X-Api-Key: $SONARR_API" "$SONARR_URL/api/v3/system/status" > /dev/null; then
                echo "✅ Sonarr connecté avec succès"
            else
                echo "⚠️  Impossible de se connecter à Sonarr (vérifiez l'URL et la clé API)"
            fi
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
            read -p "🎬 Clé API Radarr [Détectée: ${RADARR_API_DETECTED:0:8}...] : " RADARR_API
            RADARR_API=${RADARR_API:-$RADARR_API_DETECTED}
        else
            read -p "🎬 Clé API Radarr : " RADARR_API
        fi
        
        # Test de connexion Radarr
        if [ -n "$RADARR_API" ]; then
            echo "🧪 Test de connexion Radarr..."
            if curl -s -H "X-Api-Key: $RADARR_API" "$RADARR_URL/api/v3/system/status" > /dev/null; then
                echo "✅ Radarr connecté avec succès"
            else
                echo "⚠️  Impossible de se connecter à Radarr (vérifiez l'URL et la clé API)"
            fi
        fi
    fi
    
    # Configuration des actions automatiques
    echo ""
    read -p "🔄 Activer les actions automatiques (relance/suppression) ? [Y/n] : " AUTO_ACTIONS
    AUTO_ACTIONS=${AUTO_ACTIONS:-Y}
    
    # Mise à jour du fichier de configuration
    echo "📝 Mise à jour de la configuration..."
    
    if [[ $ENABLE_SONARR =~ ^[Yy]$ ]]; then
        sed -i.bak "s|url: \"http://localhost:8989\"|url: \"$SONARR_URL\"|" config/config.yaml.local
        sed -i.bak2 "s|api_key: \"your_sonarr_api_key\"|api_key: \"$SONARR_API\"|" config/config.yaml.local
    else
        sed -i.bak "s|enabled: true|enabled: false|" config/config.yaml.local
    fi
    
    if [[ $ENABLE_RADARR =~ ^[Yy]$ ]]; then
        sed -i.bak3 "s|url: \"http://localhost:7878\"|url: \"$RADARR_URL\"|" config/config.yaml.local
        sed -i.bak4 "s|api_key: \"your_radarr_api_key\"|api_key: \"$RADARR_API\"|" config/config.yaml.local
    else
        sed -i.bak3 "/radarr:/,/check_stuck:/ s|enabled: true|enabled: false|" config/config.yaml.local
    fi
    
    if [[ $AUTO_ACTIONS =~ ^[Nn]$ ]]; then
        sed -i.bak5 "s|auto_retry: true|auto_retry: false|" config/config.yaml.local
    fi
    
    rm -f config/config.yaml.local.bak*
    
    echo "✅ Configuration créée dans config/config.yaml.local"
else
    echo "✅ Configuration locale existante préservée"
    echo "💡 Pour reconfigurer, supprimez config/config.yaml.local et relancez l'installation"
fi

# Test de l'installation
echo ""
echo "🧪 Test de l'installation..."
if python arr-monitor.py --test --config config/config.yaml.local; then
    echo "✅ Test réussi !"
else
    echo "⚠️  Test échoué, mais l'installation est terminée"
    echo "💡 Vérifiez la configuration dans config/config.yaml.local"
fi

echo ""
if [ "$IS_UPDATE" = true ]; then
    echo "✅ Mise à jour terminée avec succès !"
    echo "💡 Votre configuration existante a été préservée"
else
    echo "✅ Installation terminée avec succès !"
fi
echo ""
echo "📋 Utilisation :"
echo "   cd $INSTALL_DIR"
echo "   source venv/bin/activate"
echo "   python arr-monitor.py --config config/config.yaml.local"
echo ""
echo "📋 Commandes utiles :"
echo "   # Test unique"
echo "   python arr-monitor.py --test --config config/config.yaml.local"
echo ""
echo "   # Mode debug"
echo "   python arr-monitor.py --debug --config config/config.yaml.local"
echo ""
echo "   # Simulation sans actions"
echo "   python arr-monitor.py --dry-run --config config/config.yaml.local"
echo ""
echo "   # Voir les logs"
echo "   tail -f logs/arr-monitor.log"
echo ""
echo "📁 Configuration : $INSTALL_DIR/config/config.yaml.local"
echo "📝 Logs : $INSTALL_DIR/logs/arr-monitor.log"
echo ""
echo "🔧 Pour créer un service système (optionnel) :"
echo ""
read -p "🛠️  Voulez-vous installer le service systemd ? [y/N] : " INSTALL_SERVICE
INSTALL_SERVICE=${INSTALL_SERVICE:-N}

if [[ $INSTALL_SERVICE =~ ^[Yy]$ ]]; then
    if [ -f "$SOURCE_DIR/arr-monitor.service" ]; then
        echo "📋 Installation du service systemd..."
        
        # Copie et modification du fichier service
        cp "$SOURCE_DIR/arr-monitor.service" arr-monitor.service.tmp
        sed -i.bak "s|%USER%|$USER|g" arr-monitor.service.tmp
        sed -i.bak2 "s|%INSTALL_DIR%|$INSTALL_DIR|g" arr-monitor.service.tmp
        
        # Installation du service
        sudo cp arr-monitor.service.tmp /etc/systemd/system/arr-monitor.service
        sudo systemctl daemon-reload
        sudo systemctl enable arr-monitor
        
        # Nettoyer les fichiers temporaires
        rm -f arr-monitor.service.tmp*
        
        echo "✅ Service systemd installé et activé"
        echo "   sudo systemctl start arr-monitor    # Démarrer"
        echo "   sudo systemctl status arr-monitor   # Vérifier le statut"
        echo "   sudo journalctl -u arr-monitor -f   # Voir les logs"
    else
        echo "⚠️  Fichier service non trouvé : $SOURCE_DIR/arr-monitor.service"
    fi
else
    echo "📋 Instructions pour installation manuelle du service :"
    echo "   # Créer le fichier service"
    echo "   sudo tee /etc/systemd/system/arr-monitor.service > /dev/null <<EOF"
    echo "[Unit]"
    echo "Description=Arr Monitor - Surveillance Sonarr/Radarr"
    echo "After=network.target"
    echo ""
    echo "[Service]"
    echo "Type=simple"
    echo "User=$USER"
    echo "WorkingDirectory=$INSTALL_DIR"
    echo "ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/arr-monitor.py --config $INSTALL_DIR/config/config.yaml.local"
    echo "Restart=always"
    echo "RestartSec=30"
    echo ""
    echo "[Install]"
    echo "WantedBy=multi-user.target"
    echo "EOF"
    echo ""
    echo "   # Activer et démarrer le service"
    echo "   sudo systemctl daemon-reload"
    echo "   sudo systemctl enable arr-monitor"
    echo "   sudo systemctl start arr-monitor"
    echo "   sudo systemctl status arr-monitor"
fi
