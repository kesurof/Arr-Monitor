#!/bin/bash

# Script de désinstallation Arr Monitor
set -euo pipefail

echo "🗑️  Désinstallation Arr Monitor - Surveillance Sonarr/Radarr"
echo ""
echo "⚠️  Ce script va :"
echo "   • Arrêter et supprimer le service systemd"
echo "   • Supprimer les fichiers d'installation"
echo "   • Nettoyer les configurations (optionnel)"
echo ""

# Demander confirmation
read -p "❓ Êtes-vous sûr de vouloir désinstaller Arr Monitor ? [y/N] : " CONFIRM
CONFIRM=${CONFIRM:-N}

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "❌ Désinstallation annulée"
    exit 0
fi

echo ""
echo "🔍 Recherche des installations existantes..."

# Recherche des installations possibles
POSSIBLE_INSTALL_DIRS=(
    "/home/$USER/scripts/Arr-Monitor"
    "/opt/Arr-Monitor"
    "/usr/local/Arr-Monitor"
    "$HOME/Arr-Monitor"
)

FOUND_INSTALLATIONS=()
for dir in "${POSSIBLE_INSTALL_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -f "$dir/arr-monitor.py" ]; then
        FOUND_INSTALLATIONS+=("$dir")
        echo "  ✅ Installation trouvée : $dir"
    fi
done

