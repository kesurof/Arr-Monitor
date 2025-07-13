# 🚀 Arr Monitor v1.1.5 - Release Stable

**Version de production recommandée** ⭐

## 🎯 Points forts de cette release

Cette version marque une étape importante avec un **projet optimisé, nettoyé et stabilisé** pour un usage en production.

## ✨ Nouvelles fonctionnalités

### 🔄 Système de versions centralisé
- **Fichier `.version`** unique comme source de vérité
- Synchronisation automatique de tous les composants
- Fin des incohérences de versions entre launcher/monitor/update_checker

### 🛠️ Installation systemd améliorée
- Fallback manuel détaillé quand `install-arr.sh` manque
- Instructions complètes pour configuration service systemd
- Gestion robuste des environnements virtuels

### 🧹 Projet nettoyé et organisé
- **7 fichiers temporaires supprimés** (test-*, fix-*, quick-fix-*)
- Structure claire et maintenue
- Scripts optimisés pour la production

## 🔧 Corrections techniques importantes

### ✅ Fix problème d'installation
- **Correction critique** : script `install-arr.sh` avec sed cassé
- Suppression de la correction automatique fragile
- Installation plus fiable et prévisible

### ✅ Synchronisation des versions
- Launcher affiche maintenant correctement `v1.1.5`
- Plus de détection de fausses mises à jour
- Cohérence entre tous les composants

## 🏆 Améliorations de stabilité

- ✅ Scripts d'installation/désinstallation robustes
- ✅ Détection d'erreurs Sonarr/Radarr optimisée  
- ✅ Interface utilisateur améliorée
- ✅ Gestion d'erreurs renforcée

## 📋 Contenu de la release

### Scripts principaux
- `arr-monitor.py` - Script de monitoring principal
- `arr-launcher.sh` - Interface utilisateur interactive  
- `install-arr.sh` - Installation automatisée (corrigée)
- `uninstall-arr.sh` - Désinstallation complète

### Configuration
- `config.yaml` - Configuration par défaut
- `.version` - Version centralisée (1.1.5)
- `requirements.txt` - Dépendances Python
- `arr-monitor.service` - Service systemd

### Documentation
- `README.md` - Guide d'utilisation
- `CHANGELOG.md` - Historique des versions
- `release-notes-v*.md` - Notes de release détaillées

## 🚀 Installation recommandée

```bash
# Installation automatique (recommandée)
curl -sL https://raw.githubusercontent.com/kesurof/Arr-Monitor/v1.1.5/install-arr.sh | bash

# Ou installation manuelle
git clone https://github.com/kesurof/Arr-Monitor.git
cd Arr-Monitor
git checkout v1.1.5
./install-arr.sh
```

## 🔍 Vérification de version

Après installation, vérifiez que toutes les versions sont synchronisées :

```bash
# Launcher devrait afficher v1.1.5
./arr-launcher.sh

# Vérification fichier version
cat .version
# Sortie attendue: 1.1.5
```

## 📈 Historique des corrections

| Version | Problème résolu |
|---------|----------------|
| v1.1.5 | Projet nettoyé, installation corrigée, versions centralisées |
| v1.1.4-clean | Suppression fichiers temporaires |
| v1.1.4 | Système de versions centralisé |
| v1.1.3 | Améliorations interface utilisateur |

## 🎯 Prochaines étapes

- Surveillance des retours utilisateurs
- Optimisations performances si nécessaires
- Nouvelles fonctionnalités basées sur les demandes

## ⚠️ Notes importantes

- **Migration recommandée** : Les utilisateurs des versions antérieures peuvent mettre à jour sans risque
- **Sauvegarde** : Vos configurations existantes sont préservées lors de la mise à jour
- **Compatibilité** : Compatible avec toutes les installations Sonarr/Radarr existantes

---

**Version stable recommandée pour la production** 🏆

Pour toute question ou problème : [GitHub Issues](https://github.com/kesurof/Arr-Monitor/issues)
