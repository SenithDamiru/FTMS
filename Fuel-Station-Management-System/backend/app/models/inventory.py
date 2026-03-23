from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Text, TIMESTAMP, Boolean
from .. import db


# ─────────────────────────────────────────────
#  FUEL TANK  — master registry of all 5 tanks
# ─────────────────────────────────────────────
class FuelTank(db.Model):
    __tablename__ = 'fuel_tanks'

    id                    = Column(Integer, primary_key=True, autoincrement=True)
    tank_id               = Column(String(20),  nullable=False, unique=True)  # e.g. "1P", "2P"
    fuel_type             = Column(String(50),  nullable=False)               # "92 Petrol" etc.
    capacity_l            = Column(Float,       nullable=False)               # max capacity in litres
    current_stock_l       = Column(Float,       nullable=False, default=0.0) # current level in litres
    low_stock_threshold_l = Column(Float,       nullable=False, default=0.0) # alert below this
    iot_device_id         = Column(String(50),  nullable=True)               # "TANK_001" or NULL
    location              = Column(String(100), nullable=True)
    notes                 = Column(Text,        nullable=True)
    last_updated          = Column(TIMESTAMP,   default=datetime.utcnow, onupdate=datetime.utcnow)
    created_at            = Column(TIMESTAMP,   default=datetime.utcnow)

    @property
    def stock_pct(self):
        if not self.capacity_l or self.capacity_l == 0:
            return 0.0
        return round((self.current_stock_l / self.capacity_l) * 100, 1)

    @property
    def is_low(self):
        return self.current_stock_l <= self.low_stock_threshold_l

    def to_dict(self):
        return {
            'id':                    self.id,
            'tank_id':               self.tank_id,
            'fuel_type':             self.fuel_type,
            'capacity_l':            self.capacity_l,
            'current_stock_l':       round(self.current_stock_l, 2),
            'stock_pct':             self.stock_pct,
            'low_stock_threshold_l': self.low_stock_threshold_l,
            'is_low':                self.is_low,
            'iot_device_id':         self.iot_device_id,
            'location':              self.location,
            'notes':                 self.notes,
            'last_updated':          str(self.last_updated) if self.last_updated else None,
        }