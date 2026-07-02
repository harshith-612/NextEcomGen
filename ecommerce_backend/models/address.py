import uuid
from sqlalchemy import Column, String, ForeignKey
from config.database import Base


class Address(Base):
    __tablename__ = "address"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    userId = Column(String(36), ForeignKey("user.id", ondelete="CASCADE"), nullable=True)

    name = Column(String(100), nullable=False)
    phoneNumber = Column(String(15), nullable=False)

    houseNumber = Column(String(100), nullable=False)
    street = Column(String(255), nullable=False)

    pincode = Column(String(10), nullable=False)
    state = Column(String(100), nullable=False)