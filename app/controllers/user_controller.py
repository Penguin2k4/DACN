import os
import shutil
from sqlalchemy.orm import Session
from app import models

class UserController:
    def __init__(self):
        self.upload_dir = "uploads/avatars"
        os.makedirs(self.upload_dir, exist_ok=True)
    async def update_profile(self, db: Session, uid: str, username: str, avatar: None):
        try:
            user = db.query(models.UserDB).filter(models.UserDB.ProviderUserId == uid).first()
            if not user:
                return {"success": False, "message": "User không tồn tại"}
            user.Username = username
            if avatar:
                file_ext = avatar.filename.split(".")[-1]
                file_name = f"avatar_{uid}.{file_ext}"
                file_path = os.path.join(self.upload_dir, file_name)
                with open(file_path, "wb") as buffer:
                    shutil.copyfileobj(avatar.file, buffer)
                # Cập nhật đường dẫn vào database (dùng cột AvatarPath)
                user.AvatarPath = file_path.replace("\\", "/")
            db.commit()
            
            # Trả về thông tin mới để App cập nhật giao diện
            return {
                "success": True,
                "username": user.Username,
                "avatar_url": f"https://ebulliently-basal-larry.ngrok-free.dev/{user.AvatarPath}" if user.AvatarPath else None
            }
        except Exception as e:
            db.rollback()
            return {"success": False, "message": str(e)}