from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from sqlmodel import Session, select

from app.database import create_db_and_tables, get_session, engine
from app.deps import get_password_hash
from app.models import User
from app.routers import (
    auth, users, motors, telemetry, maintenance, safety, iot, esp32_devices
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Au démarrage : créer les tables et l'admin par défaut
    create_db_and_tables()
    
    # Créer l'admin par défaut s'il n'existe pas
    with Session(engine) as session:
        statement = select(User).where(User.email == "admin@motorguard.local")
        admin = session.exec(statement).first()
        if not admin:
            admin = User(
                full_name="Administrateur",
                email="admin@motorguard.local",
                password_hash=get_password_hash("admin123"),
                role="ADMIN",
                is_active=True
            )
            session.add(admin)
            session.commit()
            print("✅ Admin par défaut créé : admin@motorguard.local / admin123")
    
    yield
    # Au shutdown (rien à faire pour l'instant)


app = FastAPI(
    title="MotorGuard API",
    description="API backend pour la solution IoT MotorGuard",
    version="1.0.0",
    lifespan=lifespan,
    swagger_ui_init_oauth={
        "usePkceWithAuthorizationCodeGrant": False,
    },
    swagger_ui_parameters={
        "persistAuthorization": True,  # Garder l'authentification après rechargement
    }
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifier les origines autorisées
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclure les routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(motors.router)
app.include_router(telemetry.router)
app.include_router(maintenance.router)
app.include_router(safety.router)
app.include_router(iot.router)
app.include_router(esp32_devices.router)


@app.get("/health")
def health_check():
    """Vérification de santé de l'API"""
    return {"status": "ok"}


@app.get("/")
def root():
    """Page d'accueil de l'API"""
    return {
        "message": "MotorGuard API",
        "version": "1.0.0",
        "docs": "/docs"
    }

