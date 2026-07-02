from datetime import datetime
from pydantic import BaseModel, ConfigDict
from sqlalchemy import Column, Integer, String, Text, Float, TIMESTAMP, text
from config.database import Base
class Product(Base): 
    __tablename__ = "product" 
    
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False) 
    imageName = Column(String(255), nullable=False) 
    productDescription = Column(Text, nullable=False) 
    price = Column(Float, nullable=False) 
    category = Column(String(100), nullable=False) 
    
    createdAt = Column( 
        TIMESTAMP, 
        server_default=text("CURRENT_TIMESTAMP"), 
        nullable=False 
    ) 
    updatedAt = Column( 
        TIMESTAMP, 
        server_default=text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"), 
        nullable=False 
    )
