from datetime import datetime, timezone
from typing import List
from pydantic import BaseModel, ConfigDict, Field


class ProductItemInput(BaseModel): 
    productId: int
    quantity: int = Field(..., gt=0, examples=[2], description="Quantity must be greater than 0")


class OrderItemBase(BaseModel):
    name: str
    price: float
    imageName: str
    productDescription: str
    category: str
    quantity: int  # <-- Added Field


class OrderItemResponse(OrderItemBase):
    productId: int
    orderId: int

    model_config = ConfigDict(from_attributes=True)


class OrderBase(BaseModel):
    date: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    status: str = Field(default="pending", examples=["pending"])
    totalAmount: float = Field(
        default=0.0,
        description="Leave 0 to calculate automatically on backend"
    )


class OrderCreate(OrderBase):
    products: List[ProductItemInput] = Field(
        ...,
        examples=[[{"productId": 1, "quantity": 2}, {"productId": 2, "quantity": 1}]],
        description="List of Product IDs paired with ordered quantities"
    )


class OrderResponse(OrderBase):
    id: int
    userId: str
    items: List[OrderItemResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)