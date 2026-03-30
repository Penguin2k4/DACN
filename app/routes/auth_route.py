from fastapi import APIRouter
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app import crud, models
from app.controllers.auth_controller import AuthController

router = APIRouter()
controller = AuthController()
class UserData(BaseModel):
    firebase_uid: str
    email: str
    full_name: str = "Unknown"
    password: str = ""  
class CheckUserRequest(BaseModel):
    firebase_uid: str
@router.post("/check-status")
async def check_user_status(data: CheckUserRequest):
    db: Session = SessionLocal()
    try:
        user = db.query(models.UserDB).filter(models.UserDB.ProviderUserId == data.firebase_uid).first()
        if user:
            return {"exists": True}
        else:
            return {"exists": False}
    finally:
        db.close()
@router.post("/sync")
async def sync_user_endpoint(data: UserData):
    return await controller.sync_user(
        uid=data.firebase_uid, 
        email=data.email, 
        full_name=data.full_name,
        password=data.password 
    )