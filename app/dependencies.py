# app/dependencies.py
from fastapi import Header, HTTPException
from firebase_admin import auth

async def get_current_user_uid(authorization: str = Header(None)):
    if not authorization:
        return None 

    try:
        token = authorization.split(" ")[1]
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
        return uid
    except Exception as e:
        print(f"Lỗi Auth: {e}")
        return None