from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from datetime import datetime

from app.database import get_session
from app.deps import get_current_active_user, get_esp32_device_by_api_key
from app.models import Motor, Telemetry, ESP32Device
from app.schemas import MotorStatusResponse, MotorCommandRequest, TelemetryCreate

router = APIRouter(prefix="/iot", tags=["iot"])


@router.get("/motor/status", response_model=MotorStatusResponse)
def get_motor_status(
    esp32_uid: str = None,
    motor_code: str = None,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """
    Obtenir l'état actuel d'un moteur depuis l'ESP32.
    Cette route simule ce que l'ESP32 devrait exposer.
    En production, cette route serait appelée directement par l'ESP32.
    """
    # Rechercher le moteur
    statement = None
    if esp32_uid:
        statement = select(Motor).where(Motor.esp32_uid == esp32_uid)
    elif motor_code:
        statement = select(Motor).where(Motor.code == motor_code)
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="esp32_uid or motor_code required"
        )
    
    motor = session.exec(statement).first()
    if not motor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor not found"
        )
    
    # Retourner l'état actuel du moteur
    return MotorStatusResponse(
        esp32_uid=motor.esp32_uid or "UNKNOWN",
        motor_code=motor.code,
        temperature=motor.last_temperature or 0.0,
        vibration=motor.last_vibration or 0.0,
        current=motor.last_current or 0.0,
        speed_rpm=motor.last_speed_rpm or 0.0,
        is_running=motor.is_running,
        battery_percent=motor.last_battery_percent,
        timestamp=motor.last_update or datetime.utcnow()
    )


@router.post("/motor/command")
def send_motor_command(
    command: MotorCommandRequest,
    esp32_uid: str = None,
    motor_code: str = None,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """
    Envoyer une commande au moteur via l'ESP32.
    Cette route simule ce que l'ESP32 devrait exposer.
    En production, cette route serait appelée directement par l'ESP32.
    """
    # Rechercher le moteur
    statement = None
    if esp32_uid:
        statement = select(Motor).where(Motor.esp32_uid == esp32_uid)
    elif motor_code:
        statement = select(Motor).where(Motor.code == motor_code)
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="esp32_uid or motor_code required"
        )
    
    motor = session.exec(statement).first()
    if not motor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor not found"
        )
    
    # Mettre à jour l'état du moteur selon la commande
    if command.action == "START":
        motor.is_running = True
        if command.target_speed_rpm:
            motor.last_speed_rpm = command.target_speed_rpm
    elif command.action == "STOP":
        motor.is_running = False
        motor.last_speed_rpm = 0.0
    
    motor.last_update = datetime.utcnow()
    session.add(motor)
    session.commit()
    
    return {"status": "ok", "message": f"Command {command.action} executed"}


@router.post("/telemetry/from-esp32", status_code=status.HTTP_201_CREATED)
def receive_telemetry_from_esp32(
    telemetry_data: TelemetryCreate,
    esp32_device: ESP32Device = Depends(get_esp32_device_by_api_key),
    session: Session = Depends(get_session)
):
    """
    Endpoint sécurisé pour recevoir la télémétrie directement de l'ESP32.
    Authentification via API Key dans le header X-API-Key.
    """
    # Utiliser le motor_id associé à l'ESP32
    motor_id = esp32_device.motor_id
    if not motor_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ESP32 not associated with a motor"
        )
    
    # Vérifier que le motor_id correspond
    if telemetry_data.motor_id != motor_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Motor ID mismatch"
        )
    
    # Créer la télémétrie
    new_telemetry = Telemetry(
        motor_id=motor_id,
        temperature=telemetry_data.temperature,
        vibration=telemetry_data.vibration,
        current=telemetry_data.current,
        speed_rpm=telemetry_data.speed_rpm,
        is_running=telemetry_data.is_running,
        battery_percent=telemetry_data.battery_percent,
    )
    session.add(new_telemetry)
    
    # Mettre à jour le moteur avec les dernières valeurs
    motor = session.get(Motor, motor_id)
    if motor:
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
    
    return {"status": "ok", "telemetry_id": new_telemetry.id}

