from jose import jwt,JWTError
from datetime import datetime, timedelta
from fastapi import  Depends, HTTPException
import os
from dotenv import load_dotenv
load_dotenv()
import bcrypt
def get_password_hash(password: str) -> str:
    """Hashes a plain-text password."""
    pwd_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies a plain-text password against a hashed password."""
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

SECRET_KEY=os.getenv("SECRET_KEY")
ALGORITHM=os.getenv("ALGORITHM")
def create_token(user):
    payload = {
        "userId": user.id,
        "exp": datetime.utcnow() + timedelta(hours=3)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
security = HTTPBearer()


def admin_portal(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token") 
    

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    

from jose import jwt
from datetime import datetime, timedelta

def create_email_verification_token(email: str):
    payload = {
        "email": email,
        "type": "email_verification",
        "exp": datetime.utcnow() + timedelta(hours=24)
    }

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def verify_email_token(token: str):
    return jwt.decode(
        token,
        SECRET_KEY,
        algorithms=[ALGORITHM]
    )