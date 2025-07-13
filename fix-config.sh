#!/bin/bash

# Script de correction de configuration Arr Monitor
# Corrige la configuration avec les valeurs détectées automatiquement

CONFIG_FILE="/home/kesurof/scripts/Arr-Monitor/config/config.yaml.local"

echo "🔧 Correction de la configuration Arr Monitor..."
echo ""

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Fichier de configuration non trouvé : $CONFIG_FILE"
    exit 1
fi

echo "📋 Configuration actuelle :"
echo "  Sonarr : $(grep -A 3 "sonarr:" "$CONFIG_FILE" | grep "enabled:" | sed 's/.*enabled: //')"
echo "  Radarr : $(grep -A 3 "radarr:" "$CONFIG_FILE" | grep "enabled:" | sed 's/.*enabled: //')"
echo ""

# Mise à jour avec les valeurs détectées lors de l'installation
echo "🔧 Application des corrections..."

# Sonarr : activation et configuration
sed -i.bak1 '/sonarr:/,/radarr:/ s|enabled: false|enabled: true|' "$CONFIG_FILE"
sed -i.bak2 's|url: "http://localhost:8989"|url: "http://172.18.0.6:8989"|' "$CONFIG_FILE"
sed -i.bak3 's|api_key: "your_sonarr_api_key"|api_key: "9c90833a5d9d437987fe0b8ad95cce0a"|' "$CONFIG_FILE"

# Radarr : activation et configuration  
sed -i.bak4 '/radarr:/,/monitoring:/ s|enabled: false|enabled: true|' "$CONFIG_FILE"
sed -i.bak5 's|url: "http://localhost:7878"|url: "http://172.18.0.15:7878"|' "$CONFIG_FILE"
sed -i.bak6 's|api_key: "your_radarr_api_key"|api_key: "89d317afaed4486fa44c8b29b2fd15a5"|' "$CONFIG_FILE"

# Nettoyage des fichiers de sauvegarde
rm -f "$CONFIG_FILE".bak*

echo "✅ Configuration corrigée !"
echo ""

echo "📋 Nouvelle configuration :"
echo "  Sonarr : $(grep -A 3 "sonarr:" "$CONFIG_FILE" | grep "enabled:" | sed 's/.*enabled: //')"
echo "  Radarr : $(grep -A 3 "radarr:" "$CONFIG_FILE" | grep "enabled:" | sed 's/.*enabled: //')"
echo ""

echo "🧪 Test de connexion..."

# Test Sonarr
if curl -s -f -H "X-Api-Key: 9c90833a5d9d437987fe0b8ad95cce0a" "http://172.18.0.6:8989/api/v3/system/status" >/dev/null 2>&1; then
    echo "  ✅ Sonarr : Connexion réussie"
else
    echo "  ⚠️  Sonarr : Test de connexion échoué (mais configuration appliquée)"
fi

# Test Radarr
if curl -s -f -H "X-Api-Key: 89d317afaed4486fa44c8b29b2fd15a5" "http://172.18.0.15:7878/api/v3/system/status" >/dev/null 2>&1; then
    echo "  ✅ Radarr : Connexion réussie"
else
    echo "  ⚠️  Radarr : Test de connexion échoué (mais configuration appliquée)"
fi

echo ""
echo "🎯 Pour tester la configuration complète :"
echo "  cd /home/kesurof/scripts/Arr-Monitor"
echo "  ./venv/bin/python arr-monitor.py --test --config config/config.yaml.local"
echo ""
echo "🚀 Pour lancer le monitoring :"
echo "  cd /home/kesurof/scripts/Arr-Monitor"
echo "  ./arr-launcher.sh"
