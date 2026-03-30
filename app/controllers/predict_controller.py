import shutil
import os
from fastapi import UploadFile
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app import crud
from app.services.predict_service import PredictService

class PredictController:
    def __init__(self):
        self.ai_service = PredictService()

    async def predict(self, file: UploadFile, model_name: str, uid: str = None):
        upload_dir = "uploads"
        os.makedirs(upload_dir, exist_ok=True)
        file_location = f"{upload_dir}/{file.filename}"
        with open(file_location, "wb+") as buffer:
            shutil.copyfileobj(file.file, buffer)
        with open(file_location, "rb") as f:
            image_bytes = f.read()
        result = self.ai_service.predict_image(image_bytes, model_name)
        db: Session = SessionLocal()
        try:
            user_db_id = 1 
            if uid:
                user = crud.get_user_by_firebase_uid(db, uid)
                if user:
                    user_db_id = user.UserId
                else:
                    print(f"⚠️ UID {uid} hợp lệ nhưng chưa đồng bộ sang SQL Server.")
            crud.create_prediction_record(
                db=db,
                user_id=user_db_id,
                image_path=file_location,
                model_name=model_name,
                label=result['label'],
                confidence=result['confidence']
            )
            print(f"✅ Đã lưu kết quả dự đoán cho User ID: {user_db_id}")

        except Exception as e:
            print(f"❌ Lỗi lưu Database: {e}")
        finally:
            db.close()
        return result