#!/bin/bash

# Test de la logique de configuration
echo "🧪 Test de la logique de configuration du script d'installation"

# Créer un répertoire de test temporaire
TEST_DIR="/tmp/arr-monitor-config-test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/config"

echo "📋 Copie du fichier config.yaml de base..."
cp config.yaml "$TEST_DIR/config/"
cd "$TEST_DIR"

echo "📋 Simulation de la création de config.yaml.local..."
cp config/config.yaml config/config.yaml.local

echo "📋 Test de la configuration avec Sonarr et Radarr détectés..."

# Simulation des variables détectées
ENABLE_SONARR="Y"
ENABLE_RADARR="Y"
SONARR_URL="http://192.168.1.100:8989"
SONARR_API="test_sonarr_api_key_12345"
RADARR_URL="http://192.168.1.100:7878"
RADARR_API="test_radarr_api_key_67890"

echo "📝 Application des modifications sed..."

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

rm -f config/config.yaml.local.bak*

echo ""
echo "✅ Configuration générée :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat config/config.yaml.local | head -15
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "🔍 Vérification des valeurs configurées :"
if grep -q "enabled: true" config/config.yaml.local; then
    echo "✅ Au moins un service activé"
else
    echo "❌ Aucun service activé"
fi

if grep -q "$SONARR_URL" config/config.yaml.local; then
    echo "✅ URL Sonarr configurée correctement"
else
    echo "❌ URL Sonarr non configurée"
fi

if grep -q "$SONARR_API" config/config.yaml.local; then
    echo "✅ API Sonarr configurée correctement"
else
    echo "❌ API Sonarr non configurée"
fi

if grep -q "$RADARR_URL" config/config.yaml.local; then
    echo "✅ URL Radarr configurée correctement"
else
    echo "❌ URL Radarr non configurée"
fi

if grep -q "$RADARR_API" config/config.yaml.local; then
    echo "✅ API Radarr configurée correctement"
else
    echo "❌ API Radarr non configurée"
fi

echo ""
echo "🧹 Nettoyage du répertoire de test..."
cd - > /dev/null
rm -rf "$TEST_DIR"
echo "✅ Test terminé !"
