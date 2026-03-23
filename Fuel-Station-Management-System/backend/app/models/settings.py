from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, TIMESTAMP
from .. import db


class StationSettings(db.Model):
    __tablename__ = 'station_settings'

    id              = Column(Integer, primary_key=True, default=1)
    name            = Column(String(150), nullable=False, default='')
    address         = Column(Text,        nullable=True)
    phone           = Column(String(30),  nullable=True)
    email           = Column(String(120), nullable=True)
    license_number  = Column(String(100), nullable=True)
    logo_path       = Column(String(255), nullable=True)
    updated_at      = Column(TIMESTAMP,   default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id':             self.id,
            'name':           self.name            or '',
            'address':        self.address         or '',
            'phone':          self.phone           or '',
            'email':          self.email           or '',
            'license_number': self.license_number  or '',
            'logo_path':      self.logo_path       or '',
            'updated_at':     str(self.updated_at) if self.updated_at else None,
        }