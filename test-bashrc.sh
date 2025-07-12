#!/bin/bash
# test-bashrc.sh - Script de test pour vérifier l'intégration bashrc

echo "🧪 Test de l'intégration bashrc Arr Monitor"
echo ""

# Vérifier si la fonction existe dans bashrc
if grep -q "function arr-monitor" "$HOME/.bashrc"; then
    echo "✅ Fonction 'arr-monitor' trouvée dans ~/.bashrc"
    
    # Vérifier les alias
    if grep -q "alias arrmonitor=" "$HOME/.bashrc"; then
        echo "✅ Alias 'arrmonitor' configuré"
    else
        echo "❌ Alias 'arrmonitor' manquant"
    fi
    
    if grep -q "alias arr=" "$HOME/.bashrc"; then
        echo "✅ Alias 'arr' configuré"
    else
        echo "❌ Alias 'arr' manquant"
    fi
    
    echo ""
    echo "🎯 Pour tester, exécutez :"
    echo "   source ~/.bashrc"
    echo "   arr-monitor help"
    echo ""
    
else
    echo "❌ Fonction 'arr-monitor' non trouvée dans ~/.bashrc"
    echo ""
    echo "💡 Pour configurer, lancez :"
    echo "   ./arr-launcher.sh"
    echo "   Puis choisissez l'option 9"
    echo ""
fi

echo "📋 Contenu actuel de la fonction bashrc :"
echo "─────────────────────────────────────────"
grep -A 20 "function arr-monitor" "$HOME/.bashrc" 2>/dev/null || echo "Aucune fonction trouvée"
