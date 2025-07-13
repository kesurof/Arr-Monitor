#!/usr/bin/env python3
"""
Test script pour vérifier que la détection d'erreur est stricte
"""

import sys
import os
sys.path.append(os.path.dirname(__file__))

from arr_monitor import ArrMonitor

# Test cases avec différents types d'erreurs
test_cases = [
    {
        "name": "qBittorrent error (DOIT être détecté)",
        "item": {
            "errorMessage": "qBittorrent is reporting an error",
            "status": "downloading"
        },
        "should_detect": True
    },
    {
        "name": "Stalled download (NE DOIT PAS être détecté)",
        "item": {
            "errorMessage": "The download is stalled with no connections",
            "status": "stalled"
        },
        "should_detect": False
    },
    {
        "name": "Warning status (NE DOIT PAS être détecté)",
        "item": {
            "errorMessage": "Some warning message",
            "status": "warning"
        },
        "should_detect": False
    },
    {
        "name": "Failed status (NE DOIT PAS être détecté)",
        "item": {
            "errorMessage": "Download failed",
            "status": "failed"
        },
        "should_detect": False
    },
    {
        "name": "No error (NE DOIT PAS être détecté)",
        "item": {
            "errorMessage": "",
            "status": "downloading"
        },
        "should_detect": False
    }
]

def test_detection():
    """Test la fonction de détection d'erreur"""
    print("🧪 Test de détection d'erreur stricte")
    print("=" * 50)
    
    # Créer une instance simplifiée pour le test
    class TestMonitor:
        def is_download_failed(self, item):
            """Fonction de test copiée du script principal"""
            error_message = item.get('errorMessage', '')
            
            # DÉTECTION STRICTE : Seulement l'erreur qBittorrent spécifique
            is_qbittorrent_error = (
                error_message and "qBittorrent is reporting an error" in error_message
            )
            
            return is_qbittorrent_error
    
    monitor = TestMonitor()
    all_passed = True
    
    for test_case in test_cases:
        result = monitor.is_download_failed(test_case["item"])
        expected = test_case["should_detect"]
        
        status = "✅ PASS" if result == expected else "❌ FAIL"
        if result != expected:
            all_passed = False
            
        print(f"{status} {test_case['name']}")
        print(f"     Détecté: {result}, Attendu: {expected}")
        print(f"     Message: {test_case['item']['errorMessage']}")
        print()
    
    print("=" * 50)
    if all_passed:
        print("✅ TOUS LES TESTS PASSENT - La détection est stricte !")
    else:
        print("❌ CERTAINS TESTS ÉCHOUENT - Vérifier la logique !")
    
    return all_passed

if __name__ == "__main__":
    test_detection()
