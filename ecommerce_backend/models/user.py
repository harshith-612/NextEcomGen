import uuid
from sqlalchemy import Column, String, Boolean
from config.database import Base

class User(Base):
    __tablename__ = "user"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, nullable=False)
    fullName = Column(String(255), nullable=True)
    password = Column(String(255), nullable=False)
    role = Column(String(50), default="user")
    isEmailVerified = Column(Boolean, default=False)
    profileImage = Column(String(500), nullable=True)