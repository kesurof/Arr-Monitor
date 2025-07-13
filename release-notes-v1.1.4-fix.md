# 🔧 Arr Monitor v1.1.4 - Correction Critique

## ⚠️ Correction Importante
Cette version corrige un oubli dans la version précédente où le numéro de version n'était pas correctement mis à jour dans le code.

## 🔧 Corrections
- **Fix version** : Correction du numéro de version affiché (1.1.0 → 1.1.4)
  - Ligne 5 : Commentaire de documentation
  - Ligne 26 : Variable `self.version` dans la classe
- **Cohérence** : Toutes les références de version sont maintenant synchronisées

## 🎯 Rappel des Fonctionnalités v1.1.4

### Détection Stricte (CRITIQUE)
- ✅ **Protection renforcée** : Le script ne supprime QUE les erreurs `qBittorrent is reporting an error`
- ✅ **Sécurité** : Les téléchargements `stalled with no connections` sont préservés
- ✅ **Précision** : Évite les suppressions accidentelles de téléchargements légitimes

### Nouvelles Fonctionnalités
- 🔄 **Auto-refresh** : Menu pour réactualiser l'IP et l'API key automatiquement
- 🐛 **Gestion d'erreurs** : Amélioration du message d'erreur 404 dans update_checker
- 📚 **Documentation** : README simplifié (758 → ~200 lignes)

## 📥 Installation
```bash
# Mise à jour automatique via le menu
./arr-launcher.sh

# Ou mise à jour manuelle
git pull origin main
```

## ⚠️ Important
Cette version est essentielle pour tous les utilisateurs car elle contient la correction critique de détection stricte qui protège vos téléchargements contre les suppressions accidentelles.

## 🔗 Fichiers Modifiés
- `arr-monitor.py` : Correction du numéro de version
- Tous les autres fichiers restent identiques à v1.1.4

---
**Version complète et corrigée** - Déployez immédiatement pour bénéficier de la protection optimale de vos téléchargements.
