from .. import db
class Role(db.Model):
    __tablename__ = 'roles'

    RoleID = db.Column('roleid', db.Integer, primary_key=True)
    RoleName = db.Column('rolename', db.String(50))
    Description = db.Column('description', db.Text)

