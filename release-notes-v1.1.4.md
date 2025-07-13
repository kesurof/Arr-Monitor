# 🚨 Release Notes v1.1.4 - CORRECTION CRITIQUE

**Date de release :** 13 juillet 2025

## 🚨 CORRECTION CRITIQUE

### ⚠️ **Problème Identifié**
Les versions précédentes détectaient et supprimaient **TOUS** les types d'erreurs :
- ❌ `"The download is stalled with no connections"` (supprimé par erreur)
- ❌ Status `"stalled"`, `"warning"`, `"failed"` (supprimés par erreur)  
- ❌ Tous les messages d'erreur génériques

### ✅ **Correction Appliquée** 
La détection est maintenant **STRICTEMENT** limitée à :
- ✅ **UNIQUEMENT** `"qBittorrent is reporting an error"`
- ✅ **AUCUNE** autre erreur n'est touchée
- ✅ **PROTECTION** des téléchargements stalled légitimes

### 📋 **Code Modifié**
```python
# AVANT (v1.1.3 et antérieures)
status in ['failed', 'warning', 'error', 'stalled', 'paused'] or
bool(error_message) or  # TOUS les messages d'erreur !

# APRÈS (v1.1.4)
error_message and "qBittorrent is reporting an error" in error_message
# UNIQUEMENT cette erreur spécifique !
```

## ✨ Fonctionnalités Conservées

### 🔄 **Réactualisation Automatique**
- **Fonction `refresh_config()`** complète
- **Détection Docker** intelligente
- **Extraction automatique** des clés API
- **Tests de connexion** après mise à jour
- **Système de sauvegarde** automatique

### 🎯 **Menu Interactif Amélioré**
- **Option 5** : Réactualiser IPs et clés API
- **Commande `arr-monitor refresh`** globale
- **Réorganisation** : Systemd (S), Bashrc (A)
- **Aide intégrée** complète

### 📝 **Documentation Simplifiée**
- **README raccourci** : 758 → ~200 lignes
- **Langage au présent**
- **Clarification** de la détection stricte
- **Avertissement** sur les autres erreurs

## 🔧 Autres Corrections

### ⚙️ **Configuration**
- **Config.yaml** : `enabled: false` par défaut (corrigé)
- **Install-arr.sh** : logique sed corrigée
- **Erreurs 404** : gestion améliorée

### 🐳 **Docker**
- **Multi-réseaux** : traefik_proxy, bridge, custom
- **SETTINGS_STORAGE** : support complet
- **Validation** : tests de connectivité

## 🚀 Installation & Mise à Jour

### **⚠️ MISE À JOUR CRITIQUE RECOMMANDÉE**

```bash
# Depuis un répertoire temporaire
cd /tmp
git clone https://github.com/kesurof/Arr-Monitor.git
cd Arr-Monitor
./install-arr.sh --update
```

### **Nouvelle Installation**
```bash
git clone https://github.com/kesurof/Arr-Monitor.git
cd Arr-Monitor
chmod +x install-arr.sh
./install-arr.sh
```

## 🎯 Impact de la Correction

### ✅ **Ce qui est maintenant PROTÉGÉ**
- `"The download is stalled with no connections"` ➡️ **IGNORÉ**
- `"Download failed"` ➡️ **IGNORÉ**
- `"Warning: something wrong"` ➡️ **IGNORÉ**
- Status `"stalled"`, `"warning"`, `"failed"` ➡️ **IGNORÉ**

### 🎯 **Ce qui est TRAITÉ**
- `"qBittorrent is reporting an error"` ➡️ **Blocklist + Search**

## 🔄 Migration depuis v1.1.3

**MISE À JOUR TRANSPARENTE** :
- Configuration existante préservée
- Correction automatique de la détection
- Aucune action manuelle requise
- Nouvelle fonction `refresh` disponible

## 📊 Statistiques de la Correction

- **Lignes supprimées** : 15 (détection élargie)
- **Lignes ajoutées** : 8 (détection stricte)
- **Fonction modifiée** : `is_download_failed()`
- **Impact** : **CRITIQUE** - Empêche suppression erronée

## ⚠️ Recommandation Utilisateurs

### 🚨 **MISE À JOUR IMMÉDIATE CONSEILLÉE**
Si vous utilisez v1.1.3 ou antérieure :
1. **Arrêtez** le service : `sudo systemctl stop arr-monitor`
2. **Mettez à jour** : `cd /tmp && git clone ... && ./install-arr.sh --update`
3. **Redémarrez** : `sudo systemctl start arr-monitor`

### 📋 **Vérification Post-Mise à Jour**
```bash
# Tester la nouvelle fonction
arr-monitor refresh

# Vérifier les logs
arr-monitor logs

# Test de configuration
arr-monitor test
```

## 🤝 Remerciements

Merci à l'utilisateur qui a identifié cette **erreur critique** :
> "le script supprime les warnings : The download is stalled with no connections"

Cette correction **protège maintenant** tous les téléchargements légitimes stalled.

---

**⚠️ Cette release corrige un problème CRITIQUE - Mise à jour fortement recommandée !**

**⭐ Si cette correction vous aide, n'hésitez pas à donner une étoile au projet !**
