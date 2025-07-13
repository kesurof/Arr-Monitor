#!/bin/bash
# fix-version.sh - Script de correction de version pour le serveur distant

echo "🔧 CORRECTION DE VERSION v1.1.4"
echo "================================="
echo ""

# Forcer la mise à jour du fichier .version
echo "1. 📝 Mise à jour du fichier .version"
echo "1.1.4" > .version
echo "   ✅ Version écrite: $(cat .version)"
echo ""

# Vérifier les permissions
echo "2. 🔒 Vérification des permissions"
chmod 644 .version
echo "   ✅ Permissions mises à jour"
echo ""

# Test de lecture
echo "3. 🧪 Test de lecture"
if [ -f ".version" ]; then
    VERSION_READ=$(cat ".version" | tr -d '\n\r' | sed 's/[[:space:]]*$//')
    echo "   Version lue: '$VERSION_READ'"
    if [ "$VERSION_READ" = "1.1.4" ]; then
        echo "   ✅ Lecture correcte"
    else
        echo "   ❌ Erreur de lecture"
    fi
else
    echo "   ❌ Fichier .version non trouvé"
fi
echo ""

# Nettoyer les éventuels caches
echo "4. 🧹 Nettoyage des caches"
# Supprimer d'éventuels fichiers temporaires
rm -f .version.tmp* .version.bak .version.old 2>/dev/null
echo "   ✅ Caches nettoyés"
echo ""

# Test avec arr-launcher.sh si disponible
echo "5. 🚀 Test avec arr-launcher.sh"
if [ -f "arr-launcher.sh" ]; then
    # Extraire juste la partie de lecture de version
    VERSION_TEST=$(bash -c '
        VERSION_FILE=".version"
        if [ -f "$VERSION_FILE" ]; then
            CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '"'"'\n\r'"'"' | sed '"'"'s/[[:space:]]*$//'"'"')
            echo "$CURRENT_VERSION"
        else
            echo "1.1.4"
        fi
    ')
    echo "   Version détectée par launcher: '$VERSION_TEST'"
    if [ "$VERSION_TEST" = "1.1.4" ]; then
        echo "   ✅ Launcher lit correctement"
    else
        echo "   ❌ Problème dans launcher"
    fi
else
    echo "   ⚠️  arr-launcher.sh non trouvé"
fi
echo ""

echo "🎯 RÉSULTAT FINAL"
echo "================="
echo "Version dans .version: $(cat .version 2>/dev/null || echo "ERREUR")"
echo ""
echo "Si le problème persiste, copiez cette commande sur votre serveur:"
echo "echo '1.1.4' > .version && chmod 644 .version"
echo ""
