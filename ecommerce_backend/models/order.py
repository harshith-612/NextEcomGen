import datetime
from sqlalchemy import Column, Integer, String, Text, Float, DateTime, ForeignKey, PrimaryKeyConstraint
from sqlalchemy.orm import relationship
from config.database import Base


class Order(Base):
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    userId = Column(
        String(36),
        ForeignKey("user.id", ondelete="CASCADE"),
        nullable=False
    )
    date = Column(
        DateTime,
        default=lambda: datetime.datetime.now(datetime.timezone.utc),
        nullable=False
    )
    status = Column(String(50), default="pending", nullable=False)
    totalAmount = Column(Float, default=0.0, nullable=False)

    items = relationship(
        "OrderItem",
        back_populates="order",
        cascade="all, delete-orphan"
    )


class OrderItem(Base):
    __tablename__ = "orderItems"

    orderId = Column(Integer, ForeignKey("orders.id", ondelete="CASCADE"), nullable=False)
    productId = Column(Integer, ForeignKey("product.id"), nullable=False)
    name = Column(String(255), nullable=False)
    imageName = Column(String(255), nullable=False)
    productDescription = Column(Text, nullable=False)
    price = Column(Float, nullable=False)
    category = Column(String(100), nullable=False)
    quantity = Column(Integer, default=1, nullable=False)  # <-- Added Field

    order = relationship("Order", back_populates="items")

    __table_args__ = (
        PrimaryKeyConstraint("orderId", "productId"),
    )
