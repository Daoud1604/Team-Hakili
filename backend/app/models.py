from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, List
from datetime import datetime
from enum import Enum


class UserRole(str, Enum):
    ADMIN = "ADMIN"
    TECHNICIAN = "TECHNICIAN"


class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    full_name: str
    email: str = Field(index=True, unique=True)
    password_hash: str
    role: str = Field(index=True)  # "ADMIN" ou "TECHNICIAN"
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Motor(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str  # ex: "Broyeur Principal"
    code: str = Field(index=True, unique=True)  # ex: "M001"
    location: Optional[str] = None
    description: Optional[str] = None
    
    esp32_uid: Optional[str] = Field(default=None, index=True)
    # identifiant boîtier (par ex. "ESP32_001")
    
    is_running: bool = False
    last_temperature: Optional[float] = None
    last_vibration: Optional[float] = None
    last_current: Optional[float] = None
    last_speed_rpm: Optional[float] = None
    last_battery_percent: Optional[float] = None
    last_update: Optional[datetime] = None


class Telemetry(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    motor_id: int = Field(foreign_key="motor.id")
    temperature: float
    vibration: float
    current: float
    speed_rpm: float
    is_running: bool
    battery_percent: Optional[float] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class TaskStatus(str, Enum):
    PLANNED = "PLANNED"
    IN_PROGRESS = "IN_PROGRESS"
    DONE = "DONE"
    CANCELLED = "CANCELLED"


class MaintenanceTask(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    motor_id: int = Field(foreign_key="motor.id")
    assigned_to_user_id: int = Field(foreign_key="user.id")
    created_by_user_id: int = Field(foreign_key="user.id")
    
    title: str
    description: Optional[str] = None
    scheduled_date: datetime
    status: str = Field(default="PLANNED")  # PLANNED, IN_PROGRESS, DONE, CANCELLED
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None


class MaintenanceReport(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    task_id: int = Field(foreign_key="maintenancetask.id", unique=True)
    summary: str
    details: Optional[str] = None
    start_time: datetime
    end_time: datetime
    created_at: datetime = Field(default_factory=datetime.utcnow)


class SafetyConfig(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    motor_id: int = Field(foreign_key="motor.id", unique=True)
    
    max_temperature: float = Field(default=80.0)
    max_vibration: float = Field(default=5.0)
    min_battery_percent: float = Field(default=20.0)
    emergency_stop_delay_seconds: int = Field(default=5)
    enable_sms_alerts: bool = Field(default=False)
    sms_phone_number: Optional[str] = None
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None


class Notification(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    motor_id: Optional[int] = Field(default=None, foreign_key="motor.id")
    user_id: Optional[int] = Field(default=None, foreign_key="user.id")
    
    type: str  # "connection_lost", "high_temperature", "high_vibration", "low_battery", "maintenance_due"
    title: str
    message: str
    is_read: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)


class ESP32Device(SQLModel, table=True):
    """Modèle pour enregistrer les ESP32 autorisés avec API Key"""
    id: Optional[int] = Field(default=None, primary_key=True)
    esp32_uid: str = Field(unique=True, index=True)
    api_key: str = Field(unique=True, index=True)  # Clé API unique pour authentification
    motor_id: Optional[int] = Field(default=None, foreign_key="motor.id")
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_seen: Optional[datetime] = None

