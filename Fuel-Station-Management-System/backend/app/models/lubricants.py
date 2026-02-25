from .. import db
from datetime import datetime


class Lubricant(db.Model):
    """Product catalog – one row per lubricant SKU."""
    __tablename__ = 'lubricants'

    LubricantID  = db.Column('lubricant_id',  db.Integer,      primary_key=True)
    Name         = db.Column('name',           db.String(100),  nullable=False)
    Brand        = db.Column('brand',          db.String(100),  nullable=False)
    Grade        = db.Column('grade',          db.String(50),   nullable=False)   # e.g. 5W-30, SAE 40
    Category     = db.Column('category',       db.String(50),   nullable=False)   # Engine Oil, Gear Oil, Grease…
    UnitType     = db.Column('unit_type',      db.String(20),   nullable=False)   # Liters / Bottles / Kg
    SellingPrice = db.Column('selling_price',  db.Float,        nullable=False)
    CostPrice    = db.Column('cost_price',     db.Float,        nullable=False)
    StockQty     = db.Column('stock_qty',      db.Float,        nullable=False, default=0)
    LowStockThreshold = db.Column('low_stock_threshold', db.Float, nullable=False, default=10)
    Description  = db.Column('description',    db.Text)
    CreatedAt    = db.Column('created_at',     db.DateTime,     server_default=db.func.now())
    UpdatedAt    = db.Column('updated_at',     db.DateTime,     server_default=db.func.now(), onupdate=datetime.utcnow)

    # relationships
    sales     = db.relationship('LubricantSale',     back_populates='lubricant', lazy='dynamic')
    purchases = db.relationship('LubricantPurchase', back_populates='lubricant', lazy='dynamic')

    def to_dict(self):
        return {
            "id":            self.LubricantID,
            "name":          self.Name,
            "brand":         self.Brand,
            "grade":         self.Grade,
            "category":      self.Category,
            "unit_type":     self.UnitType,
            "selling_price": self.SellingPrice,
            "cost_price":    self.CostPrice,
            "stock_qty":     self.StockQty,
            "low_stock_threshold": self.LowStockThreshold,
            "description":   self.Description,
            "is_low_stock":  self.StockQty <= self.LowStockThreshold,
        }


class LubricantSale(db.Model):
    """Records every sale transaction for a lubricant."""
    __tablename__ = 'lubricant_sales'

    SaleID       = db.Column('sale_id',       db.Integer, primary_key=True)
    LubricantID  = db.Column('lubricant_id',  db.Integer, db.ForeignKey('lubricants.lubricant_id'), nullable=False)
    CustomerName = db.Column('customer_name', db.String(100))
    Quantity     = db.Column('quantity',      db.Float,   nullable=False)
    UnitPrice    = db.Column('unit_price',    db.Float,   nullable=False)   # price at time of sale
    TotalAmount  = db.Column('total_amount',  db.Float,   nullable=False)
    PaymentMethod = db.Column('payment_method', db.String(50), nullable=False)
    Notes        = db.Column('notes',         db.Text)
    SaleDate     = db.Column('sale_date',     db.Date,    nullable=False)
    CreatedAt    = db.Column('created_at',    db.DateTime, server_default=db.func.now())

    lubricant = db.relationship('Lubricant', back_populates='sales')

    def to_dict(self):
        return {
            "id":             self.SaleID,
            "lubricant_id":   self.LubricantID,
            "lubricant_name": self.lubricant.Name if self.lubricant else '',
            "brand":          self.lubricant.Brand if self.lubricant else '',
            "unit_type":      self.lubricant.UnitType if self.lubricant else '',
            "customer_name":  self.CustomerName,
            "quantity":       self.Quantity,
            "unit_price":     self.UnitPrice,
            "total_amount":   self.TotalAmount,
            "payment_method": self.PaymentMethod,
            "notes":          self.Notes,
            "date":           self.SaleDate.strftime('%Y-%m-%d'),
        }


class LubricantPurchase(db.Model):
    """Records every restock / purchase from a supplier."""
    __tablename__ = 'lubricant_purchases'

    PurchaseID   = db.Column('purchase_id',   db.Integer, primary_key=True)
    LubricantID  = db.Column('lubricant_id',  db.Integer, db.ForeignKey('lubricants.lubricant_id'), nullable=False)
    SupplierName = db.Column('supplier_name', db.String(100), nullable=False)
    Quantity     = db.Column('quantity',      db.Float,   nullable=False)
    CostPerUnit  = db.Column('cost_per_unit', db.Float,   nullable=False)
    TotalCost    = db.Column('total_cost',    db.Float,   nullable=False)
    InvoiceRef   = db.Column('invoice_ref',   db.String(100))
    Notes        = db.Column('notes',         db.Text)
    PurchaseDate = db.Column('purchase_date', db.Date,    nullable=False)
    CreatedAt    = db.Column('created_at',    db.DateTime, server_default=db.func.now())

    lubricant = db.relationship('Lubricant', back_populates='purchases')

    def to_dict(self):
        return {
            "id":             self.PurchaseID,
            "lubricant_id":   self.LubricantID,
            "lubricant_name": self.lubricant.Name if self.lubricant else '',
            "brand":          self.lubricant.Brand if self.lubricant else '',
            "unit_type":      self.lubricant.UnitType if self.lubricant else '',
            "supplier_name":  self.SupplierName,
            "quantity":       self.Quantity,
            "cost_per_unit":  self.CostPerUnit,
            "total_cost":     self.TotalCost,
            "invoice_ref":    self.InvoiceRef,
            "notes":          self.Notes,
            "date":           self.PurchaseDate.strftime('%Y-%m-%d'),
        }