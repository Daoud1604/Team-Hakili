# Guide de Sécurité - MotorGuard

## Sécurité des Communications

### Mode Actuel (Développement/Test)

Actuellement, l'application utilise des connexions HTTP non sécurisées pour communiquer avec l'ESP32. Cela est acceptable pour :

- Tests en développement
- Réseaux locaux privés et isolés
- Démonstrations

### Recommandations pour la Production

#### 1. Utiliser HTTPS/TLS

Pour sécuriser les communications en production, il est **fortement recommandé** d'utiliser HTTPS :

**Côté ESP32 :**

- Configurer un serveur HTTPS avec certificat SSL/TLS
- Utiliser un certificat auto-signé ou un certificat Let's Encrypt
- Port recommandé : 443 (HTTPS)

**Côté Application Flutter :**

- Modifier l'URL de base pour utiliser `https://` au lieu de `http://`
- Activer `allowSelfSignedCert` dans les paramètres si vous utilisez un certificat auto-signé
- Pour la production, utiliser un certificat valide signé par une autorité de certification

#### 2. Authentification API Key

L'ESP32 devrait utiliser une clé API pour authentifier les requêtes :

```python
# Exemple d'implémentation
API_KEY = "votre_cle_secrete_unique"

# Dans chaque requête
headers = {
    "X-API-Key": API_KEY
}
```

#### 3. Chiffrement des Données Sensibles

- Les données de télémétrie sensibles peuvent être chiffrées avant transmission
- Utiliser AES-256 pour le chiffrement symétrique
- Stocker les clés de manière sécurisée (Android Keystore)

#### 4. Isolation Réseau

- Utiliser un réseau Wi-Fi dédié pour les ESP32
- Configurer un VLAN séparé si possible
- Activer le pare-feu sur le routeur pour limiter l'accès

#### 5. Sécurité Android

L'application Android inclut déjà :

- ✅ Permissions réseau configurées
- ✅ Support pour certificats auto-signés (mode développement)
- ⚠️ Pour la production : désactiver `usesCleartextTraffic` dans `AndroidManifest.xml`

### Configuration Recommandée pour Production

#### AndroidManifest.xml

```xml
<application
    ...
    android:usesCleartextTraffic="false">  <!-- Désactiver HTTP -->
```

#### ConfigProvider

```dart
// Utiliser HTTPS par défaut
String _esp32BaseUrl = 'https://192.168.1.50:443';
bool _allowSelfSignedCert = false; // Désactiver en production
```

### Protection contre l'Interception

1. **Wi-Fi Sécurisé** : Utiliser WPA3 ou au minimum WPA2 avec un mot de passe fort
2. **HTTPS** : Toutes les communications doivent être chiffrées
3. **VPN** : Pour un accès distant, utiliser un VPN
4. **Firewall** : Limiter l'accès au réseau local

### Bonnes Pratiques

1. **Ne jamais exposer l'ESP32 directement sur Internet**
2. **Changer les mots de passe par défaut**
3. **Mettre à jour régulièrement le firmware ESP32**
4. **Utiliser des clés API uniques pour chaque ESP32**
5. **Logger les tentatives d'accès suspectes**

## Notes Importantes

⚠️ **Le mode actuel (HTTP) est uniquement pour le développement et les tests.**

Pour un déploiement en production, il est **essentiel** d'implémenter HTTPS/TLS pour protéger les données contre l'interception.
