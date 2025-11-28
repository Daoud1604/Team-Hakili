from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from typing import List

from app.database import get_session
from app.deps import get_current_active_user
from app.models import Motor
from app.schemas import MotorCreate, MotorUpdate, MotorResponse

router = APIRouter(prefix="/motors", tags=["motors"])


@router.post("/", response_model=MotorResponse, status_code=status.HTTP_201_CREATED)
def create_motor(
    motor_data: MotorCreate,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Créer un nouveau moteur"""
    # Vérifier si le code existe déjà
    statement = select(Motor).where(Motor.code == motor_data.code)
    existing_motor = session.exec(statement).first()
    if existing_motor:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Motor code already exists"
        )
    
    new_motor = Motor(**motor_data.dict())
    session.add(new_motor)
    session.commit()
    session.refresh(new_motor)
    return new_motor


@router.get("/", response_model=List[MotorResponse])
def list_motors(
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Lister tous les moteurs"""
    statement = select(Motor)
    motors = session.exec(statement).all()
    return motors


@router.get("/{motor_id}", response_model=MotorResponse)
def get_motor(
    motor_id: int,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Obtenir un moteur par ID"""
    statement = select(Motor).where(Motor.id == motor_id)
    motor = session.exec(statement).first()
    if not motor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor not found"
        )
    return motor


@router.put("/{motor_id}", response_model=MotorResponse)
def update_motor(
    motor_id: int,
    motor_data: MotorUpdate,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Mettre à jour un moteur"""
    statement = select(Motor).where(Motor.id == motor_id)
    motor = session.exec(statement).first()
    if not motor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor not found"
        )
    
    update_data = motor_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(motor, key, value)
    
    session.add(motor)
    session.commit()
    session.refresh(motor)
    return motor


@router.delete("/{motor_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_motor(
    motor_id: int,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_active_user)
):
    """Supprimer un moteur"""
    statement = select(Motor).where(Motor.id == motor_id)
    motor = session.exec(statement).first()
    if not motor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor not found"
        )
    
    session.delete(motor)
    session.commit()
    return None

