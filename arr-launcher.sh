#!/bin/bash
# arr-launcher.sh - Script de lancement unifié Arr Monitor
# Compatible ARM64 et détection automatique des mises à jour

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
VENV_DIR="$SCRIPT_DIR/venv"
VERSION_FILE="$SCRIPT_DIR/.version"
CURRENT_VERSION="1.1.0"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonctions utilitaires
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Détection de l'architecture
detect_architecture() {
    local arch=$(uname -m)
    case $arch in
        aarch64|arm64)
            echo "arm64"
            ;;
        x86_64|amd64)
            echo "amd64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Anonymisation des informations sensibles
anonymize_logs() {
    local log_file="$1"
    if [[ -f "$log_file" ]]; then
        # Remplace les adresses IP privées par des placeholders
        sed -i 's/192\.168\.[0-9]\+\.[0-9]\+/192.168.xxx.xxx/g' "$log_file" 2>/dev/null || true
        sed -i 's/10\.[0-9]\+\.[0-9]\+\.[0-9]\+/10.xxx.xxx.xxx/g' "$log_file" 2>/dev/null || true
        sed -i 's/172\.[0-9]\+\.[0-9]\+\.[0-9]\+/172.xxx.xxx.xxx/g' "$log_file" 2>/dev/null || true
        
        # Remplace les noms d'utilisateur par des placeholders
        sed -i "s/$(whoami)/[USER]/g" "$log_file" 2>/dev/null || true
        
        # Remplace les noms d'hôte par des placeholders
        sed -i "s/$(hostname)/[HOSTNAME]/g" "$log_file" 2>/dev/null || true
    fi
}

# Vérification des prérequis système
check_system_requirements() {
    info "🔍 Vérification des prérequis système..."
    
    # Vérification de l'architecture
    local arch=$(detect_architecture)
    log "Architecture détectée: $arch"
    
    # Vérification Python
    if ! command -v python3 &> /dev/null; then
        error "Python 3 n'est pas installé"
        return 1
    fi
    
    local python_version=$(python3 --version | cut -d' ' -f2)
    log "Python version: $python_version"
    
    # Vérification des dépendances système pour ARM64
    if [[ "$arch" == "arm64" ]]; then
        info "🔧 Optimisations ARM64 activées"
        
        # Vérification des paquets système nécessaires pour ARM64
        local required_packages=("build-essential" "python3-dev" "libffi-dev")
        for package in "${required_packages[@]}"; do
            if ! dpkg -l | grep -q "^ii  $package "; then
                warn "Paquet recommandé manquant pour ARM64: $package"
                info "Installation recommandée: sudo apt install $package"
            fi
        done
    fi
    
    return 0
}

# Configuration de l'environnement virtuel
setup_venv() {
    info "🐍 Configuration de l'environnement virtuel..."
    
    if [[ ! -d "$VENV_DIR" ]]; then
        log "Création de l'environnement virtuel..."
        python3 -m venv "$VENV_DIR"
    fi
    
    source "$VENV_DIR/bin/activate"
    
    # Mise à jour pip pour ARM64
    pip install --upgrade pip
    
    # Installation des dépendances avec optimisation ARM64
    if [[ -f "$SCRIPT_DIR/requirements.txt" ]]; then
        log "Installation des dépendances..."
        pip install -r "$SCRIPT_DIR/requirements.txt"
    fi
    
    log "✅ Environnement virtuel prêt"
}

# Vérification des mises à jour
check_updates() {
    info "🔍 Vérification des mises à jour..."
    
    if [[ -f "$SCRIPT_DIR/update_checker.py" ]]; then
        source "$VENV_DIR/bin/activate"
        python3 "$SCRIPT_DIR/update_checker.py"
    else
        warn "Module de vérification des mises à jour non trouvé"
    fi
}

# Création de la configuration si elle n'existe pas
setup_config() {
    info "⚙️ Vérification de la configuration..."
    
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    
    if [[ ! -f "$CONFIG_DIR/config.yaml" ]]; then
        log "Création de la configuration par défaut..."
        cp "$SCRIPT_DIR/config.yaml" "$CONFIG_DIR/config.yaml" 2>/dev/null || true
    fi
    
    # Création du fichier de version
    echo "$CURRENT_VERSION" > "$VERSION_FILE"
}

# Nettoyage des logs avec anonymisation
cleanup_logs() {
    info "🧹 Nettoyage et anonymisation des logs..."
    
    find "$LOG_DIR" -name "*.log" -type f | while read -r log_file; do
        # Anonymisation des logs
        anonymize_logs "$log_file"
        
        # Rotation des logs > 10MB
        if [[ $(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0) -gt 10485760 ]]; then
            mv "$log_file" "${log_file}.old"
            touch "$log_file"
            log "Rotation du fichier de log: $(basename "$log_file")"
        fi
    done
}

