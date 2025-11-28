# Guide utilisateur - MotorGuard Mobile

Guide simple pour utiliser l'application MotorGuard sur Android.

## Installation

### 1. Installer l'APK

1. Transférer le fichier `app-release.apk` sur votre téléphone Android
2. Ouvrir le fichier APK sur le téléphone
3. Autoriser l'installation depuis des sources inconnues si demandé
4. Suivre les instructions d'installation

**Chemin de l'APK après build** :

```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

### 2. Première ouverture

L'application s'ouvre sur l'écran de connexion.

## Connexion au Wi-Fi de l'ESP32

⚠️ **IMPORTANT** : Avant d'utiliser l'application, vous devez connecter le téléphone au Wi-Fi de l'ESP32.

### Étapes

1. Allumer l'ESP32 (le capteur doit être alimenté)
2. Ouvrir les **Paramètres Android** → **Wi-Fi**
3. Rechercher le réseau Wi-Fi nommé **MotorGuard_AP**
4. Se connecter avec le mot de passe : **motorguard123**
   - (Ces valeurs peuvent être différentes selon la configuration de l'ESP32)
5. Attendre la connexion (l'icône Wi-Fi doit apparaître)

### Vérification

Dans l'application MotorGuard :

1. Aller dans **Paramètres** (icône ⚙️ en bas)
2. Section **Configuration IoT / Réseau**
3. Cliquer sur **Test de connexion ESP32**
4. Si la connexion est réussie, vous verrez "Connecté" en vert

## Première utilisation

### 1. Se connecter

**Compte administrateur par défaut** :

- **Email** : `admin@motorguard.local`
- **Mot de passe** : `admin123`

1. Entrer l'email et le mot de passe
2. Cliquer sur **Se connecter**

⚠️ **Sécurité** : Changez le mot de passe de l'admin après la première connexion (fonctionnalité à implémenter).

### 2. Créer des techniciens (ADMIN uniquement)

1. Aller dans l'onglet **Utilisateurs** (en bas)
2. Cliquer sur le bouton **+** (flottant)
3. Remplir le formulaire :
   - Nom complet
   - Email
   - Mot de passe
   - Rôle : **TECHNICIAN**
4. Cliquer sur **Enregistrer**

### 3. Créer des moteurs

1. Aller dans l'onglet **Machines** (en bas)
2. Cliquer sur le bouton **+ Nouvelle machine**
3. Remplir le formulaire :
   - **Nom** : Ex: "Broyeur Principal"
   - **Code** : Ex: "M001" (doit être unique)
   - **Localisation** : Ex: "Atelier 3, Ligne 2"
   - **Description** : (optionnel)
   - **ESP32 UID** : Ex: "ESP32_001" (doit correspondre à l'ESP32)
4. Cliquer sur **Enregistrer**

### 4. Configurer les seuils de sécurité

1. Ouvrir une machine depuis la liste
2. Aller dans l'onglet **Sécurité**
3. Configurer les seuils :
   - Température maximale (défaut: 80°C)
   - Vibration maximale (défaut: 5 mm/s)
   - Batterie minimale (défaut: 20%)
   - Délai d'arrêt d'urgence (défaut: 5 secondes)
4. Enregistrer

## Utilisation quotidienne

### Tableau de bord

L'écran d'accueil affiche :

- **Total machines** : Nombre total de moteurs enregistrés
- **En marche** : Nombre de moteurs actuellement en fonctionnement
- **Saines** : Nombre de moteurs fonctionnant normalement
- **Critiques** : Nombre de moteurs avec alertes

### Surveiller un moteur

1. Aller dans **Machines**
2. Cliquer sur une machine
3. L'écran de contrôle affiche :
   - **Statut Wi-Fi** : Vérifier que c'est "Connecté"
   - **Vitesse (RPM)** : Vitesse actuelle du moteur
   - **Température, Vibration, Courant, Batterie** : Valeurs en temps réel
   - **Panneau de contrôle** : Boutons DÉMARRER / ARRÊT

### Démarrer un moteur

1. Ouvrir la machine
2. Vérifier que le Wi-Fi est connecté
3. Cliquer sur **DÉMARRER**
4. L'écran de confirmation de sécurité s'affiche
5. Ajuster la vitesse cible avec le slider (540-1800 RPM)
6. Cliquer sur **CONFIRMER LE DÉMARRAGE**
7. Le moteur démarre et les valeurs se mettent à jour en temps réel

### Arrêter un moteur

1. Ouvrir la machine
2. Cliquer sur **ARRÊT**
3. Le moteur s'arrête immédiatement

### Consulter l'historique

1. Ouvrir une machine
2. Aller dans l'onglet **Historique**
3. Voir les données de télémétrie enregistrées

### Consulter les statistiques

1. Ouvrir une machine
2. Aller dans l'onglet **Statistiques**
3. Voir :
   - Disponibilité (% de temps en marche)
   - Temps de marche vs arrêt
   - Nombre de démarrages
   - Dernière maintenance

## Pour les techniciens

### Voir mes tâches

1. Se connecter avec un compte **TECHNICIAN**
2. Aller dans l'onglet **Mes tâches**
3. Voir la liste des tâches assignées

### Effectuer une maintenance

1. Ouvrir une tâche
2. Cliquer sur **Commencer la maintenance**
3. Remplir le formulaire de rapport :
   - Résumé
   - Détails
   - Heure de début
   - Heure de fin
4. Envoyer le rapport
5. La tâche passe à "Terminée"

## Configuration

### Paramètres IoT / Réseau

Dans **Paramètres** → **Configuration IoT / Réseau** :

- **SSID ESP32** : Nom du réseau Wi-Fi (défaut: MotorGuard_AP)
- **Mot de passe ESP32** : Mot de passe du réseau (défaut: motorguard123)
- **URL base ESP32** : Adresse IP de l'ESP32 (défaut: http://192.168.4.1)
- **Intervalle de rafraîchissement** : Fréquence de mise à jour (défaut: 2 secondes)
- **Test de connexion ESP32** : Vérifier la connexion

### Mode de fonctionnement

- **Local autonome (ESP32 uniquement)** : Mode par défaut pour la démo
- **Serveur FastAPI (expérimental)** : Pour usage futur avec serveur

## Dépannage

### Le Wi-Fi ne se connecte pas

1. Vérifier que l'ESP32 est allumé
2. Vérifier que le SSID et le mot de passe sont corrects
3. Réessayer la connexion depuis les paramètres Android
4. Redémarrer l'ESP32 si nécessaire

### Pas de données affichées

1. Vérifier la connexion Wi-Fi dans les paramètres Android
2. Tester la connexion ESP32 dans l'app (Paramètres → Test de connexion)
3. Vérifier que l'ESP32 UID correspond dans la configuration du moteur
4. Vérifier que l'URL base ESP32 est correcte (http://192.168.4.1)

### L'application se ferme

1. Vérifier que vous avez la dernière version de l'APK
2. Redémarrer l'application
3. Si le problème persiste, réinstaller l'APK

### Les commandes ne fonctionnent pas

1. Vérifier que le Wi-Fi est connecté
2. Vérifier que l'ESP32 répond (Test de connexion)
3. Vérifier que le code moteur ou ESP32 UID est correct
4. Vérifier les logs de l'ESP32 si possible

## Démo type pour le hackathon

### Préparation

1. **Allumer l'ESP32** : S'assurer que le capteur est alimenté et fonctionne
2. **Connecter le téléphone** : Se connecter au Wi-Fi MotorGuard_AP
3. **Ouvrir l'application** : Lancer MotorGuard

### Scénario de démo

#### 1. Connexion et configuration

1. Se connecter avec `admin@motorguard.local` / `admin123`
2. Aller dans **Paramètres** → **Configuration IoT**
3. Vérifier que l'URL ESP32 = `http://192.168.4.1`
4. Cliquer sur **Test de connexion** → Doit afficher "Connecté" ✅

