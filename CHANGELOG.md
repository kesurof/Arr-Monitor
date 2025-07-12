# 📋 Changelog - Arr Monitor

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
