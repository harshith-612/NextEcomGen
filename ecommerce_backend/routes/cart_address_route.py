from fastapi import APIRouter, Depends, HTTPException, status,Query
from sqlalchemy.orm import Session
from typing import List
from models.product import Product
from config.database import get_db
from models.cart import Cart
from models.address import Address
from schemas.cartAddress import (
    CartBase,
    CartResponse,
    AddressBase,
    AddressResponse,
    AddressCreate
)

from auth import get_current_user
router = APIRouter(prefix="/users",tags=["Users Cart & Addresses"])
def build_cart_response(db: Session, userId: str):

    items = (
        db.query(Cart, Product)
        .join(Product, Cart.productId == Product.id)
        .filter(Cart.userId == userId)
        .all()
    )

    cartItems = []
    cartTotal = 0.0

    for cart, product in items:
        itemTotal = product.price * cart.quantity
        cartTotal += itemTotal

        cartItems.append({
            "productId": product.id,
            "name": product.name,
            "imageName": product.imageName,
            "price": product.price,
            "category": product.category,
            "quantity": cart.quantity,
            "itemTotal": itemTotal
        })

    return {
        "items": cartItems,
        "cartTotal": cartTotal
    }
@router.post("/cart", response_model=CartResponse)
def add_to_cart(
    cartData: CartBase,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    userId = str(user["userId"])

    item = db.query(Cart).filter(
        Cart.userId == userId,
        Cart.productId == cartData.productId
    ).first()

    if item:
        item.quantity += cartData.quantity
    else:
        item = Cart(
            productId=cartData.productId,
            quantity=cartData.quantity,
            userId=userId
        )
        db.add(item)

    db.commit()

    return build_cart_response(db, userId)
@router.get("/cart", response_model=CartResponse)
def get_cart(
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    userId = str(user["userId"])
    return build_cart_response(db, userId)
@router.put("/cart", response_model=CartResponse)
def update_cart(
    cartData: CartBase,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    userId = str(user["userId"])

    item = db.query(Cart).filter(
        Cart.userId == userId,
        Cart.productId == cartData.productId
    ).first()

    if not item:
        raise HTTPException(status_code=404, detail="Cart item not found")

    item.quantity = cartData.quantity

    if item.quantity <= 0:
        db.delete(item)

    db.commit()

    return build_cart_response(db, userId)
@router.delete("/cart", status_code=204)
def delete_from_cart(
    productId: int = Query(...),
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    userId = str(user["userId"])

    item = db.query(Cart).filter(
        Cart.userId == userId,
        Cart.productId == productId
    ).first()

    if not item:
        raise HTTPException(status_code=404, detail="Cart item not found")

    db.delete(item)
    db.commit()

    return None
@router.delete("/cart/clear", status_code=204)
def clear_cart(
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    userId = str(user["userId"])

    db.query(Cart).filter(
        Cart.userId == userId
    ).delete(synchronize_session=False)

    db.commit()
    return None

@router.post("/addresses", response_model=AddressResponse)
def add_user_address(
    address_data: AddressCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    userId = str(user["userId"])

    new_address = Address(
        userId=userId,
        name=address_data.name,
        phoneNumber=address_data.phoneNumber,
        houseNumber=address_data.houseNumber,
        street=address_data.street,
        pincode=address_data.pincode,
        state=address_data.state
    )

    db.add(new_address)
    db.commit()
    db.refresh(new_address)

    return new_address
@router.get("/addresses", response_model=List[AddressResponse])
def get_user_addresses(
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    userId = str(user["userId"])

    return db.query(Address).filter(Address.userId == userId).all()


@router.put("/addresses/{addressId}", response_model=AddressResponse)
@router.put("/addresses/{addressId}", response_model=AddressResponse)
def update_user_address(
    addressId: str,
    address_data: AddressBase,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    userId = str(user["userId"])

    address = db.query(Address).filter(
        Address.id == addressId,
        Address.userId == userId
    ).first()

    if not address:
        raise HTTPException(status_code=404, detail="Address not found")

    update_data = address_data.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(address, key, value)

    db.commit()
    db.refresh(address)

    return address


@router.delete("/addresses/{addressId}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user_address(
    addressId: str,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    userId = str(user["userId"])

    address = db.query(Address).filter(
        Address.id == addressId,
        Address.userId == userId
    ).first()

    if not address:
        raise HTTPException(status_code=404, detail="Address not found")

    db.delete(address)
    db.commit()
    return None