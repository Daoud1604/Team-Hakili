from sqlmodel import SQLModel, create_engine, Session
from pathlib import Path

# Chemin vers la base de données SQLite
DATABASE_URL = "sqlite:///./motorguard.db"

# Créer le moteur de base de données
engine = create_engine(DATABASE_URL, echo=True, connect_args={"check_same_thread": False})


def create_db_and_tables():
    """Crée toutes les tables dans la base de données"""
    SQLModel.metadata.create_all(engine)


def get_session():
    """Dépendance pour obtenir une session de base de données"""
    with Session(engine) as session:
        yield session

