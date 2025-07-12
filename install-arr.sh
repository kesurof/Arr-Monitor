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
    
    # Variables globales pour la détection
    SONARR_DETECTED=""
    RADARR_DETECTED=""
    
    if command -v docker &> /dev/null && docker ps &> /dev/null; then
        # Recherche conteneur Sonarr
        SONARR_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -i sonarr)
        if [ -n "$SONARR_CONTAINERS" ]; then
            while read -r container; do
                if [ -n "$container" ]; then
                    # Méthode 1: Récupération IP du conteneur (réseau traefik_proxy)
                    SONARR_IP=$(docker inspect "$container" --format='{{.NetworkSettings.Networks.traefik_proxy.IPAddress}}' 2>/dev/null)
                    if [ -n "$SONARR_IP" ] && [ "$SONARR_IP" != "<no value>" ]; then
                        SONARR_DETECTED="http://$SONARR_IP:8989"
                        echo "  ✅ Sonarr détecté via IP container: $container -> $SONARR_DETECTED"
                        break
                    fi
                    
                    # Méthode 2: Récupération IP du réseau par défaut
                    if [ -z "$SONARR_IP" ]; then
                        SONARR_IP=$(docker inspect "$container" --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
                        if [ -n "$SONARR_IP" ] && [ "$SONARR_IP" != "<no value>" ]; then
                            SONARR_DETECTED="http://$SONARR_IP:8989"
                            echo "  ✅ Sonarr détecté via IP réseau: $container -> $SONARR_DETECTED"
                            break
                        fi
                    fi
                    
                    # Méthode 3: Port mapping (fallback)
                    if [ -z "$SONARR_DETECTED" ]; then
                        SONARR_PORT=$(docker port "$container" 8989/tcp 2>/dev/null | cut -d':' -f2)
                        if [ -n "$SONARR_PORT" ]; then
                            SONARR_DETECTED="http://localhost:$SONARR_PORT"
                            echo "  ✅ Sonarr détecté via port mapping: $container -> $SONARR_DETECTED"
                            break
                        fi
                    fi
                fi
            done <<< "$SONARR_CONTAINERS"
        fi
        
        # Recherche conteneur Radarr (même logique)
        RADARR_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -i radarr)
        if [ -n "$RADARR_CONTAINERS" ]; then
            while read -r container; do
                if [ -n "$container" ]; then
                    # Méthode 1: Récupération IP du conteneur (réseau traefik_proxy)
                    RADARR_IP=$(docker inspect "$container" --format='{{.NetworkSettings.Networks.traefik_proxy.IPAddress}}' 2>/dev/null)
                    if [ -n "$RADARR_IP" ] && [ "$RADARR_IP" != "<no value>" ]; then
                        RADARR_DETECTED="http://$RADARR_IP:7878"
                        echo "  ✅ Radarr détecté via IP container: $container -> $RADARR_DETECTED"
                        break
                    fi
                    
                    # Méthode 2: Récupération IP du réseau par défaut
                    if [ -z "$RADARR_IP" ]; then
                        RADARR_IP=$(docker inspect "$container" --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
                        if [ -n "$RADARR_IP" ] && [ "$RADARR_IP" != "<no value>" ]; then
                            RADARR_DETECTED="http://$RADARR_IP:7878"
                            echo "  ✅ Radarr détecté via IP réseau: $container -> $RADARR_DETECTED"
                            break
                        fi
                    fi
                    
                    # Méthode 3: Port mapping (fallback)
                    if [ -z "$RADARR_DETECTED" ]; then
                        RADARR_PORT=$(docker port "$container" 7878/tcp 2>/dev/null | cut -d':' -f2)
                        if [ -n "$RADARR_PORT" ]; then
                            RADARR_DETECTED="http://localhost:$RADARR_PORT"
                            echo "  ✅ Radarr détecté via port mapping: $container -> $RADARR_DETECTED"
                            break
                        fi
                    fi
                fi
            done <<< "$RADARR_CONTAINERS"
        fi
    fi
    
    # Vérification des processus locaux si Docker ne trouve rien
    if [ -z "$SONARR_DETECTED" ]; then
        if command -v netstat &> /dev/null && netstat -tlnp 2>/dev/null | grep -q ":8989 "; then
            SONARR_DETECTED="http://localhost:8989"
            echo "  ✅ Sonarr détecté (processus local): $SONARR_DETECTED"
        elif command -v ss &> /dev/null && ss -tlnp 2>/dev/null | grep -q ":8989 "; then
            SONARR_DETECTED="http://localhost:8989"
            echo "  ✅ Sonarr détecté (processus local via ss): $SONARR_DETECTED"
        fi
    fi
    
    if [ -z "$RADARR_DETECTED" ]; then
        if command -v netstat &> /dev/null && netstat -tlnp 2>/dev/null | grep -q ":7878 "; then
            RADARR_DETECTED="http://localhost:7878"
            echo "  ✅ Radarr détecté (processus local): $RADARR_DETECTED"
        elif command -v ss &> /dev/null && ss -tlnp 2>/dev/null | grep -q ":7878 "; then
            RADARR_DETECTED="http://localhost:7878"
            echo "  ✅ Radarr détecté (processus local via ss): $RADARR_DETECTED"
        fi
    fi
    
    if [ -z "$SONARR_DETECTED" ] && [ -z "$RADARR_DETECTED" ]; then
        echo "  ⚠️  Aucun conteneur/processus Sonarr/Radarr détecté automatiquement"
        echo "  💡 Vérifiez que vos services sont démarrés et accessibles"
    fi
}

