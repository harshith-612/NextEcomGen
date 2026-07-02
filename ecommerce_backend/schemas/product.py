from datetime import datetime
from pydantic import BaseModel, ConfigDict

class ProductCreate(BaseModel):
    id: int
    name: str
    imageName: str
    productDescription: str
    price: float
    category: str
class ProductResponse(ProductCreate): 
    createdAt: datetime
    updatedAt: datetime
    
    model_config = ConfigDict(from_attributes=True)