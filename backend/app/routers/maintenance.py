from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from typing import List
from datetime import datetime

from app.database import get_session
from app.deps import get_current_active_user, get_current_admin_user
from app.models import Motor, User, MaintenanceTask, MaintenanceReport
from app.schemas import (
    MaintenanceTaskCreate, MaintenanceTaskResponse,
    MaintenanceReportCreate, MaintenanceReportResponse
)

router = APIRouter(prefix="/maintenance", tags=["maintenance"])


@router.post("/tasks", response_model=MaintenanceTaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(
    task_data: MaintenanceTaskCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_admin_user)
):
    """Créer une tâche de maintenance (ADMIN uniquement)"""
    # Vérifier que le moteur existe
    statement = select(Motor).where(Motor.id == task_data.motor_id)
    motor = session.exec(statement).first()
    if not motor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor not found"
        )
    
    # Vérifier que l'utilisateur assigné existe
    statement = select(User).where(User.id == task_data.assigned_to_user_id)
    assigned_user = session.exec(statement).first()
    if not assigned_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assigned user not found"
        )
    
    new_task = MaintenanceTask(
        **task_data.dict(),
        created_by_user_id=current_user.id
    )
    session.add(new_task)
    session.commit()
    session.refresh(new_task)
    return new_task


@router.get("/tasks", response_model=List[MaintenanceTaskResponse])
def list_tasks(
    motor_id: int = None,
    assigned_to_user_id: int = None,
    status: str = None,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_active_user)
):
    """Lister les tâches de maintenance"""
    statement = select(MaintenanceTask)
    
    # Filtres selon le rôle
    if current_user.role == "TECHNICIAN":
        # Les techniciens voient uniquement leurs tâches
        statement = statement.where(MaintenanceTask.assigned_to_user_id == current_user.id)
    elif motor_id:
        statement = statement.where(MaintenanceTask.motor_id == motor_id)
    elif assigned_to_user_id:
        statement = statement.where(MaintenanceTask.assigned_to_user_id == assigned_to_user_id)
    
    if status:
        statement = statement.where(MaintenanceTask.status == status)
    
    tasks = session.exec(statement).all()
    return tasks


@router.get("/tasks/{task_id}", response_model=MaintenanceTaskResponse)
def get_task(
    task_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_active_user)
):
    """Obtenir une tâche de maintenance"""
    statement = select(MaintenanceTask).where(MaintenanceTask.id == task_id)
    task = session.exec(statement).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    # Vérifier les permissions
    if current_user.role == "TECHNICIAN" and task.assigned_to_user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    return task


@router.put("/tasks/{task_id}/status", response_model=MaintenanceTaskResponse)
def update_task_status(
    task_id: int,
    new_status: str,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_active_user)
):
    """Mettre à jour le statut d'une tâche"""
    statement = select(MaintenanceTask).where(MaintenanceTask.id == task_id)
    task = session.exec(statement).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    # Vérifier les permissions
    if current_user.role == "TECHNICIAN" and task.assigned_to_user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    task.status = new_status
    task.updated_at = datetime.utcnow()
    session.add(task)
    session.commit()
    session.refresh(task)
    return task


@router.post("/reports", response_model=MaintenanceReportResponse, status_code=status.HTTP_201_CREATED)
def create_report(
    report_data: MaintenanceReportCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_active_user)
):
    """Créer un rapport de maintenance"""
    # Vérifier que la tâche existe
    statement = select(MaintenanceTask).where(MaintenanceTask.id == report_data.task_id)
    task = session.exec(statement).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    # Vérifier les permissions
    if current_user.role == "TECHNICIAN" and task.assigned_to_user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    # Vérifier qu'il n'y a pas déjà un rapport
    statement = select(MaintenanceReport).where(MaintenanceReport.task_id == report_data.task_id)
    existing_report = session.exec(statement).first()
    if existing_report:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Report already exists for this task"
        )
    
    new_report = MaintenanceReport(**report_data.dict())
    session.add(new_report)
    
    # Mettre à jour le statut de la tâche
    task.status = "DONE"
    task.updated_at = datetime.utcnow()
    session.add(task)
    
    session.commit()
    session.refresh(new_report)
    return new_report


@router.get("/reports/task/{task_id}", response_model=MaintenanceReportResponse)
def get_task_report(
    task_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_active_user)
):
    """Obtenir le rapport d'une tâche"""
    statement = select(MaintenanceReport).where(MaintenanceReport.task_id == task_id)
    report = session.exec(statement).first()
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    return report

