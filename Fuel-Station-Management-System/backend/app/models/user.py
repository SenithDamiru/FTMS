from .. import db

class User(db.Model):
    __tablename__ = 'users'

    user_id = db.Column('userid', db.Integer, primary_key=True)
    full_name = db.Column('fullname', db.String(100), nullable=False)
    email = db.Column('email', db.String(100), unique=True, nullable=False)
    phone_number = db.Column('phonenumber', db.String(20))
    password_hash = db.Column('passwordhash', db.Text, nullable=False)
    role_id = db.Column('roleid', db.Integer, db.ForeignKey('roles.roleid', ondelete="CASCADE"), nullable=False)
    status = db.Column('status', db.String(20), default='Active')
    created_at = db.Column('createdat', db.DateTime, server_default=db.func.current_timestamp())
    emp_no = db.Column('empno', db.String(20), unique=True)
    profile_image = db.Column('profileimage', db.String(255))

    role = db.relationship("Role", backref="users")
