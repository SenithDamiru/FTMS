from datetime import datetime
from sqlalchemy import Column, Integer, String, DECIMAL, Date, ForeignKey, Text, CheckConstraint, TIMESTAMP
from sqlalchemy.orm import relationship
from .. import db


# ------------------------------------------------------------
# Fuel Prices
# ------------------------------------------------------------
class FuelPrice(db.Model):
    __tablename__ = "fuel_prices"

    price_id        = Column(Integer, primary_key=True, autoincrement=True)
    fuel_type       = Column(String(50), nullable=False, unique=True)
    price_per_litre = Column(DECIMAL(10, 2), nullable=False)
    effective_date  = Column(Date, nullable=False)
    updated_by      = Column(String(100))
    notes           = Column(Text)
    created_at      = Column(TIMESTAMP, default=datetime.utcnow)
    updated_at      = Column(TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id':               self.price_id,
            'fuel_type':        self.fuel_type,
            'price_per_litre':  float(self.price_per_litre),
            'effective_date':   str(self.effective_date) if self.effective_date else None,
            'updated_by':       self.updated_by,
            'notes':            self.notes,
        }


# ------------------------------------------------------------
# Daily Sales
# ------------------------------------------------------------
class DailySale(db.Model):
    __tablename__ = "daily_sales"

    sale_id         = Column(Integer, primary_key=True, autoincrement=True)
    sale_date       = Column(Date, nullable=False)
    pump_id         = Column(Integer, ForeignKey("pumps.pump_id"), nullable=False)
    shift_id        = Column(Integer, ForeignKey("staff_shifts.id"), nullable=True)
    user_id         = Column(Integer, ForeignKey("users.userid"), nullable=True)
    record_type     = Column(String(20), nullable=False, default="shift")
    opening_meter   = Column(DECIMAL(12, 2))
    closing_meter   = Column(DECIMAL(12, 2))
    litres_sold     = Column(DECIMAL(12, 2), nullable=False)
    price_per_litre = Column(DECIMAL(10, 2), nullable=False)
    total_amount    = Column(DECIMAL(12, 2), nullable=False)
    payment_method  = Column(String(20), nullable=False, default="Cash")
    shift_period    = Column(String(20), nullable=False, default="Morning")
    notes           = Column(Text)
    created_at      = Column(TIMESTAMP, default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint("record_type IN ('shift','transaction')",        name="check_record_type"),
        CheckConstraint("payment_method IN ('Cash','Card','Mobile','Credit')", name="check_payment_method"),
        CheckConstraint("shift_period IN ('Morning','Evening','Night')", name="check_shift_period"),
    )

    pump  = relationship("Pump",  backref="daily_sales", foreign_keys=[pump_id])
    shift = relationship("Shift", backref="daily_sales", foreign_keys=[shift_id])
    user  = relationship("User",  backref="daily_sales", foreign_keys=[user_id])

    def to_dict(self):
        return {
            'id':             self.sale_id,
            'sale_date':      str(self.sale_date) if self.sale_date else None,
            'pump_id':        self.pump_id,
            'pump_number':    self.pump.PumpNumber  if self.pump  else '',
            'pump_name':      self.pump.PumpName    if self.pump  else '',
            'fuel_type':      self.pump.FuelType    if self.pump  else '',
            'shift_id':       self.shift_id,
            'shift_label':    f"{self.shift.StartTime.strftime('%H:%M')}–{self.shift.EndTime.strftime('%H:%M')}" if self.shift else '',
            'user_id':        self.user_id,
            'recorded_by':    self.user.full_name   if self.user  else '',
            'record_type':    self.record_type,
            'opening_meter':  float(self.opening_meter)   if self.opening_meter  else None,
            'closing_meter':  float(self.closing_meter)   if self.closing_meter  else None,
            'litres_sold':    float(self.litres_sold),
            'price_per_litre':float(self.price_per_litre),
            'total_amount':   float(self.total_amount),
            'payment_method': self.payment_method,
            'shift_period':   self.shift_period,
            'notes':          self.notes,
        }


# ------------------------------------------------------------
# Credit Accounts
# ------------------------------------------------------------
class CreditAccount(db.Model):
    __tablename__ = "credit_accounts"

    account_id          = Column(Integer, primary_key=True, autoincrement=True)
    account_name        = Column(String(150), nullable=False)
    contact_person      = Column(String(100))
    contact_phone       = Column(String(30))
    contact_email       = Column(String(120))
    address             = Column(Text)
    credit_limit        = Column(DECIMAL(12, 2), nullable=False, default=0)
    outstanding_balance = Column(DECIMAL(12, 2), nullable=False, default=0)
    status              = Column(String(20), nullable=False, default="Active")
    notes               = Column(Text)
    created_at          = Column(TIMESTAMP, default=datetime.utcnow)
    updated_at          = Column(TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        CheckConstraint("status IN ('Active','Suspended','Closed')", name="check_credit_status"),
    )

    credit_sales    = relationship("CreditSale",    backref="account")
    credit_payments = relationship("CreditPayment", backref="account")

    @property
    def utilisation_pct(self):
        if not self.credit_limit or float(self.credit_limit) == 0:
            return 0
        return round((float(self.outstanding_balance) / float(self.credit_limit)) * 100, 1)

    def to_dict(self):
        return {
            'id':                   self.account_id,
            'account_name':         self.account_name,
            'contact_person':       self.contact_person,
            'contact_phone':        self.contact_phone,
            'contact_email':        self.contact_email,
            'address':              self.address,
            'credit_limit':         float(self.credit_limit),
            'outstanding_balance':  float(self.outstanding_balance),
            'available_credit':     float(self.credit_limit) - float(self.outstanding_balance),
            'utilisation_pct':      self.utilisation_pct,
            'status':               self.status,
            'notes':                self.notes,
        }


