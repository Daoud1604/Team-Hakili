# Guide d'authentification dans Swagger UI

## Problème : Vous voyez "Client credentials" au lieu du formulaire username/password

### Explication

Swagger UI peut afficher plusieurs flows OAuth2. Il faut sélectionner le bon :

- ❌ **"Client credentials"** : Pour authentifier des applications (client_id/client_secret)
- ✅ **"OAuth2" / "OAuth2PasswordBearer"** : Pour authentifier des utilisateurs (username/password)

### Solution : Trouver le bon flow

1. **Cliquez sur "Authorize"** 🔒 (en haut à droite)

2. **Si vous voyez plusieurs flows**, cherchez celui qui s'appelle :

   - "OAuth2"
   - "OAuth2PasswordBearer"
   - "OAuth2 (password)"
   - Ou simplement celui qui a des champs "username" et "password"

3. **NE PAS utiliser** celui qui s'appelle :
   - "Client credentials"
   - Celui qui demande "client_id" et "client_secret"

### Utilisation du flow "password"

Une fois que vous avez trouvé le bon flow (celui avec username/password) :

1. **username** : Entrez votre **EMAIL** → `admin@motorguard.local`

   - ⚠️ Le champ s'appelle "username" mais utilisez votre email

2. **password** : Entrez votre mot de passe → `admin123`

3. Cliquez sur **"Authorize"**

4. ✅ **C'est tout !** Vous êtes connecté et pouvez tester toutes les API

### Vérification

Après avoir cliqué sur "Authorize", vous devriez voir :

- ✅ Un cadenas vert à côté de "Authorize"
- ✅ Les endpoints protégés sont maintenant accessibles
- ✅ Vous pouvez tester les API sans erreur 401

### Si vous ne trouvez pas le flow "password"

**Solution alternative** : Utiliser l'endpoint `/auth/login-json` manuellement

1. Allez sur `/auth/login-json` dans Swagger
2. Cliquez sur "Try it out"
3. Entrez :
   ```json
   {
     "email": "admin@motorguard.local",
     "password": "admin123"
   }
   ```
4. Cliquez sur "Execute"
5. Copiez le `access_token` de la réponse
6. Cliquez sur "Authorize"
7. Collez le token dans le champ "Value" (sans "Bearer")
8. Cliquez sur "Authorize"

### Capture d'écran attendue

Quand vous cliquez sur "Authorize", vous devriez voir quelque chose comme :

```
┌─────────────────────────────────────┐
│ OAuth2                              │
│                                     │
│ username: [admin@motorguard.local] │
│ password: [••••••••]                │
│                                     │
│ [Authorize] [Cancel]                │
└─────────────────────────────────────┘
```

**PAS** :

```
┌─────────────────────────────────────┐
│ Client credentials                  │
│                                     │
│ client_id: [        ]               │
│ client_secret: [        ]           │
│                                     │
│ [Authorize] [Cancel]                │
└─────────────────────────────────────┘
```

### Dépannage

**Q : Je ne vois que "Client credentials"**

- R : Cherchez dans la liste, il peut y avoir plusieurs flows. Le flow "password" devrait être là aussi.

**Q : Le flow "password" n'apparaît pas**

- R : Vérifiez que le serveur est bien lancé et que vous êtes sur `http://localhost:8000/docs`
- R : Essayez de rafraîchir la page (F5)
- R : Utilisez la méthode alternative avec `/auth/login-json`

**Q : J'ai entré email/password mais j'ai toujours 401**

- R : Vérifiez que vous utilisez le bon flow (celui avec username/password, pas client_id/client_secret)
- R : Vérifiez que l'email et le mot de passe sont corrects
- R : Vérifiez les logs du serveur pour voir l'erreur exacte
