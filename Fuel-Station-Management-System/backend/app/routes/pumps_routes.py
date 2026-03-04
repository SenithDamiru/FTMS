from flask import Blueprint, request, jsonify, render_template
from ..models.pumps import Pump, PumpMaintenance, PumpFault
from ..models.user import User                   # reuse existing User model
from .. import db
from datetime import datetime, date

pumps_bp = Blueprint('pumps', __name__, url_prefix='/pumps')


# ─────────────────────────────────────────────
#  PAGE
# ─────────────────────────────────────────────

@pumps_bp.route('/page', methods=['GET'])
def pumps_page():
    return render_template('pumps.html')


# ─────────────────────────────────────────────
#  PUMP CRUD
# ─────────────────────────────────────────────

@pumps_bp.route('/', methods=['GET'])
def get_pumps():
    fuel_type = request.args.get('fuel_type')
    status    = request.args.get('status')
    query     = Pump.query
    if fuel_type:
        query = query.filter(Pump.FuelType == fuel_type)
    if status:
        query = query.filter(Pump.Status == status)
    pumps = query.order_by(Pump.PumpNumber).all()
    return jsonify([p.to_dict() for p in pumps])


@pumps_bp.route('/<int:id>', methods=['GET'])
def get_pump(id):
    return jsonify(Pump.query.get_or_404(id).to_dict())


@pumps_bp.route('/add', methods=['POST'])
def add_pump():
    d = request.json
    p = Pump(
        PumpNumber   = d['pump_number'],
        PumpName     = d['pump_name'],
        FuelType     = d['fuel_type'],
        Status       = d.get('status', 'Active'),
        TotalDispensedL = float(d.get('total_dispensed_l', 0)),
        LastMaintenanceDate = _parse_date(d.get('last_maintenance_date')),
        NextMaintenanceDate = _parse_date(d.get('next_maintenance_date')),
        MaintenanceWarningDays = int(d.get('maintenance_warning_days', 7)),
        OperatorID   = d.get('operator_id') or None,
        Notes        = d.get('notes', ''),
    )
    db.session.add(p)
    db.session.commit()
    return jsonify({"message": "Pump added", "id": p.PumpID}), 201


@pumps_bp.route('/update/<int:id>', methods=['PUT'])
def update_pump(id):
    p = Pump.query.get_or_404(id)
    d = request.json
    p.PumpNumber    = d['pump_number']
    p.PumpName      = d['pump_name']
    p.FuelType      = d['fuel_type']
    p.Status        = d.get('status', p.Status)
    p.MaintenanceWarningDays = int(d.get('maintenance_warning_days', 7))
    p.OperatorID    = d.get('operator_id') or None
    p.Notes         = d.get('notes', '')
    if d.get('last_maintenance_date'):
        p.LastMaintenanceDate = _parse_date(d['last_maintenance_date'])
    if d.get('next_maintenance_date'):
        p.NextMaintenanceDate = _parse_date(d['next_maintenance_date'])
    db.session.commit()
    return jsonify({"message": "Pump updated"})


@pumps_bp.route('/delete/<int:id>', methods=['DELETE'])
def delete_pump(id):
    p = Pump.query.get_or_404(id)
    db.session.delete(p)
    db.session.commit()
    return jsonify({"message": "Pump deleted"})


# ─────────────────────────────────────────────
#  STATUS & DISPENSED QUICK-UPDATES
# ─────────────────────────────────────────────

@pumps_bp.route('/status/<int:id>', methods=['PATCH'])
def update_status(id):
    """Toggle / set pump status. Body: { status: 'Active'|'Inactive'|'Under Maintenance' }"""
    p = Pump.query.get_or_404(id)
    new_status = request.json.get('status')
    if new_status not in ('Active', 'Inactive', 'Under Maintenance'):
        return jsonify({"message": "Invalid status"}), 400
    p.Status = new_status
    db.session.commit()
    return jsonify({"message": "Status updated", "status": p.Status})