# ------------------------------------------------------------
# Credit Sales
# ------------------------------------------------------------
class CreditSale(db.Model):
    __tablename__ = "credit_sales"

    credit_sale_id  = Column(Integer, primary_key=True, autoincrement=True)
    sale_date       = Column(Date, nullable=False)
    account_id      = Column(Integer, ForeignKey("credit_accounts.account_id"), nullable=False)
    pump_id         = Column(Integer, ForeignKey("pumps.pump_id"), nullable=False)
    shift_id        = Column(Integer, ForeignKey("staff_shifts.id"), nullable=True)
    user_id         = Column(Integer, ForeignKey("users.userid"), nullable=True)
    vehicle_number  = Column(String(30))
    litres_sold     = Column(DECIMAL(12, 2), nullable=False)
    price_per_litre = Column(DECIMAL(10, 2), nullable=False)
    total_amount    = Column(DECIMAL(12, 2), nullable=False)
    fuel_type       = Column(String(50))
    reference       = Column(String(100))
    notes           = Column(Text)
    created_at      = Column(TIMESTAMP, default=datetime.utcnow)

    pump  = relationship("Pump",  foreign_keys=[pump_id])
    shift = relationship("Shift", foreign_keys=[shift_id])
    user  = relationship("User",  foreign_keys=[user_id])

    def to_dict(self):
        return {
            'id':               self.credit_sale_id,
            'sale_date':        str(self.sale_date) if self.sale_date else None,
            'account_id':       self.account_id,
            'account_name':     self.account.account_name if self.account else '',
            'pump_id':          self.pump_id,
            'pump_number':      self.pump.PumpNumber  if self.pump  else '',
            'pump_name':        self.pump.PumpName    if self.pump  else '',
            'shift_id':         self.shift_id,
            'shift_label':      f"{self.shift.StartTime.strftime('%H:%M')}–{self.shift.EndTime.strftime('%H:%M')}" if self.shift else '',
            'user_id':          self.user_id,
            'recorded_by':      self.user.full_name   if self.user  else '',
            'vehicle_number':   self.vehicle_number,
            'litres_sold':      float(self.litres_sold),
            'price_per_litre':  float(self.price_per_litre),
            'total_amount':     float(self.total_amount),
            'fuel_type':        self.fuel_type,
            'reference':        self.reference,
            'notes':            self.notes,
        }


# ------------------------------------------------------------
# Credit Payments
# ------------------------------------------------------------
class CreditPayment(db.Model):
    __tablename__ = "credit_payments"

    payment_id       = Column(Integer, primary_key=True, autoincrement=True)
    payment_date     = Column(Date, nullable=False)
    account_id       = Column(Integer, ForeignKey("credit_accounts.account_id"), nullable=False)
    user_id          = Column(Integer, ForeignKey("users.userid"), nullable=True)
    amount           = Column(DECIMAL(12, 2), nullable=False)
    payment_method   = Column(String(30), nullable=False, default="Cash")
    reference_number = Column(String(100))
    notes            = Column(Text)
    created_at       = Column(TIMESTAMP, default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint(
            "payment_method IN ('Cash','Cheque','Bank Transfer','Online')",
            name="check_credit_payment_method"
        ),
    )

    user = relationship("User", foreign_keys=[user_id])

    def to_dict(self):
        return {
            'id':               self.payment_id,
            'payment_date':     str(self.payment_date) if self.payment_date else None,
            'account_id':       self.account_id,
            'account_name':     self.account.account_name if self.account else '',
            'user_id':          self.user_id,
            'received_by':      self.user.full_name if self.user else '',
            'amount':           float(self.amount),
            'payment_method':   self.payment_method,
            'reference_number': self.reference_number,
            'notes':            self.notes,
        }


# ------------------------------------------------------------
# Fuel Deliveries
# ------------------------------------------------------------
class FuelDelivery(db.Model):
    __tablename__ = "fuel_deliveries"

    delivery_id      = Column(Integer, primary_key=True, autoincrement=True)
    delivery_date    = Column(Date, nullable=False)
    supplier_id      = Column(Integer, ForeignKey("suppliers.supplier_id"), nullable=True)
    invoice_number   = Column(String(100))
    fuel_type        = Column(String(50), nullable=False)
    litres_delivered = Column(DECIMAL(12, 2), nullable=False)
    price_per_litre  = Column(DECIMAL(10, 2), nullable=False)
    total_cost       = Column(DECIMAL(12, 2), nullable=False)
    delivery_vehicle = Column(String(100))
    driver_name      = Column(String(100))
    received_by      = Column(String(100))
    notes            = Column(Text)
    created_at       = Column(TIMESTAMP, default=datetime.utcnow)

    supplier = relationship("Supplier")

    def to_dict(self):
        return {
            'id':               self.delivery_id,
            'delivery_date':    str(self.delivery_date) if self.delivery_date else None,
            'supplier_id':      self.supplier_id,
            'supplier_name':    self.supplier.Name if self.supplier else 'Direct',
            'invoice_number':   self.invoice_number,
            'fuel_type':        self.fuel_type,
            'litres_delivered': float(self.litres_delivered),
            'price_per_litre':  float(self.price_per_litre),
            'total_cost':       float(self.total_cost),
            'delivery_vehicle': self.delivery_vehicle,
            'driver_name':      self.driver_name,
            'received_by':      self.received_by,
            'notes':            self.notes,
        }