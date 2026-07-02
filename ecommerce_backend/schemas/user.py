from typing import Optional
from pydantic import BaseModel

class UserBase(BaseModel):
    email: Optional[str] = None
    fullName: Optional[str] = None
    role: Optional[str] = None
    class Config:
        from_attributes = True
        
class LoginRequest(BaseModel):
    email: str
    password: str

class UserCreate(BaseModel): 
    email: str
    fullName: str
    role: str
    password: str

class UserDetailResponse(UserBase):
    id: str
    email: str
    fullName: str
    role: str
    isEmailVerified: bool = False

class UserUpdate(BaseModel):
    fullName: Optional[str] = None
    email: Optional[str] = None