@pumps_bp.route('/dispensed/<int:id>', methods=['PATCH'])
def update_dispensed(id):
    """Update total fuel dispensed. Body: { total_dispensed_l: float }"""
    p = Pump.query.get_or_404(id)
    p.TotalDispensedL = float(request.json.get('total_dispensed_l', p.TotalDispensedL))
    db.session.commit()
    return jsonify({"message": "Dispensed total updated", "total_dispensed_l": p.TotalDispensedL})


# ─────────────────────────────────────────────
#  MAINTENANCE CRUD
# ─────────────────────────────────────────────

@pumps_bp.route('/maintenance', methods=['GET'])
def get_all_maintenance():
    pump_id    = request.args.get('pump_id')
    start_date = request.args.get('start_date')
    end_date   = request.args.get('end_date')
    query      = PumpMaintenance.query
    if pump_id:
        query = query.filter(PumpMaintenance.PumpID == int(pump_id))
    if start_date:
        query = query.filter(PumpMaintenance.MaintenanceDate >= _parse_date(start_date))
    if end_date:
        query = query.filter(PumpMaintenance.MaintenanceDate <= _parse_date(end_date))
    records = query.order_by(PumpMaintenance.MaintenanceDate.desc()).all()
    return jsonify([r.to_dict() for r in records])


@pumps_bp.route('/maintenance/add', methods=['POST'])
def add_maintenance():
    d = request.json
    m = PumpMaintenance(
        PumpID          = int(d['pump_id']),
        MaintenanceDate = _parse_date(d['maintenance_date']),
        Technician      = d['technician'],
        WorkDone        = d['work_done'],
        Cost            = float(d.get('cost', 0)),
        NextScheduled   = _parse_date(d.get('next_scheduled')),
        Notes           = d.get('notes', ''),
    )
    db.session.add(m)

    # Auto-update pump dates and set status to Under Maintenance
    pump = Pump.query.get_or_404(int(d['pump_id']))
    pump.LastMaintenanceDate = m.MaintenanceDate
    if m.NextScheduled:
        pump.NextMaintenanceDate = m.NextScheduled
    pump.Status = 'Under Maintenance'

    db.session.commit()
    return jsonify({"message": "Maintenance logged", "id": m.MaintenanceID}), 201


@pumps_bp.route('/maintenance/update/<int:id>', methods=['PUT'])
def update_maintenance(id):
    m = PumpMaintenance.query.get_or_404(id)
    d = request.json
    m.MaintenanceDate = _parse_date(d['maintenance_date'])
    m.Technician      = d['technician']
    m.WorkDone        = d['work_done']
    m.Cost            = float(d.get('cost', 0))
    m.NextScheduled   = _parse_date(d.get('next_scheduled'))
    m.Notes           = d.get('notes', '')

    # Also update pump's last/next dates if provided
    pump = Pump.query.get(m.PumpID)
    if pump:
        pump.LastMaintenanceDate = m.MaintenanceDate
        if m.NextScheduled:
            pump.NextMaintenanceDate = m.NextScheduled

    db.session.commit()
    return jsonify({"message": "Maintenance updated"})


@pumps_bp.route('/maintenance/delete/<int:id>', methods=['DELETE'])
def delete_maintenance(id):
    m = PumpMaintenance.query.get_or_404(id)
    db.session.delete(m)
    db.session.commit()
    return jsonify({"message": "Maintenance record deleted"})


# ─────────────────────────────────────────────
#  FAULT CRUD
# ─────────────────────────────────────────────

@pumps_bp.route('/faults', methods=['GET'])
def get_faults():
    pump_id  = request.args.get('pump_id')
    status   = request.args.get('status')
    query    = PumpFault.query
    if pump_id:
        query = query.filter(PumpFault.PumpID == int(pump_id))
    if status:
        query = query.filter(PumpFault.Status == status)
    faults = query.order_by(PumpFault.FaultDate.desc()).all()
    return jsonify([f.to_dict() for f in faults])


