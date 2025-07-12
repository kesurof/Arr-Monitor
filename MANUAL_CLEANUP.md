# Commandes de nettoyage manuel Arr Monitor

## 1. Arrêt et suppression du service systemd
sudo systemctl stop arr-monitor 2>/dev/null || true
sudo systemctl disable arr-monitor 2>/dev/null || true
sudo rm -f /etc/systemd/system/arr-monitor.service
sudo systemctl daemon-reload
sudo systemctl reset-failed arr-monitor 2>/dev/null || true

## 2. Suppression des installations
# Répertoires possibles où chercher
ls -la /home/$USER/scripts/Arr-Monitor 2>/dev/null || echo "Pas trouvé dans /home/$USER/scripts/"
ls -la /opt/Arr-Monitor 2>/dev/null || echo "Pas trouvé dans /opt/"
ls -la $HOME/Arr-Monitor 2>/dev/null || echo "Pas trouvé dans $HOME/"

# Supprimer le répertoire d'installation (adapter le chemin)
# rm -rf /home/$USER/scripts/Arr-Monitor

## 3. Vérifier les processus actifs
pgrep -f "arr-monitor.py" || echo "Aucun processus arr-monitor"

# Tuer les processus si nécessaire
# pkill -f "arr-monitor.py"

## 4. Nettoyage des logs (optionnel)
sudo journalctl --vacuum-time=1s --unit=arr-monitor 2>/dev/null || true

## 5. Vérification finale
systemctl list-unit-files | grep arr-monitor || echo "Service complètement supprimé"
pgrep -f "arr-monitor.py" || echo "Aucun processus actif"
