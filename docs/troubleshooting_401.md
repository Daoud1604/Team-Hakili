# Dépannage : Erreur 401 Unauthorized

## Problème

Vous obtenez une erreur `401 Unauthorized` même après vous être connecté avec succès.

## Solutions

### Solution 1 : Swagger UI - Format du token

Dans Swagger UI (`http://localhost:8000/docs`) :

1. **Connectez-vous** via `/auth/login-json`
2. **Copiez le token** depuis la réponse (champ `access_token`)
3. **Cliquez sur "Authorize"** 🔒 (en haut à droite)
4. **⚠️ IMPORTANT** : Entrez **SEULEMENT le token**, sans "Bearer"
   - ❌ **FAUX** : `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - ✅ **CORRECT** : `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
5. Cliquez sur "Authorize"
6. Vous devriez voir un cadenas vert ✅

**Pourquoi ?** Swagger UI ajoute automatiquement "Bearer " devant le token grâce à `OAuth2PasswordBearer`.

### Solution 2 : Vérifier le token

Le token doit être :

- ✅ Copié **complètement** (il est très long)
- ✅ Sans espaces avant/après
- ✅ Pas de retours à la ligne

**Exemple de token valide** :

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsImV4cCI6MTcwNjEwODAwMH0.abc123...
```

### Solution 3 : Tester avec curl

Pour vérifier si le problème vient de Swagger :

```bash
# 1. Obtenir le token
TOKEN=$(curl -s -X POST "http://localhost:8000/auth/login-json" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@motorguard.local","password":"admin123"}' \
  | jq -r '.access_token')

echo "Token: $TOKEN"

# 2. Tester avec le token
curl -X GET "http://localhost:8000/motors/" \
  -H "Authorization: Bearer $TOKEN"
```

Si ça fonctionne avec curl mais pas avec Swagger, le problème vient de la façon dont vous entrez le token dans Swagger.

### Solution 4 : Vérifier que l'utilisateur existe

Vérifiez que l'utilisateur admin existe dans la base de données :

```bash
# Via Swagger : GET /users/ (nécessite d'être connecté)
# Ou vérifier les logs du serveur au démarrage
```

Le serveur devrait afficher :

```
✅ Admin par défaut créé : admin@motorguard.local / admin123
```

### Solution 5 : Vérifier les logs du serveur

Regardez les logs du serveur FastAPI pour voir l'erreur exacte :

```bash
# Les logs s'affichent dans le terminal où uvicorn tourne
```

Erreurs possibles :

- `Could not validate credentials` → Token invalide ou expiré
- `Incorrect email or password` → Problème de connexion
- `Inactive user` → Utilisateur désactivé

### Solution 6 : Réinitialiser la base de données

Si rien ne fonctionne, réinitialisez la base :

```bash
cd backend
# Supprimer la base de données
rm motorguard.db

# Relancer le serveur (la base sera recréée)
uvicorn app.main:app --reload
```

L'admin par défaut sera recréé automatiquement.

### Solution 7 : Vérifier le format de la requête

Dans Swagger, assurez-vous que :

1. **Le Content-Type est correct** :

   - Pour `/auth/login-json` : `application/json`
   - Swagger le fait automatiquement

2. **Le format JSON est valide** :

   ```json
   {
     "email": "admin@motorguard.local",
     "password": "admin123"
   }
   ```

3. **Pas de guillemets supplémentaires** dans le body

## Test complet étape par étape

### Étape 1 : Vérifier que le serveur fonctionne

```bash
curl http://localhost:8000/health
```

Réponse attendue : `{"status":"ok"}`

### Étape 2 : Se connecter

Dans Swagger UI :

1. Aller sur `/auth/login-json`
2. Cliquer sur "Try it out"
3. Entrer :
   ```json
   {
     "email": "admin@motorguard.local",
     "password": "admin123"
   }
   ```
4. Cliquer sur "Execute"
5. **Vérifier le code de réponse** : doit être `200`
6. **Copier le token** depuis `access_token`

### Étape 3 : Autoriser

1. Cliquer sur "Authorize" 🔒
2. Dans le champ "Value", coller **SEULEMENT le token**
3. Cliquer sur "Authorize"
4. Vérifier qu'un cadenas vert ✅ apparaît

### Étape 4 : Tester un endpoint protégé

1. Aller sur `/motors/` (GET)
2. Cliquer sur "Try it out"
3. Cliquer sur "Execute"
4. **Vérifier le code de réponse** : doit être `200`, pas `401`

## Erreurs courantes

### Erreur : "Could not validate credentials"

**Cause** : Token invalide ou mal formaté

**Solution** :

- Vérifier que vous avez copié le token complet
- Vérifier qu'il n'y a pas d'espaces
- Réessayer de se connecter pour obtenir un nouveau token

### Erreur : "Incorrect email or password"

**Cause** : Identifiants incorrects

**Solution** :

- Vérifier : `admin@motorguard.local` / `admin123`
- Vérifier que l'utilisateur existe dans la base

### Erreur : Token expiré

**Cause** : Le token JWT a expiré (par défaut, pas d'expiration dans notre code, mais peut arriver)

**Solution** :

- Se reconnecter pour obtenir un nouveau token

## Test rapide avec Python

Créez un fichier `test_auth.py` :

```python
import requests

BASE_URL = "http://localhost:8000"

# 1. Login
response = requests.post(
    f"{BASE_URL}/auth/login-json",
    json={"email": "admin@motorguard.local", "password": "admin123"}
)
print(f"Login status: {response.status_code}")
token = response.json()["access_token"]
print(f"Token: {token[:50]}...")

# 2. Tester avec le token
headers = {"Authorization": f"Bearer {token}"}
response = requests.get(f"{BASE_URL}/motors/", headers=headers)
print(f"Motors status: {response.status_code}")
print(f"Response: {response.json()}")
```

Exécuter :

```bash
python test_auth.py
```

Si ça fonctionne, le problème vient de Swagger UI.

## Contact

Si le problème persiste après avoir essayé toutes ces solutions, vérifiez :

1. Les logs du serveur FastAPI
2. La version de FastAPI et des dépendances
3. Que le serveur est bien lancé sur le bon port (8000)