@pumps_bp.route('/faults/add', methods=['POST'])
def add_fault():
    d = request.json
    f = PumpFault(
        PumpID      = int(d['pump_id']),
        FaultDate   = _parse_date(d['fault_date']),
        ReportedBy  = d['reported_by'],
        Description = d['description'],
        Severity    = d.get('severity', 'Medium'),
        Status      = d.get('status', 'Open'),
        Notes       = d.get('notes', ''),
    )
    db.session.add(f)

    # Auto-update pump status: new fault → Inactive
    pump = Pump.query.get(int(d['pump_id']))
    if pump:
        pump.Status = 'Inactive'

    db.session.commit()
    return jsonify({"message": "Fault reported", "id": f.FaultID}), 201


@pumps_bp.route('/faults/update/<int:id>', methods=['PUT'])
def update_fault(id):
    f = PumpFault.query.get_or_404(id)
    d = request.json
    f.FaultDate    = _parse_date(d['fault_date'])
    f.ReportedBy   = d['reported_by']
    f.Description  = d['description']
    f.Severity     = d.get('severity', f.Severity)
    new_status     = d.get('status', f.Status)
    f.Status       = new_status
    f.ResolvedDate = _parse_date(d.get('resolved_date'))
    f.Notes        = d.get('notes', '')

    # Auto-update pump status based on fault resolution
    pump = Pump.query.get(f.PumpID)
    if pump:
        if new_status == 'Resolved':
            # Check if there are other open/in-progress faults for this pump
            other_open = PumpFault.query.filter(
                PumpFault.PumpID == f.PumpID,
                PumpFault.FaultID != f.FaultID,
                PumpFault.Status != 'Resolved'
            ).count()
            if other_open == 0:
                pump.Status = 'Active'
        else:
            pump.Status = 'Inactive'

    db.session.commit()
    return jsonify({"message": "Fault updated"})


@pumps_bp.route('/faults/delete/<int:id>', methods=['DELETE'])
def delete_fault(id):
    f = PumpFault.query.get_or_404(id)
    db.session.delete(f)
    db.session.commit()
    return jsonify({"message": "Fault deleted"})


# ─────────────────────────────────────────────
#  OPERATORS LIST  (for dropdown)
# ─────────────────────────────────────────────

@pumps_bp.route('/operators', methods=['GET'])
def get_operators():
    users = User.query.filter(User.status == 'Active').order_by(User.full_name).all()
    return jsonify([{
        "id":        u.user_id,
        "name":      u.full_name,
        "emp_no":    u.emp_no,
        "role":      u.role.RoleName if u.role else '',
    } for u in users])


# ─────────────────────────────────────────────
#  SUMMARY
# ─────────────────────────────────────────────

@pumps_bp.route('/summary', methods=['GET'])
def get_summary():
    pumps    = Pump.query.all()
    today    = date.today()

    active   = sum(1 for p in pumps if p.Status == 'Active')
    inactive = sum(1 for p in pumps if p.Status == 'Inactive')
    maint    = sum(1 for p in pumps if p.Status == 'Under Maintenance')
    alerts   = [p.to_dict() for p in pumps if p.maintenance_alert() in ('overdue', 'warning')]
    overdue  = [p.to_dict() for p in pumps if p.maintenance_alert() == 'overdue']

    by_fuel = {}
    for p in pumps:
        by_fuel.setdefault(p.FuelType, {'count': 0, 'total_dispensed': 0})
        by_fuel[p.FuelType]['count']           += 1
        by_fuel[p.FuelType]['total_dispensed'] += p.TotalDispensedL

    open_faults = PumpFault.query.filter(PumpFault.Status != 'Resolved').count()

    return jsonify({
        "total_pumps":    len(pumps),
        "active":         active,
        "inactive":       inactive,
        "under_maintenance": maint,
        "alert_count":    len(alerts),
        "overdue_count":  len(overdue),
        "alerts":         alerts,
        "by_fuel":        by_fuel,
        "open_faults":    open_faults,
        "total_dispensed_all": sum(p.TotalDispensedL for p in pumps),
    })


# ─────────────────────────────────────────────
#  HELPER
# ─────────────────────────────────────────────

def _parse_date(val):
    if not val:
        return None
    if isinstance(val, date):
        return val
    return datetime.strptime(val, '%Y-%m-%d').date()