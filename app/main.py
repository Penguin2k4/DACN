# app/main.py
import uvicorn
import firebase_admin
from app.routes import auth_route, user_route
from firebase_admin import credentials
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
from app.routes import predict_route 
Base.metadata.create_all(bind=engine)
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)

app = FastAPI(title="Garbage Classification API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.include_router(auth_route.router, prefix="/auth", tags=["Auth"])
app.include_router(predict_route.router)
app.include_router(user_route.router)
@app.get("/")
def root():
    return {"message": "Server đang chạy ngon lành! "}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)