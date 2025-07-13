# 🔧 Arr Monitor v1.1.4 - Version Centralisée et Détection Stricte

## 🎯 VERSION FINALE COMPLÈTE

Cette version apporte la **centralisation complète** du système de version et corrige définitivement tous les problèmes de synchronisation.

## 🔧 SYSTÈME DE VERSION CENTRALISÉ (NOUVEAU!)

### ✨ Innovation Majeure
- **Fichier unique** : `.version` contient la version (1.1.4)
- **Lecture automatique** : Tous les scripts lisent depuis ce fichier
- **Cohérence garantie** : Plus jamais de versions incohérentes
- **Maintenance simplifiée** : Une seule modification met à jour tout

### 🛠️ Corrections Techniques
- **Launcher** : Lit dynamiquement depuis `.version` 
- **Monitor** : Utilise `_read_version_file()` automatique
- **Update Checker** : Détection automatique de la version courante
- **Fallback** : Version par défaut 1.1.4 si fichier absent

## 🛡️ DÉTECTION STRICTE (CRITIQUE)

### Protection Renforcée
- ✅ **Suppression UNIQUE** : `qBittorrent is reporting an error` seulement
- ✅ **Protection** : `stalled with no connections` préservés
- ✅ **Sécurité** : Aucune suppression accidentelle possible
- ✅ **Précision** : Détection ciblée et stricte

## 🆕 Fonctionnalités Complètes

### Auto-Refresh Configuration
- 🔄 **Detection Docker** : Conteneurs Sonarr/Radarr automatique
- 🔑 **Extraction API** : Clés API trouvées automatiquement  
- � **URLs dynamiques** : IPs mises à jour en temps réel
- 🧪 **Test connexion** : Validation immédiate

### Améliorations Interface
- 🐛 **Erreurs 404** : Messages explicites et clairs
- 📚 **Documentation** : README simplifié (~200 lignes)
- 🎯 **Bashrc Integration** : Commandes globales disponibles
- 🔧 **Logs anonymisés** : Protection des données sensibles

## 📥 Installation/Mise à jour

```bash
# Méthode 1: Via le menu (recommandé)
./arr-launcher.sh
# Choix 7 pour vérifier les mises à jour

# Méthode 2: Git direct
git pull origin main

# Méthode 3: Update automatique
cd /path/to/Arr-Monitor && git fetch && git reset --hard origin/main
```

## ✅ Validation Complète

### Tests de Cohérence
- **Version Launcher** : `v1.1.4` ✅
- **Version Monitor** : `1.1.4` depuis `.version` ✅  
- **Update Checker** : Pas de fausse détection ✅
- **Configuration** : Auto-refresh fonctionnel ✅

### Tests de Sécurité
- **Détection Stricte** : Erreurs qBittorrent uniquement ✅
- **Protection Downloads** : Stalled préservés ✅
- **API Safety** : Clés anonymisées dans logs ✅

## 🎯 Impact Utilisateur

### Avant (v1.1.3 et antérieures)
- ❌ Versions incohérentes entre composants
- ❌ Fausses détections de mise à jour
- ❌ Suppression trop large d'erreurs
- ❌ Configuration manuelle complexe

### Après (v1.1.4)
- ✅ Version unique et cohérente partout
- ✅ Détection de mise à jour précise
- ✅ Suppression ciblée et sécurisée  
- ✅ Configuration auto-refresh disponible

## ⚠️ RECOMMANDATION CRITIQUE

**Déployez immédiatement cette version** pour :
1. **Protéger vos téléchargements** contre les suppressions accidentelles
2. **Éliminer les incohérences** de version
3. **Bénéficier de l'auto-refresh** de configuration
4. **Profiter d'une maintenance simplifiée**

## 🔗 Fichiers Modifiés

- `.version` : Fichier central de version (NOUVEAU)
- `arr-launcher.sh` : Lecture dynamique de version
- `arr-monitor.py` : Méthode `_read_version_file()` 
- `update_checker.py` : Auto-détection version
- `release-notes-v1.1.4-fix.md` : Documentation complète

---
**🚀 VERSION PRODUCTION READY** - Système complet, sécurisé et maintenable
