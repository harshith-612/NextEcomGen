import os
from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI
from config.database import Base, engine
from routes import product_routes, user_routes, order_routes, cart_address_route
Base.metadata.create_all(bind=engine)
app = FastAPI(title="Next E-ComGEN Backend")
app.include_router(product_routes.router)
app.include_router(user_routes.router)
app.include_router(order_routes.router)
app.include_router(cart_address_route.router)
app.include_router(product_routes.router1)
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")