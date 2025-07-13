#!/bin/bash
# test-version.sh - Test simple de lecture de version

echo "=== TEST DE LECTURE DE VERSION ==="
echo ""

echo "1. Contenu du fichier .version:"
if [ -f ".version" ]; then
    cat .version
    echo ""
else
    echo "ERREUR: Fichier .version non trouvé!"
    exit 1
fi

echo "2. Test de lecture bash (comme dans arr-launcher.sh):"
if [ -f ".version" ]; then
    CURRENT_VERSION=$(cat ".version" | tr -d '\n\r' | sed 's/[[:space:]]*$//')
    echo "Version lue: $CURRENT_VERSION"
else
    echo "Fallback: 1.1.4"
fi
echo ""

echo "3. Vérification des espaces/caractères invisibles:"
echo "Taille du fichier: $(wc -c < .version) octets"
echo "Contenu hexadecimal:"
hexdump -C .version | head -2
echo ""

echo "4. Test de nettoyage:"
CLEAN_VERSION=$(cat .version | tr -d '\n\r\t ' | sed 's/[[:space:]]*$//')
echo "Version nettoyée: '$CLEAN_VERSION'"
echo ""

echo "=== FIN DU TEST ==="
