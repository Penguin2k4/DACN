from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from app.controllers.predict_controller import PredictController
from app.dependencies import get_current_user_uid 
from app.database import get_db
from sqlalchemy.orm import Session
from app import models
router = APIRouter(prefix="/predict", tags=["predict"])
predict_controller = PredictController()

@router.post("/")
async def predict(
    file: UploadFile = File(...),
    model_name: str = Form(...),
    uid: str = Depends(get_current_user_uid) 
):
    print(f"🤖 Đang dự đoán cho User UID: {uid}")
    result = await predict_controller.predict(file, model_name, uid)
    
    return result
@router.get("/history")
async def get_history(uid: str = Depends(get_current_user_uid), db: Session = Depends(get_db)):
    try:
        user = db.query(models.UserDB).filter(models.UserDB.ProviderUserId == uid).first()
        if not user: raise HTTPException(status_code=404, detail="User not found")

        history = db.query(
            models.PredictionDB.PredictedLabel,
            models.PredictionDB.Confidence,
            models.PredictionDB.PredictedAt,
            models.MLModelDB.ModelName,
            models.ImageDB.ImagePath  
        ).join(models.MLModelDB, models.PredictionDB.ModelId == models.MLModelDB.ModelId)\
         .join(models.ImageDB, models.PredictionDB.ImageId == models.ImageDB.ImageId)\
         .filter(models.ImageDB.UserId == user.UserId)\
         .order_by(models.PredictionDB.PredictedAt.desc()).all()
        return [
            {
                "label": h.PredictedLabel,
                "confidence": h.Confidence,
                "date": h.PredictedAt.strftime("%d/%m/%Y %H:%M"),
                "model_name": h.ModelName,
                "image_url": f"https://ebulliently-basal-larry.ngrok-free.dev/{h.ImagePath}".replace('\\', '/')
            } for h in history
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
