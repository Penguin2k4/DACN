from sqlalchemy.orm import Session
from . import models
import datetime
def get_user_by_firebase_uid(db: Session, firebase_uid: str):
    return db.query(models.UserDB).filter(models.UserDB.ProviderUserId == firebase_uid).first()
def create_or_update_user(db: Session, uid: str, email: str, name: str, password: str = None):
    # Tìm user cũ xem có chưa
    existing_user = db.query(models.UserDB).filter(models.UserDB.ProviderUserId == uid).first()
    
    if existing_user:
        return existing_user 

    # TẠO USER MỚI
    new_user = models.UserDB(
        # Các cột định danh
        ProviderUserId=uid,
        Email=email,
        Username=name,         
        PasswordHash=password,   
        IsActive=True,          
        CreatedAt=datetime.datetime.utcnow()
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user) 
    return new_user
def create_prediction_record(db: Session, user_id: int, image_path: str, model_name: str, label: str, confidence: float):
    model_db = db.query(models.MLModelDB).filter(models.MLModelDB.ModelName == model_name).first()
    if not model_db:
        fake_path = f"ml_models/{model_name}.h5"
        model_db = models.MLModelDB(
            ModelName=model_name, 
            ModelPath=fake_path,
            IsActive=True
        )
        db.add(model_db)
        db.commit()
        db.refresh(model_db)
    new_image = models.ImageDB(
        UserId=user_id,
        ImagePath=image_path,
        Label=label, 
        UploadedAt=datetime.datetime.utcnow()
    )
    db.add(new_image)
    db.flush() 
    new_pred = models.PredictionDB(
        ImageId=new_image.ImageId,
        ModelId=model_db.ModelId,
        PredictedLabel=label,
        Confidence=confidence,
        PredictedAt=datetime.datetime.utcnow()
    )
    db.add(new_pred)
    db.commit()
    db.refresh(new_pred)
    
    return new_pred
def get_user_by_email(db: Session, email: str):
    # Tìm user trong SQL theo Email
    return db.query(models.UserDB).filter(models.UserDB.Email == email).first()