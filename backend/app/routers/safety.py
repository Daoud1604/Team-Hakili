from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from datetime import datetime

from app.database import get_session
from app.deps import get_current_active_user
from app.models import Motor, SafetyConfig
from app.schemas import SafetyConfigCreate, SafetyConfigUpdate, SafetyConfigResponse

router = APIRouter(prefix="/safety", tags=["safety"])


@router.post("/configs", response_model=SafetyConfigResponse, status_code=status.HTTP_201_CREATED)
def create_safety_config(
    config_data: SafetyConfigCreate,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Créer une configuration de sécurité pour un moteur"""
    # Vérifier que le moteur existe
    statement = select(Motor).where(Motor.id == config_data.motor_id)
    motor = session.exec(statement).first()
    if not motor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor not found"
        )
    
    # Vérifier qu'il n'y a pas déjà une config
    statement = select(SafetyConfig).where(SafetyConfig.motor_id == config_data.motor_id)
    existing_config = session.exec(statement).first()
    if existing_config:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Safety config already exists for this motor"
        )
    
    new_config = SafetyConfig(**config_data.dict())
    session.add(new_config)
    session.commit()
    session.refresh(new_config)
    return new_config


@router.get("/configs/motor/{motor_id}", response_model=SafetyConfigResponse)
def get_motor_safety_config(
    motor_id: int,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Obtenir la configuration de sécurité d'un moteur"""
    statement = select(SafetyConfig).where(SafetyConfig.motor_id == motor_id)
    config = session.exec(statement).first()
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Safety config not found for this motor"
        )
    return config


@router.put("/configs/motor/{motor_id}", response_model=SafetyConfigResponse)
def update_safety_config(
    motor_id: int,
    config_data: SafetyConfigUpdate,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Mettre à jour la configuration de sécurité d'un moteur"""
    statement = select(SafetyConfig).where(SafetyConfig.motor_id == motor_id)
    config = session.exec(statement).first()
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Safety config not found for this motor"
        )
    
    update_data = config_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(config, key, value)
    
    config.updated_at = datetime.utcnow()
    session.add(config)
    session.commit()
    session.refresh(config)
    return config

