from config.database import get_db
from fastapi import APIRouter, Depends, HTTPException, status,BackgroundTasks,File, UploadFile
from models.user import User
import shutil
import os
from schemas.user import UserCreate,UserDetailResponse,UserUpdate,LoginRequest
from sqlalchemy.orm import Session
from services.email_service import send_verification_email
from auth import create_token,get_current_user,create_email_verification_token
from auth import (
    create_token, 
    get_current_user, 
    create_email_verification_token, 
    get_password_hash, 
    verify_password
)
router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/")
def get_my_profile(
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    db_user = db.query(User).filter(User.id == user["userId"]).first()

    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    return db_user

@router.post("/profile-image")
def upload_profile_image(
    file: UploadFile = File(...),
    user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_user = db.query(User).filter(User.id == user["userId"]).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    upload_dir = "uploads"
    os.makedirs(upload_dir, exist_ok=True)
    file_path = f"{upload_dir}/{db_user.id}.jpg"
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    image_url = f"http://127.0.0.1:8000/{file_path}"

    db_user.profileImage = image_url
    db.commit()

    return {"imageUrl": image_url}

@router.delete("/")
def delete_user(
    userId: int,
    user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if user["userId"] != userId:
        raise HTTPException(status_code=403, detail="Access denied")

    db_user = db.query(User).filter(User.id == userId).first()

    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(db_user)
    db.commit()

    return {"message": "Account deleted"}
from auth import verify_email_token


@router.get("/verify-email")
def verify_email(
    token: str,
    db: Session = Depends(get_db)
):
    try:
        payload = verify_email_token(token)
        email = payload["email"]

    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired token"
        )

    user = db.query(User).filter(
        User.email == email
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    user.isEmailVerified = True

    db.commit()

    return {
        "message": "Email verified successfully"
    }


@router.post("/", response_model=UserDetailResponse, status_code=status.HTTP_201_CREATED)
def create_user(
    user_data: UserCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    if user_data.email:
        existing_email = db.query(User).filter(User.email == user_data.email).first()
        if existing_email:
            raise HTTPException(status_code=400, detail="Email already registered.")
    user_dict = user_data.model_dump()
    user_dict["password"] = get_password_hash(user_dict["password"])

    new_user = User(
        **user_dict,
        isEmailVerified=False
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    token = create_email_verification_token(new_user.email)
    background_tasks.add_task(send_verification_email, new_user.email, token)
    return new_user


@router.post("/login")
def login(
    req: LoginRequest,
    db: Session = Depends(get_db)
):
    email = req.email
    password = req.password

    user = db.query(User).filter(User.email == email).first()

    if not user:
        raise HTTPException(
    status_code=401,
    detail={
        "code": "INVALID_CREDENTIALS",
        "message": "Invalid credentials"
    }
)
    if not user.isEmailVerified:
        raise HTTPException(status_code=403, detail="Please verify your email first")

    if not verify_password(password, user.password):
        raise HTTPException(
    status_code=401,
    detail={
        "code": "INVALID_CREDENTIALS",
        "message": "Invalid credentials"
    }
)

    token = create_token(user)

    print("LOGIN SUCCESS:", email)

    return {"access_token": token}

@router.patch("/", response_model=UserDetailResponse)
def patch_user(
    user_data: UserUpdate,
    user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    userId = user["userId"]

    db_user = db.query(User).filter(User.id == userId).first()

    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    update_data = user_data.model_dump(exclude_unset=True)

    if "fullName" in update_data:
        db_user.fullName = update_data["fullName"]

    if "email" in update_data:
        db_user.email = update_data["email"]

    db.commit()
    db.refresh(db_user)

    return {
        "fullName": db_user.fullName,
        "email": db_user.email,
        "id": db_user.id,
        "role": db_user.role,
        "isEmailVerified": db_user.isEmailVerified
    }

@router.put("/", response_model=UserDetailResponse)
def update_user(
    userId: int,
    user_data: UserCreate,
    user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if user["userId"] != userId:
        raise HTTPException(status_code=403, detail="Access denied")
    db_user = db.query(User).filter(User.id == userId).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    user_dict = user_data.model_dump()
    if "password" in user_dict:
        user_dict["password"] = get_password_hash(user_dict["password"])

    for key, value in user_dict.items():
        setattr(db_user, key, value)

    db.commit()
    db.refresh(db_user)
    return db_user