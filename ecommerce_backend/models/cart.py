from sqlalchemy import Column, String, BigInteger, Integer
from config.database import Base

class Cart(Base):
    __tablename__ = "cart"

    productId = Column(Integer, primary_key=True)
    userId = Column(String(36), primary_key=True)
    quantity = Column(Integer, default=1)
