from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from config.database import get_db
from models.product import Product
from schemas.product import ProductCreate, ProductResponse
from typing import List
from datetime import datetime, timedelta
from jose import jwt, JWTError
import os
from dotenv import load_dotenv
load_dotenv()

ALGORITHM = os.getenv("ALGORITHM")
SECRET = os.getenv("SECRET")

router1 = APIRouter(prefix="/admin_portal")
router = APIRouter(prefix="/products", tags=["Products"])
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD")
def create_token(adminId: str):
    payload = {
        "adminId": adminId,
        "exp": datetime.utcnow() + timedelta(minutes=10)
    }
    return jwt.encode(payload, SECRET, algorithm=ALGORITHM)
@router1.post("/login")
def login(email: str, password: str):

    if email != ADMIN_EMAIL or password != ADMIN_PASSWORD:
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials"
        )

    token = create_token(adminId="admin")

    return {"access_token": token}
security = HTTPBearer()

def verify_admin(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET, algorithms=[ALGORITHM])
        adminId = payload.get("adminId")

        if adminId != "admin":
            raise HTTPException(status_code=403, detail="Not authorized")

        return adminId

    except JWTError:
        raise HTTPException(status_code=403, detail="Invalid or expired token")
@router.get("/", response_model=List[ProductResponse])
def get_all_products(db: Session = Depends(get_db)):
    return db.query(Product).all()

@router.get("/{productId}", response_model=ProductResponse)
def getProduct(productId: int, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == productId).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found.")
    return product
@router.post("/", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def createProduct(
    product_data: ProductCreate,
    db: Session = Depends(get_db),
    admin: str = Depends(verify_admin)
):
    newProduct = Product(**product_data.model_dump())
    db.add(newProduct)
    db.commit()
    db.refresh(newProduct)
    return newProduct


@router.put("/{productId}", response_model=ProductResponse)
def update_product(
    productId: int,
    updatedDate: ProductCreate,
    db: Session = Depends(get_db),
    admin: str = Depends(verify_admin)
):
    product = db.query(Product).filter(Product.id == productId).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found.")

    for key, value in updatedDate.model_dump().items():
        setattr(product, key, value)

    db.commit()
    db.refresh(product)
    return product


@router.delete("/{productId}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(
    productId: int,
    db: Session = Depends(get_db),
    admin: str = Depends(verify_admin)
):
    product = db.query(Product).filter(Product.id == productId).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found.")

    db.delete(product)
    db.commit()
    return None