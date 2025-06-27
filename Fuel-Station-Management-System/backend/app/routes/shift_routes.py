# shift_routes.py

from flask import Blueprint, render_template, request, jsonify
from .. import db
from ..models.shift import Shift
from ..models.user import User
from ..models.role import Role
from datetime import datetime


# Example role colors (you can store in DB or config)
ROLE_COLORS = {
    1: '#FF5722',  # Admin
    2: '#2196F3',  # Manager
    3: '#FFC107',  # Cashier
    4: '#8BC34A',  # Pump Attendant
}


shift_bp = Blueprint('shifts', __name__, url_prefix='/shifts')

@shift_bp.route('/roles')
def get_roles():
    # If you store roles in DB, fetch them and add color from config
    roles = Role.query.all()
    result = []
    for r in roles:
        color = ROLE_COLORS.get(r.RoleID, '#8BC34A')
        result.append({
            'id': r.RoleID,
            'name': r.RoleName,
            'color': color
        })
    return jsonify(result)


@shift_bp.route('/page')
def shifts_page():
    return render_template('shifts.html')

# Get all shifts as JSON (for calendar)
@shift_bp.route('/api', methods=['GET'])
def get_shifts():
    shifts = Shift.query.order_by(Shift.ShiftDate.desc()).all()
    result = []
    for s in shifts:
        role = s.role.RoleName if s.role else 'No Role'
        role_id = s.RoleID if s.RoleID else 0
        color = ROLE_COLORS.get(role_id, '#8BC34A')
        result.append({
            'id': s.ShiftID,
            'title': s.user.full_name,  # just staff name, role shown by color & tooltip
            'start': f"{s.ShiftDate}T{s.StartTime.strftime('%H:%M:%S')}",
            'end': f"{s.ShiftDate}T{s.EndTime.strftime('%H:%M:%S')}",
            'staff_name': s.user.full_name,
            'role_id': role_id,
            'role_name': role,
            'notes': s.Notes,
            'user_id': s.UserID,
            'color': color,
            'extendedProps': {
                'notes': s.Notes,
                'user_id': s.UserID,
                'roleid': role_id,
                'role_name': role
            }
        })
    return jsonify(result)


# Get all staff for dropdown
@shift_bp.route('/staff', methods=['GET'])
def get_staff():
    users = User.query.all()
    return jsonify([{'id': u.user_id, 'name': u.full_name, 'role_id': u.role_id } for u in users])

# Add a shift
@shift_bp.route('/add', methods=['POST'])
def add_shift():
    data = request.json
    new_shift = Shift(
    UserID=data['user_id'],
    RoleID=data['role_id'],
    ShiftDate=datetime.strptime(data['shift_date'], '%Y-%m-%d').date(),
    StartTime=data['start_time'],
    EndTime=data['end_time'],
    Notes=data.get('notes', '')
)

    db.session.add(new_shift)
    db.session.commit()
    return jsonify({'message': 'Shift added successfully'}), 201

def parse_time(tstr):
    """Try parsing time as HH:MM or HH:MM:SS"""
    try:
        return datetime.strptime(tstr, '%H:%M:%S').time()
    except ValueError:
        return datetime.strptime(tstr, '%H:%M').time()
#update shift

@shift_bp.route('/update/<int:id>', methods=['PUT'])
def update_shift(id):
    shift = Shift.query.get(id)
    if not shift:
        return jsonify({'message': 'Shift not found'}), 404

    data = request.json
    shift.UserID = data['user_id']
    shift.RoleID = data['role_id']
    shift.ShiftDate = datetime.strptime(data['shift_date'], '%Y-%m-%d').date()
    shift.StartTime = parse_time(data['start_time'])   # ✅ parsed correctly
    shift.EndTime = parse_time(data['end_time'])       # ✅ parsed correctly
    shift.Notes = data.get('notes', '')

    db.session.commit()
    return jsonify({'message': 'Shift updated successfully'})

# Delete a shift
@shift_bp.route('/delete/<int:id>', methods=['DELETE'])
def delete_shift(id):
    shift = Shift.query.get(id)
    if not shift:
        return jsonify({'message': 'Shift not found'}), 404

    db.session.delete(shift)
    db.session.commit()
    return jsonify({'message': 'Shift deleted'})


# Get shift history for table
from datetime import datetime, timedelta

@shift_bp.route('/history', methods=['GET'])
def get_shift_history():
    from datetime import date, timedelta
    last_30 = date.today() - timedelta(days=30)

    # ✅ Only past 30 days including today, exclude future
    shifts = Shift.query.filter(
        Shift.ShiftDate >= last_30,
        Shift.ShiftDate <= date.today()
    ).order_by(Shift.ShiftDate.desc()).all()

    result = []
    for s in shifts:
        duration = calculate_duration(s.StartTime, s.EndTime)
        role = s.role.RoleName if s.role else 'No Role'
        role_id = s.RoleID if s.RoleID else 0
        result.append({
            'staff_name': s.user.full_name,
            'role_id': role_id,
            'role_name': role,
            'shift_date': s.ShiftDate.strftime('%Y-%m-%d'),
            'start_time': s.StartTime.strftime('%H:%M'),
            'end_time': s.EndTime.strftime('%H:%M'),
            'duration': duration,
            'notes': s.Notes,
            'status': s.user.status
        })
    return jsonify(result)


# Helper to calculate duration string from time objects
def calculate_duration(start_time, end_time):
    from datetime import datetime, timedelta
    FMT = '%H:%M:%S'
    s = datetime.strptime(str(start_time), FMT)
    e = datetime.strptime(str(end_time), FMT)
    if e < s:
        e += timedelta(days=1)
    diff = e - s
    hours = diff.seconds // 3600
    minutes = (diff.seconds % 3600) // 60
    return f"{hours}h {minutes}m"


