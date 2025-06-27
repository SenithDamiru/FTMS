from flask import Blueprint, request, jsonify, render_template
from werkzeug.security import generate_password_hash
from ..models.user import User
from ..models.role import Role
from .. import db
import os
from werkzeug.utils import secure_filename
from flask import url_for
from flask import current_app

staff_bp = Blueprint('staff', __name__, url_prefix='/staff')


UPLOAD_FOLDER = 'static/uploads'  # Make sure this exists
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))  # where this file is
STATIC_FOLDER = os.path.join(PROJECT_ROOT, '..', 'static') 

# Ensure upload folder exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@staff_bp.route('/page')
def staff_page():
    return render_template('staff.html')

@staff_bp.route('/roles', methods=['GET'])
def get_roles():
    roles = Role.query.all()
    return jsonify([{"id": r.RoleID, "name": r.RoleName} for r in roles])

@staff_bp.route('/add', methods=['POST'])
@staff_bp.route('/add', methods=['POST'])
def add_staff():
    name = request.form.get('staffName')
    email = request.form.get('staffEmail')
    phone = request.form.get('staffPhone')
    password = request.form.get('staffPassword')
    emp_no = request.form.get('staffEMPNO')
    role_id = request.form.get('staffRole')
    status = request.form.get('staffStatus')
    file = request.files.get('staffImage')

    image_path = None
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        relative_path = f"uploads/{filename}"  # This will be stored in DB
        full_path = os.path.join(current_app.root_path, 'static', relative_path)

        print("DEBUG - Saving image to:", full_path)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        file.save(full_path)

        image_path = relative_path  # Store only 'uploads/filename.jpg' in DB

    hashed_password = generate_password_hash(password)
    new_user = User(
        full_name=name,
        email=email,
        phone_number=phone,
        password_hash=hashed_password,
        role_id=role_id,
        status=status,
        emp_no=emp_no,
        profile_image=image_path
    )

    db.session.add(new_user)
    db.session.commit()
    return jsonify({"message": "Staff added successfully"}), 201

@staff_bp.route('/all', methods=['GET'])
def get_all_staff():
    users = User.query.join(Role).all()
    result = []
    for u in users:
        img_path = u.profile_image or ''
        # Strip leading 'static/' if present (optional, depending on your data)
        if img_path.startswith('static/'):
            img_path = img_path[len('static/'):]
        
        if img_path:
            profile_img_url = url_for('static', filename=img_path)
        else:
            profile_img_url = url_for('static', filename='default-profile.png')

        result.append({
            "user_id": u.user_id,
            "full_name": u.full_name,
            "email": u.email,
            "phone_number": u.phone_number,
            "emp_no": u.emp_no,
            "status": u.status,
            "role_name": u.role.RoleName if u.role else "N/A",
            "profile_image": profile_img_url
        })
    return jsonify(result)

@staff_bp.route('/<int:user_id>', methods=['GET'])
def get_staff_by_id(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "Staff not found"}), 404
    
    return jsonify({
        "user_id": user.user_id,
        "full_name": user.full_name,
        "email": user.email,
        "phone_number": user.phone_number,
        "emp_no": user.emp_no,
        "role_id": user.role_id,
        "status": user.status,
        "profile_image": user.profile_image
    })

@staff_bp.route('/edit/<int:user_id>', methods=['POST'])
def edit_staff(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "Staff not found"}), 404

    name = request.form.get('staffName')
    email = request.form.get('staffEmail')
    phone = request.form.get('staffPhone')
    emp_no = request.form.get('staffEMPNO')
    role_id = request.form.get('staffRole')
    status = request.form.get('staffStatus')
    password = request.form.get('staffPassword')
    file = request.files.get('staffImage')

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        relative_path = f"uploads/{filename}"
        full_path = os.path.join(current_app.root_path, 'static', relative_path)

        print("DEBUG - Saving image to:", full_path)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        file.save(full_path)

        user.profile_image = relative_path  # Save only relative path

    user.full_name = name
    user.email = email
    user.phone_number = phone
    user.emp_no = emp_no
    user.role_id = role_id
    user.status = status

    if password:
        user.password_hash = generate_password_hash(password)

    db.session.commit()
    return jsonify({"message": "Staff updated successfully"}), 200



@staff_bp.route('/delete/<int:user_id>', methods=['DELETE'])
def delete_staff(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "Staff not found"}), 404

    db.session.delete(user)
    db.session.commit()
    return jsonify({"message": "Staff deleted successfully"}), 200
