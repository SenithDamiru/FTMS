from flask import Blueprint, request, jsonify
from ..models.role import Role
from .. import db
from flask import render_template



role_bp = Blueprint('roles', __name__, url_prefix='/roles')
@role_bp.route('/page', methods=['GET'])
def roles_page():
    return render_template('roles.html')

@role_bp.route('/', methods=['GET'])
def get_roles():
    roles = Role.query.all()
    return jsonify([{"id": r.RoleID, "name": r.RoleName, "desc": r.Description} for r in roles])

@role_bp.route('/', methods=['POST'])
def add_role():
    data = request.get_json()
    role = Role(RoleName=data['name'], Description=data.get('desc'))
    db.session.add(role)
    db.session.commit()
    return jsonify({"message": "Role added"}), 201

@role_bp.route('/<int:id>', methods=['PUT'])
def update_role(id):
    data = request.get_json()
    role = Role.query.get_or_404(id)
    role.RoleName = data.get('name', role.RoleName)
    role.Description = data.get('desc', role.Description)
    db.session.commit()
    return jsonify({"message": "Role updated"})

@role_bp.route('/<int:id>', methods=['DELETE'])
def delete_role(id):
    role = Role.query.get_or_404(id)
    db.session.delete(role)
    db.session.commit()
    return jsonify({"message": "Role deleted"})
