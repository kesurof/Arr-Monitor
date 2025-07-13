# 🚀 Arr Monitor v1.1.0 - Major Improvements & Fixes

## 🔬 Major New Features

### 📊 Complete Diagnostic Mode
- **Detailed queue analysis** with comprehensive statistics
- **Advanced error detection** for all problem types
- **Privacy-focused reporting** with data anonymization
- **Troubleshooting tool** for identifying issues
- Access via menu option 3 or `arr-monitor diagnose`

### 🎯 Global Bashrc Commands
- **System-wide availability**: `arr-monitor` command works anywhere
- **Multiple aliases**: `arrmonitor` and `arr` for convenience
- **Complete command set** with integrated help system
- **Auto-configuration** during installation

### 🚫 Fully Functional Blocklist and Search
- **Corrected API parameters** based on working bash scripts
- **Proper blocklist functionality** that actually works
- **Automatic search trigger** after blocking failed releases
- **App-specific commands**: MissingMoviesSearch vs MissingEpisodeSearch

### 📊 Complete Pagination Support
- **Large queue handling** - processes hundreds of items
- **Automatic pagination** retrieves all entries
- **No more missed items** in busy download queues
- **Optimized for ARM64** server environments

## 🔧 Technical Improvements

### API Fixes
- **Blocklist parameters**: Fixed `removeFromClient=true&blocklist=true`
- **Content-Type headers**: Proper `application/json` for all requests
- **Extended timeouts**: 15-30 seconds for ARM64 compatibility
- **Error handling**: Comprehensive exception management

### Detection Enhancements
- **Expanded error detection**: warning, failed, stalled, paused, importFailed
- **Tracking status support**: trackedDownloadStatus and trackedDownloadState
- **Message parsing**: Enhanced error message analysis
- **Debug logging**: Detailed troubleshooting information

## 🎯 User Experience

### Enhanced Interactive Menu
```
1) 🔄 Lancer Arr Monitor (mode continu)
2) 🧪 Test unique (mode debug)
3) 🔬 Diagnostic complet de la queue        ← NEW
4) ⚙️ Configuration
5) 📊 État du système
6) 🔍 Vérifier les mises à jour
7) 🧹 Nettoyer les logs
8) 📋 Voir les logs en temps réel
9) 🛠️ Installation/Configuration systemd
A) 🎯 Configurer les commandes bashrc      ← NEW
0) ❌ Quitter
```

### Global Commands Available
```bash
arr-monitor              # Main interactive menu
arr-monitor start        # Start continuous monitoring
arr-monitor test         # Run debug test
arr-monitor diagnose     # Complete queue diagnostic    ← NEW
arr-monitor config       # Edit configuration
arr-monitor logs         # Real-time log viewing
arr-monitor update       # Check for GitHub updates
arr-monitor help         # Complete help system         ← NEW

# Aliases
arrmonitor              # Short alias
arr                     # Very short alias
```

## 🔬 Diagnostic Features

### What the diagnostic shows:
- **Total queue items** with complete pagination
- **Status breakdown** for all download states
- **Error details** with anonymized sensitive data
- **Tracking information** for failed downloads
- **Problem identification** with actionable insights

### Example diagnostic output:
```
📊 Radarr DIAGNOSTIC COMPLET:
📋 Total éléments: 127

📊 STATUTS COMPLETS:
   completed: 95
   downloading: 18
   warning: 8          ← Problems detected
   failed: 4           ← Problems detected
   queued: 2

🚨 ERREURS DÉTECTÉES: 12

📋 Détail des erreurs:
   1. Movie Title Here
      Status: warning
      Erreur: qBittorrent is reporting an error
   ...
```

## 🔧 Critical Bug Fixes

### Before v1.1.0 (Issues):
- ❌ **Pagination missing**: Only first 50 items retrieved
- ❌ **Blocklist broken**: Wrong API parameters used
- ❌ **Limited detection**: Only qBittorrent errors caught
- ❌ **Timeout issues**: Insufficient for ARM64 servers
- ❌ **Manual search**: No automation after blocklist

### After v1.1.0 (Fixed):
- ✅ **Complete pagination**: All queue items retrieved
- ✅ **Blocklist working**: Correct API parameters implemented
- ✅ **Expanded detection**: All error types caught
- ✅ **ARM64 optimized**: Extended timeouts and headers
- ✅ **Automated search**: Triggers after successful blocklist

## 🚀 Installation & Usage

### Quick Start
```bash
# Clone and setup
git clone https://github.com/kesurof/Arr-Monitor.git
cd Arr-Monitor
./install-arr.sh

# Configure bashrc commands (recommended)
# Select option for bashrc integration
source ~/.bashrc

# Use anywhere on your system
arr-monitor              # Interactive menu
arr-monitor diagnose     # Check for problems
arr-monitor start        # Begin monitoring
```

### Update from Previous Version
```bash
# Preserve existing configuration
./install-arr.sh --update
```

## 🎯 Perfect for ARM64 Servers

This release is specifically optimized for ARM64 server environments like:
- **Neoverse-N1** processors
- **Ubuntu 22.04** LTS
- **Large memory** configurations (16GB+)
- **Docker-based** media server setups
- **High-volume** download queues

## 📊 Testing & Validation

This release is based on:
- ✅ **Real-world testing** on ARM64 servers
- ✅ **Working bash scripts** provided by users
- ✅ **Production environments** with large queues
- ✅ **Multiple Sonarr/Radarr** configurations
- ✅ **Comprehensive error scenarios**

---

## 💡 What's Next?

Future releases will focus on:
- 📈 **Performance metrics** and statistics
- 🔔 **Enhanced notifications** (Discord, Telegram, etc.)
- 🐳 **Docker container** for easy deployment
- 📱 **Web interface** for remote management
- 🤖 **Machine learning** for predictive error detection

---

**Full Changelog**: https://github.com/kesurof/Arr-Monitor/blob/main/CHANGELOG.md
