from fastapi import Depends, HTTPException, status, Header
from fastapi.security import OAuth2PasswordBearer
from sqlmodel import Session, select
from jose import JWTError, jwt
import bcrypt
from typing import Optional

from app.database import get_session
from app.models import User, ESP32Device
from datetime import datetime

# Configuration JWT
SECRET_KEY = "motorguard-secret-key-change-in-production"
ALGORITHM = "HS256"

# Configuration OAuth2 pour Swagger UI
# Le flow "password" permet de se connecter directement avec username/password
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="auth/login",
    scheme_name="OAuth2",
    description="Entrez votre email dans 'username' et votre mot de passe dans 'password'"
)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Vérifie un mot de passe en clair contre un hash"""
    try:
        # Si le hash commence par $2b$, c'est un hash bcrypt
        if hashed_password.startswith("$2b$") or hashed_password.startswith("$2a$"):
            return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
        # Sinon, comparaison directe (pour compatibilité avec les mots de passe en clair en dev)
        return plain_password == hashed_password
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    """Hash un mot de passe"""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')


def create_access_token(data: dict) -> str:
    """Crée un token JWT"""
    to_encode = data.copy()
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    session: Session = Depends(get_session)
) -> User:
    """Récupère l'utilisateur actuel à partir du token JWT"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    statement = select(User).where(User.id == user_id)
    user = session.exec(statement).first()
    if user is None:
        raise credentials_exception
    return user


async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Vérifie que l'utilisateur actuel est actif"""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


async def get_current_admin_user(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """Vérifie que l'utilisateur actuel est un ADMIN"""
    if current_user.role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user




async def get_esp32_device_by_api_key(
    x_api_key: str = Header(..., alias="X-API-Key", description="API Key de l'ESP32"),
    session: Session = Depends(get_session)
) -> ESP32Device:
    """Vérifie l'API Key de l'ESP32 et retourne le device"""
    statement = select(ESP32Device).where(
        ESP32Device.api_key == x_api_key,
        ESP32Device.is_active == True
    )
    device = session.exec(statement).first()
    
    if not device:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or inactive API key"
        )
    
    # Mettre à jour last_seen
    device.last_seen = datetime.utcnow()
    session.add(device)
    session.commit()
    session.refresh(device)
    
    return device

