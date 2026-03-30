from sqlalchemy.orm import Session
from app.database import SessionLocal
from app import crud

class AuthController:
    # --- SỬA DÒNG NÀY: Thêm tham số password ---
    async def sync_user(self, uid: str, email: str, full_name: str, password: str = None):
        db: Session = SessionLocal()
        try:
            # Gọi CRUD truyền thêm password xuống
            user = crud.create_or_update_user(
                db=db,
                uid=uid,
                email=email,
                name=full_name,
                password=password # <--- QUAN TRỌNG: Truyền tiếp xuống CRUD
            )
            return {
                "message": "User synced successfully",
                "user_id": user.UserId,
                "email": user.Email
            }
        except Exception as e:
            print(f"❌ Lỗi Sync User: {e}")
            return {"error": str(e)}
        finally:
            db.close()
    async def login(self, email: str, password: str):
        db: Session = SessionLocal()
        try:
            # 1. Tìm user trong DB
            user = crud.get_user_by_email(db, email=email)
            
            if not user:
                return {"success": False, "message": "Email không tồn tại"}
            
            if user.PasswordHash != password:
                return {"success": False, "message": "Sai mật khẩu"}
            return {
                "success": True,
                "message": "Login successful",
                "data": {
                    "user_id": user.UserId,
                    "email": user.Email,
                    "full_name": user.Username,
                    "firebase_uid": user.ProviderUserId
                }
            }
        except Exception as e:
            print(f"❌ Lỗi Login: {e}")
            return {"success": False, "message": f"Lỗi Server: {str(e)}"}
        finally:
            db.close()