# Fonction pour détecter les clés API
detect_api_keys() {
    echo "🔑 Recherche des clés API..."
    
    # Variables globales pour la détection
    SONARR_API_DETECTED=""
    RADARR_API_DETECTED=""
    
    # Recherche clé API Sonarr
    if command -v docker &> /dev/null && docker ps &> /dev/null; then
        SONARR_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -i sonarr)
        if [ -n "$SONARR_CONTAINERS" ]; then
            while read -r container; do
                if [ -n "$container" ]; then
                    # Méthode 1: Via chemin SETTINGS_STORAGE (comme dans votre code)
                    SETTINGS_STORAGE=${SETTINGS_STORAGE:-/opt/seedbox/docker}
                    CURRENT_USER=${USER:-kesurof}
                    CONFIG_PATH="$SETTINGS_STORAGE/docker/$CURRENT_USER/sonarr/config/config.xml"
                    
                    if [ -f "$CONFIG_PATH" ] && [ -r "$CONFIG_PATH" ]; then
                        SONARR_API_DETECTED=$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' "$CONFIG_PATH" 2>/dev/null | head -1)
                        if [ -n "$SONARR_API_DETECTED" ]; then
                            echo "  🔑 Clé API Sonarr trouvée via SETTINGS_STORAGE: ${SONARR_API_DETECTED:0:8}..."
                            break
                        fi
                    fi
                    
                    # Méthode 2: Via conteneur Docker (chemins standards)
                    if [ -z "$SONARR_API_DETECTED" ]; then
                        SONARR_API_DETECTED=$(docker exec "$container" sh -c 'cat /config/config.xml 2>/dev/null || cat /app/config.xml 2>/dev/null || cat /data/config.xml 2>/dev/null' | sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' | head -1 2>/dev/null)
                        if [ -n "$SONARR_API_DETECTED" ]; then
                            echo "  🔑 Clé API Sonarr détectée depuis conteneur $container: ${SONARR_API_DETECTED:0:8}..."
                            break
                        fi
                    fi
                fi
            done <<< "$SONARR_CONTAINERS"
        fi
    fi
    
    # Recherche clé API Radarr
    if command -v docker &> /dev/null && docker ps &> /dev/null; then
        RADARR_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -i radarr)
        if [ -n "$RADARR_CONTAINERS" ]; then
            while read -r container; do
                if [ -n "$container" ]; then
                    # Méthode 1: Via chemin SETTINGS_STORAGE (comme dans votre code)
                    SETTINGS_STORAGE=${SETTINGS_STORAGE:-/opt/seedbox/docker}
                    CURRENT_USER=${USER:-kesurof}
                    CONFIG_PATH="$SETTINGS_STORAGE/docker/$CURRENT_USER/radarr/config/config.xml"
                    
                    if [ -f "$CONFIG_PATH" ] && [ -r "$CONFIG_PATH" ]; then
                        RADARR_API_DETECTED=$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' "$CONFIG_PATH" 2>/dev/null | head -1)
                        if [ -n "$RADARR_API_DETECTED" ]; then
                            echo "  🔑 Clé API Radarr trouvée via SETTINGS_STORAGE: ${RADARR_API_DETECTED:0:8}..."
                            break
                        fi
                    fi
                    
                    # Méthode 2: Via conteneur Docker (chemins standards)
                    if [ -z "$RADARR_API_DETECTED" ]; then
                        RADARR_API_DETECTED=$(docker exec "$container" sh -c 'cat /config/config.xml 2>/dev/null || cat /app/config.xml 2>/dev/null || cat /data/config.xml 2>/dev/null' | sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' | head -1 2>/dev/null)
                        if [ -n "$RADARR_API_DETECTED" ]; then
                            echo "  🔑 Clé API Radarr détectée depuis conteneur $container: ${RADARR_API_DETECTED:0:8}..."
                            break
                        fi
                    fi
                fi
            done <<< "$RADARR_CONTAINERS"
        fi
    fi
    
    # Recherche dans les fichiers locaux communs (fallback)
    if [ -z "$SONARR_API_DETECTED" ]; then
        for config_path in "/home/$USER/.config/Sonarr/config.xml" "/opt/Sonarr/config.xml" "/var/lib/sonarr/config.xml" "/usr/local/share/sonarr/config.xml"; do
            if [ -f "$config_path" ] && [ -r "$config_path" ]; then
                SONARR_API_DETECTED=$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' "$config_path" 2>/dev/null | head -1)
                if [ -n "$SONARR_API_DETECTED" ]; then
                    echo "  🔑 Clé API Sonarr trouvée dans $config_path: ${SONARR_API_DETECTED:0:8}..."
                    break
                fi
            fi
        done
    fi
    
    if [ -z "$RADARR_API_DETECTED" ]; then
        for config_path in "/home/$USER/.config/Radarr/config.xml" "/opt/Radarr/config.xml" "/var/lib/radarr/config.xml" "/usr/local/share/radarr/config.xml"; do
            if [ -f "$config_path" ] && [ -r "$config_path" ]; then
                RADARR_API_DETECTED=$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' "$config_path" 2>/dev/null | head -1)
                if [ -n "$RADARR_API_DETECTED" ]; then
                    echo "  🔑 Clé API Radarr trouvée dans $config_path: ${RADARR_API_DETECTED:0:8}..."
                    break
                fi
            fi
        done
    fi
    
    if [ -z "$SONARR_API_DETECTED" ] && [ -z "$RADARR_API_DETECTED" ]; then
        echo "  ⚠️  Aucune clé API détectée automatiquement"
        echo "  💡 Les clés API devront être saisies manuellement"
        echo "  💡 Vérifiez les variables d'environnement SETTINGS_STORAGE si vous utilisez une structure personnalisée"
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
    
    # Test automatique après configuration
    echo ""
    echo "🧪 Test automatique de l'installation..."
    if python arr-monitor.py --test --config config/config.yaml.local; then
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
if [ "$FORCE_INSTALL" = true ]; then
    # Mode non-interactif pour --update - ne pas installer le service automatiquement
    INSTALL_SERVICE="N"
    echo "📋 Mode mise à jour : service systemd non modifié"
else
    read -p "🛠️  Voulez-vous installer le service systemd ? [y/N] : " INSTALL_SERVICE
fi
INSTALL_SERVICE=${INSTALL_SERVICE:-N}

if [[ $INSTALL_SERVICE =~ ^[Yy]$ ]]; then
    if [ -f "$SOURCE_DIR/arr-monitor.service" ]; then
        echo "📋 Installation du service systemd..."
        
        # Vérifier que l'environnement virtuel fonctionne
        if ! "$INSTALL_DIR/venv/bin/python" -c "import yaml, requests" &> /dev/null; then
            echo "⚠️  Problème avec l'environnement virtuel, réinstallation des dépendances..."
            source venv/bin/activate
            pip install -r requirements.txt
        fi
        
        # Copie et modification du fichier service avec chemin absolu
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