# Demander le répertoire d'installation si pas trouvé automatiquement
if [ ${#FOUND_INSTALLATIONS[@]} -eq 0 ]; then
    echo "  ⚠️  Aucune installation automatiquement détectée"
    read -p "📁 Chemin vers l'installation Arr Monitor (ou Enter pour ignorer) : " CUSTOM_DIR
    if [ -n "$CUSTOM_DIR" ] && [ -d "$CUSTOM_DIR" ]; then
        FOUND_INSTALLATIONS+=("$CUSTOM_DIR")
    fi
fi

# 1. Arrêt et suppression du service systemd
echo ""
echo "🛑 Gestion du service systemd..."

if systemctl is-enabled arr-monitor &> /dev/null; then
    echo "  📋 Service arr-monitor détecté"
    
    # Arrêter le service
    if systemctl is-active --quiet arr-monitor; then
        echo "  🛑 Arrêt du service..."
        sudo systemctl stop arr-monitor
    fi
    
    # Désactiver le service
    echo "  ❌ Désactivation du service..."
    sudo systemctl disable arr-monitor
    
    # Supprimer le fichier service
    if [ -f "/etc/systemd/system/arr-monitor.service" ]; then
        echo "  🗑️  Suppression du fichier service..."
        sudo rm -f /etc/systemd/system/arr-monitor.service
    fi
    
    # Recharger systemd
    echo "  🔄 Rechargement de systemd..."
    sudo systemctl daemon-reload
    sudo systemctl reset-failed arr-monitor 2>/dev/null || true
    
    echo "  ✅ Service systemd supprimé"
else
    echo "  ℹ️  Aucun service arr-monitor trouvé"
fi

# 2. Suppression des fichiers d'installation
echo ""
echo "🗑️  Suppression des fichiers d'installation..."

if [ ${#FOUND_INSTALLATIONS[@]} -gt 0 ]; then
    for install_dir in "${FOUND_INSTALLATIONS[@]}"; do
        echo "  📁 Traitement de : $install_dir"
        
        # Sauvegarder la configuration si demandé
        if [ -f "$install_dir/config/config.yaml.local" ]; then
            read -p "  💾 Sauvegarder la configuration de $install_dir ? [y/N] : " BACKUP_CONFIG
            BACKUP_CONFIG=${BACKUP_CONFIG:-N}
            
            if [[ $BACKUP_CONFIG =~ ^[Yy]$ ]]; then
                BACKUP_FILE="$HOME/arr-monitor-config-backup-$(date +%Y%m%d_%H%M%S).yaml"
                cp "$install_dir/config/config.yaml.local" "$BACKUP_FILE"
                echo "  ✅ Configuration sauvegardée : $BACKUP_FILE"
            fi
        fi
        
        # Vérifier si c'est un lien symbolique vers un venv externe
        if [ -L "$install_dir/venv" ]; then
            VENV_TARGET=$(readlink -f "$install_dir/venv")
            echo "  🔗 Environnement virtuel lié détecté : $VENV_TARGET"
            echo "  ℹ️  L'environnement virtuel externe sera préservé"
        fi
        
        # Supprimer le répertoire d'installation
        echo "  🗑️  Suppression du répertoire..."
        rm -rf "$install_dir"
        echo "  ✅ $install_dir supprimé"
    done
else
    echo "  ℹ️  Aucune installation à supprimer"
fi

# 3. Nettoyage des processus restants
echo ""
echo "🔍 Recherche de processus arr-monitor en cours..."

ARR_PROCESSES=$(pgrep -f "arr-monitor.py" || true)
if [ -n "$ARR_PROCESSES" ]; then
    echo "  ⚠️  Processus arr-monitor détectés :"
    ps -fp $ARR_PROCESSES
    
    read -p "  🛑 Terminer ces processus ? [y/N] : " KILL_PROCESSES
    KILL_PROCESSES=${KILL_PROCESSES:-N}
    
    if [[ $KILL_PROCESSES =~ ^[Yy]$ ]]; then
        echo "  🛑 Arrêt des processus..."
        kill $ARR_PROCESSES 2>/dev/null || true
        sleep 2
        
        # Force kill si nécessaire
        REMAINING=$(pgrep -f "arr-monitor.py" || true)
        if [ -n "$REMAINING" ]; then
            echo "  💀 Force kill des processus restants..."
            kill -9 $REMAINING 2>/dev/null || true
        fi
        echo "  ✅ Processus terminés"
    fi
else
    echo "  ℹ️  Aucun processus arr-monitor en cours"
fi

# 4. Nettoyage des logs système (optionnel)
echo ""
read -p "🗑️  Supprimer les logs systemd de arr-monitor ? [y/N] : " CLEAN_LOGS
CLEAN_LOGS=${CLEAN_LOGS:-N}

if [[ $CLEAN_LOGS =~ ^[Yy]$ ]]; then
    echo "  🧹 Nettoyage des logs systemd..."
    sudo journalctl --vacuum-time=1s --unit=arr-monitor 2>/dev/null || true
    echo "  ✅ Logs systemd nettoyés"
fi

# 5. Rapport final
echo ""
echo "📋 Résumé de la désinstallation :"
echo "  ✅ Service systemd : supprimé"
echo "  ✅ Fichiers d'installation : supprimés"
echo "  ✅ Processus : vérifiés"

if [ ${#FOUND_INSTALLATIONS[@]} -gt 0 ]; then
    echo "  📁 Répertoires supprimés :"
    for dir in "${FOUND_INSTALLATIONS[@]}"; do
        echo "     - $dir"
    done
fi

echo ""
echo "✅ Désinstallation terminée avec succès !"
echo ""
echo "ℹ️  Notes :"
echo "   • Les environnements virtuels externes ont été préservés"
echo "   • Les sauvegardes de configuration sont dans $HOME"
echo "   • Pour une réinstallation : curl -sL https://raw.githubusercontent.com/kesurof/Arr-Monitor/main/install-arr.sh | bash"
echo ""

# Vérification finale
echo "🔍 Vérification finale..."
if systemctl list-unit-files | grep -q arr-monitor; then
    echo "  ⚠️  Attention : Le service systemd est encore visible"
else
    echo "  ✅ Service systemd complètement supprimé"
fi

if pgrep -f "arr-monitor.py" &> /dev/null; then
    echo "  ⚠️  Attention : Des processus arr-monitor sont encore actifs"
else
    echo "  ✅ Aucun processus arr-monitor actif"
fi

echo ""
echo "🎉 Désinstallation complète !"
