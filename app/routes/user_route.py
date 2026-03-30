from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.dependencies import get_current_user_uid
from app.controllers.user_controller import UserController

router = APIRouter(prefix="/user", tags=["user"])
user_controller = UserController()

@router.post("/update")
async def update_user_profile(
    username: str = Form(...),
    avatar: UploadFile = File(None), 
    uid: str = Depends(get_current_user_uid),
    db: Session = Depends(get_db)
):
    result = await user_controller.update_profile(db, uid, username, avatar)
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    return result