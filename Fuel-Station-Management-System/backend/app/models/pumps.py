from .. import db
from datetime import datetime


class Pump(db.Model):
    """Fuel dispenser pump — one row per physical pump."""
    __tablename__ = 'pumps'

    PumpID          = db.Column('pump_id',            db.Integer,     primary_key=True)
    PumpNumber      = db.Column('pump_number',         db.String(20),  nullable=False, unique=True)  # e.g. "P-01"
    PumpName        = db.Column('pump_name',           db.String(100), nullable=False)               # e.g. "Pump 1 - Forecourt A"
    FuelType        = db.Column('fuel_type',           db.String(50),  nullable=False)               # 92 Octane / 95 Octane / Auto Diesel / Super Diesel
    Status          = db.Column('status',              db.String(30),  nullable=False, default='Active')  # Active / Inactive / Under Maintenance
    TotalDispensedL = db.Column('total_dispensed_l',   db.Float,       nullable=False, default=0.0)  # manually updated lifetime total
    LastMaintenanceDate = db.Column('last_maintenance_date', db.Date)
    NextMaintenanceDate = db.Column('next_maintenance_date', db.Date)
    MaintenanceWarningDays = db.Column('maintenance_warning_days', db.Integer, default=7)
    OperatorID      = db.Column('operator_id',         db.Integer,
                                db.ForeignKey('users.userid', ondelete='SET NULL'), nullable=True)
    Notes           = db.Column('notes',               db.Text)
    CreatedAt       = db.Column('created_at',          db.DateTime,    server_default=db.func.now())
    UpdatedAt       = db.Column('updated_at',          db.DateTime,    server_default=db.func.now(),
                                onupdate=datetime.utcnow)

    operator     = db.relationship('User', foreign_keys=[OperatorID], backref='assigned_pumps')
    maintenances = db.relationship('PumpMaintenance', back_populates='pump',
                                   lazy='dynamic', cascade='all, delete-orphan',
                                   order_by='PumpMaintenance.MaintenanceDate.desc()')
    faults       = db.relationship('PumpFault', back_populates='pump',
                                   lazy='dynamic', cascade='all, delete-orphan',
                                   order_by='PumpFault.FaultDate.desc()')

    def maintenance_alert(self):
        """Returns 'overdue', 'warning', or None."""
        if not self.NextMaintenanceDate:
            return None
        today = datetime.utcnow().date()
        delta = (self.NextMaintenanceDate - today).days
        if delta < 0:
            return 'overdue'
        if delta <= self.MaintenanceWarningDays:
            return 'warning'
        return None

    def days_until_maintenance(self):
        if not self.NextMaintenanceDate:
            return None
        return (self.NextMaintenanceDate - datetime.utcnow().date()).days

    def to_dict(self):
        return {
            "id":                    self.PumpID,
            "pump_number":           self.PumpNumber,
            "pump_name":             self.PumpName,
            "fuel_type":             self.FuelType,
            "status":                self.Status,
            "total_dispensed_l":     self.TotalDispensedL,
            "last_maintenance_date": self.LastMaintenanceDate.strftime('%Y-%m-%d') if self.LastMaintenanceDate else None,
            "next_maintenance_date": self.NextMaintenanceDate.strftime('%Y-%m-%d') if self.NextMaintenanceDate else None,
            "maintenance_warning_days": self.MaintenanceWarningDays,
            "maintenance_alert":     self.maintenance_alert(),
            "days_until_maintenance":self.days_until_maintenance(),
            "operator_id":           self.OperatorID,
            "operator_name":         self.operator.full_name if self.operator else None,
            "notes":                 self.Notes,
        }


class PumpMaintenance(db.Model):
    """Log of every maintenance visit for a pump."""
    __tablename__ = 'pump_maintenances'

    MaintenanceID   = db.Column('maintenance_id',   db.Integer,  primary_key=True)
    PumpID          = db.Column('pump_id',           db.Integer,
                                db.ForeignKey('pumps.pump_id', ondelete='CASCADE'), nullable=False)
    MaintenanceDate = db.Column('maintenance_date',  db.Date,     nullable=False)
    Technician      = db.Column('technician',        db.String(100), nullable=False)
    WorkDone        = db.Column('work_done',         db.Text,     nullable=False)
    Cost            = db.Column('cost',              db.Float,    default=0.0)
    NextScheduled   = db.Column('next_scheduled',    db.Date)     # if set, updates pump's NextMaintenanceDate
    Notes           = db.Column('notes',             db.Text)
    CreatedAt       = db.Column('created_at',        db.DateTime, server_default=db.func.now())

    pump = db.relationship('Pump', back_populates='maintenances')

    def to_dict(self):
        return {
            "id":               self.MaintenanceID,
            "pump_id":          self.PumpID,
            "pump_name":        self.pump.PumpName if self.pump else '',
            "pump_number":      self.pump.PumpNumber if self.pump else '',
            "maintenance_date": self.MaintenanceDate.strftime('%Y-%m-%d'),
            "technician":       self.Technician,
            "work_done":        self.WorkDone,
            "cost":             self.Cost,
            "next_scheduled":   self.NextScheduled.strftime('%Y-%m-%d') if self.NextScheduled else None,
            "notes":            self.Notes,
        }


class PumpFault(db.Model):
    """Fault / breakdown report for a pump."""
    __tablename__ = 'pump_faults'

    FaultID     = db.Column('fault_id',    db.Integer,  primary_key=True)
    PumpID      = db.Column('pump_id',     db.Integer,
                            db.ForeignKey('pumps.pump_id', ondelete='CASCADE'), nullable=False)
    FaultDate   = db.Column('fault_date',  db.Date,     nullable=False)
    ReportedBy  = db.Column('reported_by', db.String(100), nullable=False)
    Description = db.Column('description', db.Text,     nullable=False)
    Severity    = db.Column('severity',    db.String(20), default='Medium')   # Low / Medium / High / Critical
    Status      = db.Column('status',      db.String(20), default='Open')     # Open / In Progress / Resolved
    ResolvedDate= db.Column('resolved_date', db.Date)
    Notes       = db.Column('notes',       db.Text)
    CreatedAt   = db.Column('created_at',  db.DateTime, server_default=db.func.now())

    pump = db.relationship('Pump', back_populates='faults')

    def to_dict(self):
        return {
            "id":            self.FaultID,
            "pump_id":       self.PumpID,
            "pump_name":     self.pump.PumpName if self.pump else '',
            "pump_number":   self.pump.PumpNumber if self.pump else '',
            "fault_date":    self.FaultDate.strftime('%Y-%m-%d'),
            "reported_by":   self.ReportedBy,
            "description":   self.Description,
            "severity":      self.Severity,
            "status":        self.Status,
            "resolved_date": self.ResolvedDate.strftime('%Y-%m-%d') if self.ResolvedDate else None,
            "notes":         self.Notes,
        }