from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from config.database import get_db
from auth import get_current_user

from models.order import Order, OrderItem
from models.product import Product

from schemas.order import OrderCreate, OrderResponse

router = APIRouter(
    prefix="/users/orders",
    tags=["User Orders"]
)


@router.post("/", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def create_user_order(
    order_data: OrderCreate,
    user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    userId = str(user["userId"])

    try:
        input_products = order_data.products

        # Product IDs and quantities from request
        product_ids = [p.productId for p in input_products]
        quantity_map = {p.productId: p.quantity for p in input_products}

        # Create order first
        order_dict = order_data.model_dump(exclude={"products"})
        order_dict["userId"] = userId

        new_order = Order(**order_dict)
        db.add(new_order)
        db.flush()  # Generates order ID before commit

        # Fetch products from DB
        db_products = (
            db.query(Product)
            .filter(Product.id.in_(product_ids))
            .all()
        )

        product_map = {p.id: p for p in db_products}

        # Validate all requested products exist
        missing_products = [
            pid for pid in product_ids
            if pid not in product_map
        ]

        if missing_products:
            db.rollback()
            raise HTTPException(
                status_code=404,
                detail=f"Products not found: {missing_products}"
            )

        calculated_total = 0.0

        # Create order items
        for prod_id in product_ids:
            product = product_map[prod_id]
            item_quantity = quantity_map[prod_id]

            order_item = OrderItem(
                orderId=new_order.id,
                productId=product.id,
                name=product.name,
                price=product.price,
                imageName=product.imageName,
                productDescription=product.productDescription,
                category=product.category,
                quantity=item_quantity
            )

            db.add(order_item)

            calculated_total += product.price * item_quantity

        # Update order total
        new_order.totalAmount = calculated_total

        db.commit()
        db.refresh(new_order)

        return new_order

    except Exception:
        db.rollback()
        raise


@router.get("/", response_model=List[OrderResponse])
def get_user_orders(
    user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    userId = str(user["userId"])
    return db.query(Order).filter(Order.userId == userId).all()


@router.get("/{orderId}", response_model=OrderResponse)
def get_user_order_byId(
    orderId: int,
    user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    userId = str(user["userId"])
    order = db.query(Order).filter(Order.id == orderId, Order.userId == userId).first()

    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    return order


@router.put("/{orderId}", response_model=OrderResponse)
def update_user_order(
    orderId: int,
    order_data: OrderCreate,
    user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    userId = str(user["userId"])
    order = db.query(Order).filter(Order.id == orderId, Order.userId == userId).first()

    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    # Exclude complex products parsing on a basic metadata PUT update mapping
    update_data = order_data.model_dump(
        exclude={"products"},
        exclude_unset=True
    )

    for key, value in update_data.items():
        setattr(order, key, value)

    db.commit()
    db.refresh(order)
    return order


@router.delete("/{orderId}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user_order(
    orderId: int,
    user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    userId = str(user["userId"])
    order = db.query(Order).filter(Order.id == orderId, Order.userId == userId).first()

    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
 
    db.delete(order)
    db.commit()
    return None
