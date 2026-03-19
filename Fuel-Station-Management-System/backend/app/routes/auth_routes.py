from flask import Blueprint, request, jsonify, session
from werkzeug.security import check_password_hash
from ..models.user import User
from ..models.role import Role
from .. import db

auth_bp = Blueprint('auth', __name__, url_prefix='/auth')

# Roles that are allowed system access
ALLOWED_ROLE_IDS = {1, 2, 3, 7}  # Admin, Manager, Cashier, Station Owner
# Pump Attendant (4) is blocked

# Page → allowed role IDs mapping
PAGE_ACCESS = {
    'dashboard':    {1, 2, 3, 7},
    'sales':        {1, 2, 3, 7},
    'inventory':    {1, 2, 7},
    'tank':         {1, 2, 7},
    'pumps':        {1, 2, 7},
    'staff':        {1, 7},
    'shifts':       {1, 2, 7},
    'lubricants':   {1, 2, 3, 7},
    'reports':      {1, 2, 7},
    'suppliers':    {1, 2, 7},
    'expenses':     {1, 2, 7},
    'settings':     {1, 7},
}


# ─────────────────────────────────────────────
#  LOGIN
# ─────────────────────────────────────────────

@auth_bp.route('/login', methods=['POST'])
def login():
    data     = request.get_json()
    email    = data.get('email', '').strip().lower()
    password = data.get('password', '')

    if not email or not password:
        return jsonify({'message': 'Email and password are required.'}), 400

    user = User.query.filter_by(email=email).first()

    if not user:
        return jsonify({'message': 'Invalid email or password.'}), 401

    if not check_password_hash(user.password_hash, password):
        return jsonify({'message': 'Invalid email or password.'}), 401

    if user.status != 'Active':
        return jsonify({'message': f'Your account is {user.status.lower()}. Please contact your administrator.'}), 403

    if user.role_id not in ALLOWED_ROLE_IDS:
        return jsonify({'message': 'You do not have system access. Please contact your administrator.'}), 403

    # Set session
    session.permanent = True
    session['user_id']   = user.user_id
    session['user_name'] = user.full_name
    session['role_id']   = user.role_id
    session['role_name'] = user.role.RoleName if user.role else ''
    session['emp_no']    = user.emp_no or ''
    session['profile_image'] = user.profile_image or ''

    return jsonify({
        'message':       'Login successful.',
        'user_id':       user.user_id,
        'full_name':     user.full_name,
        'role_id':       user.role_id,
        'role_name':     user.role.RoleName if user.role else '',
        'emp_no':        user.emp_no or '',
        'profile_image': user.profile_image or '',
    }), 200


# ─────────────────────────────────────────────
#  LOGOUT
# ─────────────────────────────────────────────

@auth_bp.route('/logout', methods=['POST'])
def logout():
    session.clear()
    return jsonify({'message': 'Logged out successfully.'}), 200


# ─────────────────────────────────────────────
#  ME  —  called on every page load by auth.js
# ─────────────────────────────────────────────

@auth_bp.route('/me', methods=['GET'])
def me():
    if 'user_id' not in session:
        return jsonify({'authenticated': False}), 401

    return jsonify({
        'authenticated':  True,
        'user_id':        session['user_id'],
        'full_name':      session['user_name'],
        'role_id':        session['role_id'],
        'role_name':      session['role_name'],
        'emp_no':         session['emp_no'],
        'profile_image':  session['profile_image'],
        'page_access':    {page: (session['role_id'] in roles) for page, roles in PAGE_ACCESS.items()},
    }), 200


# ─────────────────────────────────────────────
#  CHECK PAGE ACCESS  —  optional server-side check
# ─────────────────────────────────────────────

@auth_bp.route('/check/<page>', methods=['GET'])
def check_access(page):
    if 'user_id' not in session:
        return jsonify({'allowed': False, 'reason': 'not_authenticated'}), 401
    allowed_roles = PAGE_ACCESS.get(page, set())
    allowed = session.get('role_id') in allowed_roles
    return jsonify({'allowed': allowed, 'role_name': session.get('role_name')}), 200


# ─────────────────────────────────────────────
#  DECORATORS  —  use in other route files
# ─────────────────────────────────────────────

from functools import wraps
from flask import redirect, url_for

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'message': 'Authentication required.'}), 401
        return f(*args, **kwargs)
    return decorated

def role_required(*role_ids):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if 'user_id' not in session:
                return jsonify({'message': 'Authentication required.'}), 401
            if session.get('role_id') not in set(role_ids):
                return jsonify({'message': 'You do not have permission to perform this action.'}), 403
            return f(*args, **kwargs)
        return decorated
    return decorator