# 🚀 Release Notes v1.1.3

**Date de release :** 13 juillet 2025

## ✨ Nouveautés

### 🔄 **Réactualisation Automatique**
- **Nouvelle fonction `refresh_config()`** : Réactualise automatiquement les IPs et clés API
- **Détection Docker intelligente** : Scan des conteneurs Sonarr/Radarr en cours d'exécution
- **Extraction automatique des clés API** depuis les configurations Docker
- **Tests de connexion** après mise à jour de la configuration
- **Système de sauvegarde** automatique avant modifications

### 🎯 **Menu Interactif Amélioré**
- **Option 5 : Réactualiser IPs et clés API** automatiquement
- **Réorganisation du menu** : Systemd (S), Bashrc (A)
- **Aide intégrée** avec toutes les commandes disponibles
- **Commande `arr-monitor refresh`** depuis n'importe où

### 📝 **Documentation Simplifiée**
- **README raccourci** : de 758 à ~200 lignes
- **Langage au présent** au lieu du futur
- **Suppression des non-essentiels** (évolutions, roadmap verbeux)
- **Conservation complète** de la section désinstallation
- **Focus sur l'utilisation pratique**

## 🐛 Corrections

### ⚙️ **Configuration**
- **Correction `config.yaml`** : `enabled: false` par défaut (au lieu de `true`)
- **Fix logique sed** dans `install-arr.sh` pour remplacement correct
- **Correction erreur de syntaxe** dans les scripts d'installation

### 🔍 **Gestion d'Erreurs**
- **Amélioration erreurs 404** dans `update_checker.py`
- **Messages spécifiques** : "Aucune release trouvée sur GitHub"
- **Gestion HTTPError** avec contexte informatif

## 🔧 Améliorations Techniques

### 🐳 **Intégration Docker**
- **Détection multi-réseaux** : traefik_proxy, bridge, custom
- **Support SETTINGS_STORAGE** pour infrastructures personnalisées
- **Extraction depuis conteneurs** ET fichiers locaux
- **Validation des connexions** après détection

### 📊 **Fonctionnalités Système**
- **Backup automatique** avant modifications de config
- **Tests de connectivité** API après changements
- **Logs détaillés** pour diagnostic
- **Gestion intelligente** des environnements virtuels

## 🚀 Installation & Mise à Jour

### **Nouvelle Installation**
```bash
git clone https://github.com/kesurof/Arr-Monitor.git
cd Arr-Monitor
chmod +x install-arr.sh
./install-arr.sh
```

### **Mise à Jour depuis Version Précédente**
```bash
cd /tmp
git clone https://github.com/kesurof/Arr-Monitor.git
cd Arr-Monitor
./install-arr.sh --update
```

### **Nouvelle Fonctionnalité - Réactualisation**
```bash
# Après installation/mise à jour
arr-monitor refresh  # Réactualise IPs et clés API automatiquement
```

## 🎯 Utilisation

### **Commandes Bashrc Améliorées**
```bash
arr-monitor           # Menu interactif
arr-monitor start     # Démarrer monitoring
arr-monitor test      # Test configuration
arr-monitor refresh   # 🆕 Réactualiser config automatiquement
arr-monitor logs      # Logs temps réel
arr-monitor help      # Aide complète
```

### **Menu Interactif Reorganisé**
1. 🔄 Lancer Arr Monitor
2. 🧪 Test unique  
3. 🔬 Diagnostic complet
4. ⚙️ Configuration
5. 🔄 **Réactualiser IPs et clés API** (🆕)
6. 📊 État système
7. 🔍 Vérifier mises à jour
8. 🧹 Nettoyer logs
9. 📋 Logs temps réel
S. 🛠️ Systemd
A. 🎯 Bashrc
Q. Quitter

## 🔄 Migration depuis v1.1.2

**Aucune action requise** - La mise à jour est transparente :
- Configuration existante préservée
- Nouvelles fonctionnalités disponibles immédiatement
- Commande `arr-monitor refresh` pour tester la nouvelle fonction

## 📊 Statistiques

- **Fichiers modifiés** : 6
- **Lignes ajoutées** : 464
- **Lignes supprimées** : 612 (simplification documentation)
- **Nouvelle fonction** : ~150 lignes (refresh_config)

## 🤝 Remerciements

Merci aux utilisateurs pour les retours sur :
- Les problèmes de configuration vide
- Les messages d'erreur 404 confus  
- Le besoin de réactualisation automatique
- La complexité de la documentation

---

**⭐ Si cette release vous aide, n'hésitez pas à donner une étoile au projet !**
