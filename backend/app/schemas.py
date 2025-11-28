from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


# User schemas
class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role: str  # "ADMIN" ou "TECHNICIAN"


class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    role: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


# Motor schemas
class MotorCreate(BaseModel):
    name: str
    code: str
    location: Optional[str] = None
    description: Optional[str] = None
    esp32_uid: Optional[str] = None


class MotorUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    description: Optional[str] = None
    esp32_uid: Optional[str] = None


class MotorResponse(BaseModel):
    id: int
    name: str
    code: str
    location: Optional[str]
    description: Optional[str]
    esp32_uid: Optional[str]
    is_running: bool
    last_temperature: Optional[float]
    last_vibration: Optional[float]
    last_current: Optional[float]
    last_speed_rpm: Optional[float]
    last_battery_percent: Optional[float]
    last_update: Optional[datetime]

    class Config:
        from_attributes = True


# Telemetry schemas
class TelemetryCreate(BaseModel):
    motor_id: int
    temperature: float
    vibration: float
    current: float
    speed_rpm: float
    is_running: bool
    battery_percent: Optional[float] = None


class TelemetryResponse(BaseModel):
    id: int
    motor_id: int
    temperature: float
    vibration: float
    current: float
    speed_rpm: float
    is_running: bool
    battery_percent: Optional[float]
    created_at: datetime

    class Config:
        from_attributes = True


# Maintenance schemas
class MaintenanceTaskCreate(BaseModel):
    motor_id: int
    assigned_to_user_id: int
    title: str
    description: Optional[str] = None
    scheduled_date: datetime


class MaintenanceTaskResponse(BaseModel):
    id: int
    motor_id: int
    assigned_to_user_id: int
    created_by_user_id: int
    title: str
    description: Optional[str]
    scheduled_date: datetime
    status: str
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class MaintenanceReportCreate(BaseModel):
    task_id: int
    summary: str
    details: Optional[str] = None
    start_time: datetime
    end_time: datetime


class MaintenanceReportResponse(BaseModel):
    id: int
    task_id: int
    summary: str
    details: Optional[str]
    start_time: datetime
    end_time: datetime
    created_at: datetime

    class Config:
        from_attributes = True


# Safety schemas
class SafetyConfigCreate(BaseModel):
    motor_id: int
    max_temperature: float = 80.0
    max_vibration: float = 5.0
    min_battery_percent: float = 20.0
    emergency_stop_delay_seconds: int = 5
    enable_sms_alerts: bool = False
    sms_phone_number: Optional[str] = None


class SafetyConfigUpdate(BaseModel):
    max_temperature: Optional[float] = None
    max_vibration: Optional[float] = None
    min_battery_percent: Optional[float] = None
    emergency_stop_delay_seconds: Optional[int] = None
    enable_sms_alerts: Optional[bool] = None
    sms_phone_number: Optional[str] = None


class SafetyConfigResponse(BaseModel):
    id: int
    motor_id: int
    max_temperature: float
    max_vibration: float
    min_battery_percent: float
    emergency_stop_delay_seconds: int
    enable_sms_alerts: bool
    sms_phone_number: Optional[str]
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


# IoT schemas (pour communication ESP32)
class MotorStatusResponse(BaseModel):
    esp32_uid: str
    motor_code: str
    temperature: float
    vibration: float
    current: float
    speed_rpm: float
    is_running: bool
    battery_percent: Optional[float] = None
    timestamp: datetime


class MotorCommandRequest(BaseModel):
    action: str  # "START" ou "STOP"
    target_speed_rpm: Optional[float] = None


# ESP32 Device schemas
class ESP32DeviceCreate(BaseModel):
    esp32_uid: str
    motor_id: Optional[int] = None


class ESP32DeviceResponse(BaseModel):
    id: int
    esp32_uid: str
    api_key: str
    motor_id: Optional[int]
    is_active: bool
    created_at: datetime
    last_seen: Optional[datetime]

    class Config:
        from_attributes = True

