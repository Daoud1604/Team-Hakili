from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from typing import List, Optional
from datetime import datetime, timedelta

from app.database import get_session
from app.deps import get_current_active_user
from app.models import Motor, Telemetry
from app.schemas import TelemetryCreate, TelemetryResponse

router = APIRouter(prefix="/telemetry", tags=["telemetry"])


@router.post("/", response_model=TelemetryResponse, status_code=status.HTTP_201_CREATED)
def create_telemetry(
    telemetry_data: TelemetryCreate,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Créer un point de télémétrie"""
    # Vérifier que le moteur existe
    statement = select(Motor).where(Motor.id == telemetry_data.motor_id)
    motor = session.exec(statement).first()
    if not motor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor not found"
        )
    
    # Créer la télémétrie
    new_telemetry = Telemetry(**telemetry_data.dict())
    session.add(new_telemetry)
    
    # Mettre à jour les dernières valeurs du moteur
    motor.is_running = telemetry_data.is_running
    motor.last_temperature = telemetry_data.temperature
    motor.last_vibration = telemetry_data.vibration
    motor.last_current = telemetry_data.current
    motor.last_speed_rpm = telemetry_data.speed_rpm
    motor.last_battery_percent = telemetry_data.battery_percent
    motor.last_update = datetime.utcnow()
    session.add(motor)
    
    session.commit()
    session.refresh(new_telemetry)
    return new_telemetry


@router.get("/motor/{motor_id}", response_model=List[TelemetryResponse])
def get_motor_telemetry(
    motor_id: int,
    limit: Optional[int] = 100,
    hours: Optional[int] = 24,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Obtenir l'historique de télémétrie d'un moteur"""
    # Vérifier que le moteur existe
    statement = select(Motor).where(Motor.id == motor_id)
    motor = session.exec(statement).first()
    if not motor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor not found"
        )
    
    # Calculer la date de début
    start_date = datetime.utcnow() - timedelta(hours=hours)
    
    # Récupérer la télémétrie
    statement = (
        select(Telemetry)
        .where(Telemetry.motor_id == motor_id)
        .where(Telemetry.created_at >= start_date)
        .order_by(Telemetry.created_at.desc())
        .limit(limit)
    )
    telemetry_list = session.exec(statement).all()
    return telemetry_list


@router.get("/motor/{motor_id}/latest", response_model=TelemetryResponse)
def get_latest_telemetry(
    motor_id: int,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Obtenir la dernière télémétrie d'un moteur"""
    statement = (
        select(Telemetry)
        .where(Telemetry.motor_id == motor_id)
        .order_by(Telemetry.created_at.desc())
        .limit(1)
    )
    telemetry = session.exec(statement).first()
    if not telemetry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No telemetry data found for this motor"
        )
    return telemetry

