# 📋 Changelog - Arr Monitor

## [1.1.2] - 2025-07-13

### ✨ Améliorations
- **🔧 Bashrc simplifié** : Fonction bashrc simplifiée avec accès direct au menu interactif
- **🧹 Nettoyage automatique intelligent** : Détection et suppression automatique des répertoires temporaires
- **📁 Installation complète** : Copie automatique de tous les fichiers nécessaires (arr-launcher.sh, update_checker.py, .version)
- **🛡️ Sécurité renforcée** : Vérifications multiples pour éviter la suppression accidentelle de répertoires importants

### 🐛 Corrections
- **✅ Résolution problème configuration** : Configuration maintenant créée dans le bon répertoire de destination
- **✅ Fonction bashrc manquante** : setup_bashrc_function correctement définie avant utilisation
- **✅ Fichiers manquants** : Tous les fichiers nécessaires sont maintenant copiés lors de l'installation

### 🧹 Nettoyage
- **🗑️ Suppression fichiers obsolètes** : Suppression de install-arr-new.sh, test-venv-detection.sh, quick-fix.sh
- **📦 Structure projet nettoyée** : Conservation uniquement des fichiers essentiels

### 🎯 Interface utilisateur
- **⚡ Commande unique** : `arr-monitor` donne accès direct au menu complet
- **🔗 Alias simplifiés** : `arrmonitor` et `arr` pour un accès rapide
- **💡 Messages améliorés** : Instructions claires pour l'utilisation post-installation

## [1.1.0] - 2025-07-13

### 🔬 Nouvelles fonctionnalités majeures
- **Mode diagnostic complet** avec analyse détaillée des queues
- **Commandes bashrc globales** : `arr-monitor` disponible partout dans le terminal
- **Blocklist and Search véritablement fonctionnel** avec API corrigée
- **Pagination complète** pour récupérer toutes les entrées des grandes queues
- **Détection élargie des erreurs** : warning, failed, stalled, paused, importFailed

### 🔧 Améliorations techniques
- **API Sonarr/Radarr corrigée** : utilisation des bons paramètres pour blocklist
- **Pagination automatique** : gestion des queues avec des centaines d'éléments
- **Timeouts étendus** pour les environnements ARM64
- **Headers Content-Type** appropriés pour toutes les requêtes API
- **Commandes de recherche spécifiques** : MissingMoviesSearch vs MissingEpisodeSearch

### 🎯 Interface utilisateur
- **Option diagnostic** dans le menu principal (option 3)
- **Intégration bashrc** dans le menu (option A)
- **Commandes disponibles partout** : arr-monitor, arrmonitor, arr
- **Aide intégrée** avec `arr-monitor help`
- **Gestion d'erreurs améliorée** avec anonymisation

### 📊 Diagnostic et debug
- **Analyse statistique complète** des statuts de queue
- **Détail des erreurs** avec informations de tracking
- **Mode --diagnose** pour dépannage
- **Logs anonymisés** pour protection de la vie privée
- **Rapport détaillé** des problèmes détectés

### 🚀 Commandes bashrc
- `arr-monitor` : Menu principal
- `arr-monitor start` : Démarrage monitoring
- `arr-monitor test` : Test debug
- `arr-monitor diagnose` : Diagnostic complet
- `arr-monitor config` : Édition configuration
- `arr-monitor logs` : Logs temps réel
- `arr-monitor update` : Vérification mises à jour
- `arr-monitor help` : Aide complète

### 🔧 Corrections de bugs
- **Pagination manquante** : récupération complète des queues
- **Paramètres API incorrects** : blocklist fonctionne maintenant
- **Détection d'erreurs limitée** : élargie à tous les statuts problématiques
- **Timeouts insuffisants** : adaptés aux serveurs ARM64
- **Recherche manuelle** : automatisée après blocklist

---

## [1.0.0] - 2025-07-13

### 🆕 Nouvelles fonctionnalités
- **Menu interactif unifié** (`arr-launcher.sh`) avec toutes les fonctions
- **Optimisations ARM64** spécifiques pour serveurs ARM (Neoverse-N1)
- **Détection automatique des mises à jour** via GitHub API
- **Anonymisation automatique** des données sensibles dans les logs
- **Action "Blocklist and Search"** pour résolution intelligente des erreurs

### 🔧 Améliorations techniques
- **Détection d'architecture** automatique (ARM64/AMD64)
- **Timeouts étendus** pour environnements ARM64
- **Headers optimisés** pour les requêtes API ARM64
- **Gestion avancée des logs** avec rotation et anonymisation
- **Monitoring système** intégré dans le menu

### 🔒 Sécurité et confidentialité
- **Anonymisation des adresses IP** dans les logs
- **Masquage des noms d'utilisateur** et hostnames
- **Protection des clés API** (affichage partiel)
- **Configuration privacy** dans config.yaml

### 🎯 Changements comportementaux
- **Remplacement du retry simple** par "Blocklist and Search"
- **Blocage automatique** des releases défaillantes
- **Recherche automatique** de nouvelles releases
- **Résolution définitive** au lieu de boucles infinies

### 📊 Compatibilité environnement serveur
- **Support natif ARM64** (Neoverse-N1)
- **Optimisations Ubuntu 22.04** LTS
- **Gestion des ressources** adaptée (23Gi RAM, 4 cœurs)
- **Intégration systemd** améliorée

### 🛠️ Outils d'administration
- **Menu de configuration** interactif
- **Visualisation logs** en temps réel
- **Nettoyage automatique** des logs volumineux
- **État système** détaillé avec métriques

### 📦 Dépendances
- Ajout de `packaging>=21.0` pour la gestion des versions
- Optimisation des dépendances pour ARM64
- Support des environnements virtuels existants

---

## Versions précédentes

Voir les releases GitHub pour l'historique complet des versions.