#### 2. Création d'une machine

1. Aller dans **Machines**
2. Cliquer sur **+ Nouvelle machine**
3. Remplir :
   - Nom : "Broyeur Principal"
   - Code : "M001"
   - ESP32 UID : "ESP32_001" (ou celui de votre ESP32)
4. Enregistrer

#### 3. Surveillance en temps réel

1. Ouvrir la machine "Broyeur Principal"
2. Montrer les valeurs temps réel :
   - RPM
   - Température
   - Vibration
   - Courant
   - Batterie
3. Expliquer que les données sont mises à jour toutes les 2 secondes

#### 4. Démarrage du moteur

1. Cliquer sur **DÉMARRER**
2. Montrer l'écran de confirmation de sécurité
3. Ajuster la vitesse cible (ex: 1500 RPM)
4. Glisser/Confirmer le démarrage
5. Observer le changement d'état :
   - Badge "En marche" (vert)
   - RPM qui augmente
   - Autres valeurs qui se mettent à jour

#### 5. Arrêt du moteur

1. Cliquer sur **ARRÊT**
2. Observer l'arrêt immédiat :
   - Badge "Arrêté" (gris)
   - RPM à 0

#### 6. Gestion des utilisateurs (ADMIN)

1. Aller dans **Utilisateurs**
2. Créer un technicien
3. Expliquer les rôles (ADMIN / TECHNICIAN)

#### 7. Statistiques et historique

1. Ouvrir une machine
2. Aller dans **Statistiques**
3. Montrer les métriques d'utilisation
4. Aller dans **Historique**
5. Montrer les données enregistrées

### Points clés à mettre en avant

✅ **Mode autonome** : Fonctionne sans serveur, uniquement téléphone + ESP32
✅ **Temps réel** : Mise à jour automatique toutes les 2 secondes
✅ **Multi-moteurs** : Gestion de plusieurs machines
✅ **Sécurité** : Confirmation avant démarrage, seuils configurables
✅ **Rôles** : ADMIN et TECHNICIAN avec permissions différentes
✅ **Hors ligne** : Toutes les données stockées localement

## Support

Pour toute question ou problème :

- Consulter la documentation technique : `docs/architecture.md`
- Vérifier les endpoints ESP32 : `docs/endpoints_for_esp32.md`
- Contacter l'équipe de développement

---

**Bonne utilisation de MotorGuard ! 🚀**
