# Instructions pour créer la Release GitHub v1.1.5

## 📋 Étapes pour créer la release

1. **Aller sur GitHub** : https://github.com/kesurof/Arr-Monitor/releases

2. **Cliquer sur "Create a new release"**

3. **Paramètres de la release :**
   - **Tag** : `v1.1.5` (existant)
   - **Target** : `main` 
   - **Title** : `🚀 Arr Monitor v1.1.5 - Release Stable`

4. **Description de la release** (copier-coller) :

```markdown
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

## 🏆 Améliorations de stabilité

- ✅ Scripts d'installation/désinstallation robustes
- ✅ Détection d'erreurs Sonarr/Radarr optimisée
- ✅ Interface utilisateur améliorée
- ✅ Gestion d'erreurs renforcée

**Version stable recommandée pour la production** 🏆
```

5. **Options** :
   - ☑️ Cocher "Set as the latest release"
   - ☑️ Cocher "Generate release notes" (optionnel, pour ajouter les commits automatiquement)
   - ☐ Laisser "Set as a pre-release" décoché

6. **Cliquer sur "Publish release"**

## 🎯 Résultat attendu

Une fois créée, la release sera visible à :
- https://github.com/kesurof/Arr-Monitor/releases/tag/v1.1.5
- https://github.com/kesurof/Arr-Monitor/releases/latest (en tant que latest)

## 📦 Assets automatiques

GitHub générera automatiquement :
- **Source code (zip)** - Archive zip du code source
- **Source code (tar.gz)** - Archive tar.gz du code source

## ✅ Vérification

Après création :
1. Vérifier que le tag `v1.1.5` est bien lié
2. Vérifier que c'est marqué comme "Latest release"
3. Tester l'installation avec la commande curl mentionnée