# Configuration de la fonction bashrc
setup_bashrc_integration() {
    info "🔧 Configuration de l'intégration bashrc..."
    
    local bashrc_file="$HOME/.bashrc"
    local function_name="arr-monitor"
    
    # Vérifier si la fonction existe déjà
    if grep -q "function $function_name" "$bashrc_file" 2>/dev/null; then
        log "✅ Fonction bashrc '$function_name' déjà configurée"
        return 0
    fi
    
    echo ""
    echo -e "${CYAN}🎯 Intégration bashrc disponible${NC}"
    echo ""
    echo "Cette option ajoutera une fonction '$function_name' à votre bashrc"
    echo "permettant de lancer Arr Monitor depuis n'importe où avec :"
    echo ""
    echo -e "${GREEN}  $function_name         ${NC}# Menu principal"
    echo -e "${GREEN}  $function_name start   ${NC}# Démarrage monitoring"
    echo -e "${GREEN}  $function_name test    ${NC}# Test debug"
    echo -e "${GREEN}  $function_name logs    ${NC}# Logs temps réel"
    echo ""
    echo -ne "${YELLOW}Voulez-vous configurer cette intégration ? [Y/n]:${NC} "
    read -r configure_bashrc
    configure_bashrc=${configure_bashrc:-Y}
    
    if [[ $configure_bashrc =~ ^[Yy]$ ]]; then
        # Ajouter la fonction au bashrc
        cat >> "$bashrc_file" << EOF

# Arr Monitor function
function $function_name() {
    local current_dir="\$(pwd)"
    cd "$SCRIPT_DIR"
    
    case "\${1:-menu}" in
        "start"|"run")
            echo "🚀 Démarrage Arr Monitor..."
            ./arr-launcher.sh
            ;;
        "test")
            echo "🧪 Test Arr Monitor..."
            source venv/bin/activate
            python3 arr-monitor.py --test --debug
            ;;
        "diagnose")
            echo "🔬 Diagnostic complet..."
            source venv/bin/activate
            python3 arr-monitor.py --diagnose --debug
            ;;
        "config")
            echo "⚙️ Configuration Arr Monitor..."
            if command -v nano &> /dev/null; then
                nano config/config.yaml
            elif command -v vim &> /dev/null; then
                vim config/config.yaml
            else
                echo "Éditez manuellement: $SCRIPT_DIR/config/config.yaml"
            fi
            ;;
        "logs")
            echo "📋 Logs Arr Monitor..."
            if [[ -f "$SCRIPT_DIR/logs/arr-monitor.log" ]]; then
                tail -f "$SCRIPT_DIR/logs/arr-monitor.log"
            else
                echo "❌ Aucun fichier de log trouvé"
            fi
            ;;
        "update")
            echo "🔍 Vérification des mises à jour..."
            source venv/bin/activate
            python3 update_checker.py
            ;;
        "menu")
            echo "🎯 Menu Arr Monitor..."
            ./arr-launcher.sh
            ;;
        "help"|"--help"|"-h")
            echo ""
            echo "🚀 Arr Monitor - Commandes disponibles:"
            echo ""
            echo "  $function_name [commande]"
            echo ""
            echo "Commandes:"
            echo "  start, run    - Démarrer le monitoring (menu interactif)"
            echo "  test          - Exécuter un test unique"
            echo "  diagnose      - Diagnostic complet de la queue"
            echo "  config        - Éditer la configuration"
            echo "  logs          - Voir les logs en temps réel"
            echo "  update        - Vérifier les mises à jour"
            echo "  menu          - Afficher le menu principal (défaut)"
            echo "  help          - Afficher cette aide"
            echo ""
            ;;
        *)
            echo "❌ Commande inconnue: \$1"
            echo "💡 Utilisez '$function_name help' pour voir les commandes disponibles"
            ;;
    esac
    
    cd "\$current_dir"
}

# Alias pour compatibilité
alias arrmonitor='$function_name'
alias arr='$function_name'
EOF
        
        log "✅ Fonction '$function_name' ajoutée au bashrc"
        info "💡 Rechargez votre terminal avec : source ~/.bashrc"
        info "🎯 Puis utilisez : $function_name help"
    else
        info "⏭️ Intégration bashrc ignorée"
    fi
}

# Menu principal
show_menu() {
    clear
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}           🚀 ARR MONITOR LAUNCHER v$CURRENT_VERSION           ${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Architecture:${NC} $(detect_architecture)"
    echo -e "${CYAN}Répertoire:${NC} $SCRIPT_DIR"
    echo ""
    echo -e "${BLUE}1)${NC} 🔄 Lancer Arr Monitor (mode continu)"
    echo -e "${BLUE}2)${NC} 🧪 Test unique (mode debug)"
    echo -e "${BLUE}3)${NC} 🔬 Diagnostic complet de la queue"
    echo -e "${BLUE}4)${NC} ⚙️  Configuration"
    echo -e "${BLUE}5)${NC} 📊 État du système"
    echo -e "${BLUE}6)${NC} 🔍 Vérifier les mises à jour"
    echo -e "${BLUE}7)${NC} 🧹 Nettoyer les logs"
    echo -e "${BLUE}8)${NC} 📋 Voir les logs en temps réel"
    echo -e "${BLUE}9)${NC} 🛠️  Installation/Configuration systemd"
    echo -e "${BLUE}A)${NC} 🎯 Configurer les commandes bashrc"
    echo -e "${BLUE}0)${NC} ❌ Quitter"
    echo ""
    echo -ne "${GREEN}Votre choix [0-9,A]:${NC} "
}

