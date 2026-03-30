from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base
import datetime
class UserDB(Base):
    __tablename__ = "Users"
    UserId = Column(Integer, primary_key=True, index=True)
    ProviderUserId = Column(String, unique=True, index=True) # UID Google
    Email = Column(String)
    Username = Column(String) 
    PasswordHash = Column(String, nullable=True)
    IsActive = Column(Boolean, default=True)
    CreatedAt = Column(DateTime, default=datetime.datetime.utcnow) 
    AvatarPath = Column(String, nullable=True)
class MLModelDB(Base):
    __tablename__ = "MLModels"
    ModelId = Column(Integer, primary_key=True, index=True)
    ModelName = Column(String, unique=True)
    ModelPath = Column(String)
    IsActive = Column(Boolean, default=True)
class ImageDB(Base):
    __tablename__ = "Images"

    ImageId = Column(Integer, primary_key=True, index=True)
    UserId = Column(Integer, ForeignKey("Users.UserId"))
    ImagePath = Column(String)
    Label = Column(String)
    UploadedAt = Column(DateTime, default=datetime.datetime.utcnow)
class PredictionDB(Base):
    __tablename__ = "Predictions"

    PredictionId = Column(Integer, primary_key=True, index=True)
    ImageId = Column(Integer, ForeignKey("Images.ImageId"))
    ModelId = Column(Integer, ForeignKey("MLModels.ModelId"))
    PredictedLabel = Column(String)
    Confidence = Column(Float)
    PredictedAt = Column(DateTime, default=datetime.datetime.utcnow)