from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from typing import List
import secrets
from datetime import datetime

from app.database import get_session
from app.deps import get_current_admin_user
from app.models import ESP32Device, Motor
from app.schemas import ESP32DeviceCreate, ESP32DeviceResponse

router = APIRouter(prefix="/esp32-devices", tags=["esp32-devices"])


def generate_api_key() -> str:
    """Génère une clé API unique de 32 caractères"""
    return secrets.token_urlsafe(32)


@router.post("/", response_model=ESP32DeviceResponse, status_code=status.HTTP_201_CREATED)
def create_esp32_device(
    device_data: ESP32DeviceCreate,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_admin_user)
):
    """Créer un nouveau device ESP32 avec une API Key générée automatiquement"""
    # Vérifier que l'ESP32 n'existe pas déjà
    statement = select(ESP32Device).where(ESP32Device.esp32_uid == device_data.esp32_uid)
    existing = session.exec(statement).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ESP32 device with this UID already exists"
        )
    
    # Vérifier que le moteur existe si motor_id est fourni
    if device_data.motor_id:
        motor = session.get(Motor, device_data.motor_id)
        if not motor:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Motor not found"
            )
    
    # Générer une API Key unique
    api_key = generate_api_key()
    
    # Créer le device
    new_device = ESP32Device(
        esp32_uid=device_data.esp32_uid,
        api_key=api_key,
        motor_id=device_data.motor_id,
        is_active=True,
    )
    session.add(new_device)
    session.commit()
    session.refresh(new_device)
    
    return new_device


@router.get("/", response_model=List[ESP32DeviceResponse])
def list_esp32_devices(
    session: Session = Depends(get_session),
    current_user = Depends(get_current_admin_user)
):
    """Liste tous les devices ESP32"""
    statement = select(ESP32Device).order_by(ESP32Device.created_at.desc())
    devices = session.exec(statement).all()
    return devices


@router.get("/{device_id}", response_model=ESP32DeviceResponse)
def get_esp32_device(
    device_id: int,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_admin_user)
):
    """Récupérer un device ESP32 par ID"""
    device = session.get(ESP32Device, device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ESP32 device not found"
        )
    return device


@router.patch("/{device_id}/motor", response_model=ESP32DeviceResponse)
def associate_motor_to_esp32(
    device_id: int,
    motor_id: int,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_admin_user)
):
    """Associer un moteur à un ESP32"""
    device = session.get(ESP32Device, device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ESP32 device not found"
        )
    
    motor = session.get(Motor, motor_id)
    if not motor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor not found"
        )
    
    device.motor_id = motor_id
    session.add(device)
    session.commit()
    session.refresh(device)
    
    return device


@router.post("/{device_id}/regenerate-api-key", response_model=ESP32DeviceResponse)
def regenerate_api_key(
    device_id: int,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_admin_user)
):
    """Régénérer l'API Key d'un ESP32"""
    device = session.get(ESP32Device, device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ESP32 device not found"
        )
    
    device.api_key = generate_api_key()
    session.add(device)
    session.commit()
    session.refresh(device)
    
    return device


@router.patch("/{device_id}/activate", response_model=ESP32DeviceResponse)
def activate_esp32_device(
    device_id: int,
    is_active: bool,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_admin_user)
):
    """Activer ou désactiver un ESP32"""
    device = session.get(ESP32Device, device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ESP32 device not found"
        )
    
    device.is_active = is_active
    session.add(device)
    session.commit()
    session.refresh(device)
    
    return device


@router.delete("/{device_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_esp32_device(
    device_id: int,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_admin_user)
):
    """Supprimer un device ESP32"""
    device = session.get(ESP32Device, device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ESP32 device not found"
        )
    
    session.delete(device)
    session.commit()
    return None