# Lancement du monitoring
start_monitoring() {
    local mode="$1"
    
    setup_venv
    source "$VENV_DIR/bin/activate"
    
    case "$mode" in
        "continuous")
            log "🚀 Démarrage du monitoring en mode continu..."
            python3 "$SCRIPT_DIR/arr-monitor.py" --config "$CONFIG_DIR/config.yaml"
            ;;
        "test")
            log "🧪 Test unique avec debug..."
            python3 "$SCRIPT_DIR/arr-monitor.py" --config "$CONFIG_DIR/config.yaml" --test --debug
            ;;
        "diagnose")
            log "🔬 Diagnostic complet..."
            python3 "$SCRIPT_DIR/arr-monitor.py" --config "$CONFIG_DIR/config.yaml" --diagnose --debug
            ;;
        "dry-run")
            log "🔍 Mode simulation..."
            python3 "$SCRIPT_DIR/arr-monitor.py" --config "$CONFIG_DIR/config.yaml" --test --dry-run
            ;;
    esac
}

# Configuration interactive
configure_app() {
    info "⚙️ Configuration Arr Monitor..."
    
    if command -v nano &> /dev/null; then
        nano "$CONFIG_DIR/config.yaml"
    elif command -v vim &> /dev/null; then
        vim "$CONFIG_DIR/config.yaml"
    else
        warn "Aucun éditeur trouvé. Éditez manuellement: $CONFIG_DIR/config.yaml"
    fi
}

# État du système
show_system_status() {
    info "📊 État du système..."
    echo ""
    
    # Informations système
    echo -e "${CYAN}Système:${NC}"
    echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Inconnu")"
    echo "  Kernel: $(uname -r)"
    echo "  Architecture: $(detect_architecture)"
    echo "  Uptime: $(uptime | cut -d',' -f1-2)"
    echo ""
    
    # Utilisation des ressources
    echo -e "${CYAN}Ressources:${NC}"
    echo "  CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)% utilisé"
    echo "  RAM: $(free -h | awk 'NR==2{printf "%.1f/%.1f GB (%.1f%%)", $3/1024/1024/1024, $2/1024/1024/1024, $3*100/$2}')"
    echo "  Disque: $(df -h "$SCRIPT_DIR" | awk 'NR==2{print $3"/"$2" ("$5" utilisé)"}')"
    echo ""
    
    # État des services
    echo -e "${CYAN}Services Arr:${NC}"
    local services=("sonarr" "radarr" "prowlarr" "bazarr")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  $service: ${GREEN}✅ Actif${NC}"
        else
            echo -e "  $service: ${YELLOW}⏸️ Inactif${NC}"
        fi
    done
    echo ""
    
    # Logs récents
    echo -e "${CYAN}Logs récents:${NC}"
    if [[ -f "$LOG_DIR/arr-monitor.log" ]]; then
        tail -5 "$LOG_DIR/arr-monitor.log" | while read -r line; do
            echo "  $line"
        done
    else
        echo "  Aucun log disponible"
    fi
    
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

# Visualisation des logs en temps réel
show_live_logs() {
    info "📋 Logs en temps réel (Ctrl+C pour quitter)..."
    
    if [[ -f "$LOG_DIR/arr-monitor.log" ]]; then
        tail -f "$LOG_DIR/arr-monitor.log"
    else
        warn "Aucun fichier de log trouvé"
        read -p "Appuyez sur Entrée pour continuer..."
    fi
}

# Installation systemd
install_systemd() {
    info "🛠️ Configuration systemd..."
    
    if [[ -f "$SCRIPT_DIR/install-arr.sh" ]]; then
        bash "$SCRIPT_DIR/install-arr.sh"
    else
        error "Script d'installation systemd non trouvé"
        read -p "Appuyez sur Entrée pour continuer..."
    fi
}

# Boucle principale
main() {
    # Vérifications initiales
    check_system_requirements
    setup_config
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                start_monitoring "continuous"
                ;;
            2)
                start_monitoring "test"
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
            3)
                start_monitoring "diagnose"
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
            4)
                configure_app
                ;;
            5)
                show_system_status
                ;;
            6)
                check_updates
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
            7)
                cleanup_logs
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
            8)
                show_live_logs
                ;;
            9)
                install_systemd
                ;;
            A|a)
                setup_bashrc_integration
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
            0)
                log "👋 Au revoir !"
                exit 0
                ;;
            *)
                error "Choix invalide. Veuillez sélectionner 0-9 ou A."
                sleep 2
                ;;
        esac
    done
}

# Point d'entrée
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
