from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, TIMESTAMP
from .. import db


# ─────────────────────────────────────────────
#  IOT READING — every 5-minute snapshot
# ─────────────────────────────────────────────
class IoTReading(db.Model):
    __tablename__ = 'iot_readings'

    id             = Column(Integer,   primary_key=True, autoincrement=True)
    device_id      = Column(String(50), nullable=False)   # "TANK_001"
    fuel_level_pct = Column(Float,     nullable=False)    # 0–100 from Firebase
    fuel_level_l   = Column(Float,     nullable=False)    # calculated: pct * capacity / 100
    temperature    = Column(Float,     nullable=True)
    distance       = Column(Float,     nullable=True)     # raw sensor distance in cm
    fire_detected  = Column(Boolean,   default=False)
    pump_running   = Column(Boolean,   default=False)
    in_cooldown    = Column(Boolean,   default=False)
    alert_level    = Column(String(20), nullable=True)    # "normal" / "warning" / "critical"
    recorded_at    = Column(TIMESTAMP, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id':             self.id,
            'device_id':      self.device_id,
            'fuel_level_pct': self.fuel_level_pct,
            'fuel_level_l':   round(self.fuel_level_l, 2),
            'temperature':    self.temperature,
            'distance':       self.distance,
            'fire_detected':  self.fire_detected,
            'pump_running':   self.pump_running,
            'in_cooldown':    self.in_cooldown,
            'alert_level':    self.alert_level,
            'recorded_at':    str(self.recorded_at) if self.recorded_at else None,
        }


# ─────────────────────────────────────────────
#  FIRE EVENT — permanent fire event log
# ─────────────────────────────────────────────
class FireEvent(db.Model):
    __tablename__ = 'fire_events'

    id                  = Column(Integer,    primary_key=True, autoincrement=True)
    device_id           = Column(String(50), nullable=False)
    fuel_level_pct      = Column(Float,      nullable=True)
    fuel_level_l        = Column(Float,      nullable=True)
    temperature         = Column(Float,      nullable=True)
    pump_activated      = Column(Boolean,    default=False)
    status              = Column(String(50), nullable=True)   # "detected" / "resolved" etc.
    firebase_event_key  = Column(String(100), nullable=True)  # Firebase event key for deduplication
    firebase_timestamp  = Column(Integer,    nullable=True)   # raw Firebase timestamp (ms uptime)
    recorded_at         = Column(TIMESTAMP,  default=datetime.utcnow)

    def to_dict(self):
        return {
            'id':                 self.id,
            'device_id':          self.device_id,
            'fuel_level_pct':     self.fuel_level_pct,
            'fuel_level_l':       round(self.fuel_level_l, 2) if self.fuel_level_l else None,
            'temperature':        self.temperature,
            'pump_activated':     self.pump_activated,
            'status':             self.status,
            'firebase_event_key': self.firebase_event_key,
            'firebase_timestamp': self.firebase_timestamp,
            'recorded_at':        str(self.recorded_at) if self.recorded_at else None,
        }