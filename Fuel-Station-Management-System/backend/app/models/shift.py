from .. import db

class Shift(db.Model):
    __tablename__ = 'staff_shifts'

    ShiftID = db.Column('id', db.Integer, primary_key=True)
    UserID = db.Column('user_id', db.Integer, db.ForeignKey('users.userid', ondelete='CASCADE'))
    RoleID = db.Column('role_id', db.Integer, db.ForeignKey('roles.roleid', ondelete='SET NULL'))
    ShiftDate = db.Column('shift_date', db.Date, nullable=False)
    StartTime = db.Column('start_time', db.Time, nullable=False)
    EndTime = db.Column('end_time', db.Time, nullable=False)
    Notes = db.Column('notes', db.Text)

    # Relationships (optional)
    user = db.relationship('User', backref='shifts', passive_deletes=True)
    role = db.relationship('Role', backref='assigned_shifts', foreign_keys=[RoleID], passive_deletes=True)
