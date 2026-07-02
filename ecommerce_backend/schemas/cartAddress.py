from typing import Optional

from pydantic import BaseModel, ConfigDict

class CartBase(BaseModel):
    productId: int
    quantity: int = 1
class CartItemResponse(BaseModel):
    productId: int
    name: str
    imageName: str
    price: float
    category: str
    quantity: int
    itemTotal: float

class CartResponse(BaseModel):
    items: list[CartItemResponse]
    cartTotal: float
        
class AddressCreate(BaseModel):
    name: str
    phoneNumber: str
    houseNumber: str
    street: str
    pincode: str
    state: str


class AddressBase(BaseModel):
    name: Optional[str] = None
    phoneNumber: Optional[str] = None
    houseNumber: Optional[str] = None
    street: Optional[str] = None
    pincode: Optional[str] = None
    state: Optional[str] = None


class AddressResponse(AddressBase):
    id: str
    userId: str

    model_config = ConfigDict(from_attributes=True)