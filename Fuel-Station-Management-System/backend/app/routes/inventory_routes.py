from flask import Blueprint, request, jsonify, render_template
from ..models.inventory import FuelTank
from .. import db
from datetime import datetime

inventory_bp = Blueprint('inventory', __name__, url_prefix='/inventory')


# ─────────────────────────────────────────────
#  PAGE
# ─────────────────────────────────────────────

@inventory_bp.route('/page')
def inventory_page():
    return render_template('inventory.html')


# ─────────────────────────────────────────────
#  GET ALL TANKS
# ─────────────────────────────────────────────

@inventory_bp.route('/tanks')
def get_tanks():
    tanks = FuelTank.query.order_by(FuelTank.tank_id).all()
    return jsonify([t.to_dict() for t in tanks])


# ─────────────────────────────────────────────
#  GET SINGLE TANK
# ─────────────────────────────────────────────

@inventory_bp.route('/tanks/<string:tank_id>')
def get_tank(tank_id):
    tank = FuelTank.query.filter_by(tank_id=tank_id).first_or_404()
    return jsonify(tank.to_dict())


# ─────────────────────────────────────────────
#  UPDATE STOCK LEVEL (manual adjustment)
# ─────────────────────────────────────────────

@inventory_bp.route('/tanks/<string:tank_id>/stock', methods=['PUT'])
def update_stock(tank_id):
    tank = FuelTank.query.filter_by(tank_id=tank_id).first_or_404()
    d    = request.get_json()

    new_stock = float(d.get('current_stock_l', tank.current_stock_l))

    if new_stock < 0:
        return jsonify({'message': 'Stock cannot be negative'}), 400
    if new_stock > tank.capacity_l:
        return jsonify({'message': f'Stock cannot exceed tank capacity of {tank.capacity_l}L'}), 400

    tank.current_stock_l = new_stock
    tank.last_updated    = datetime.utcnow()
    db.session.commit()
    return jsonify({'message': 'Stock updated', 'tank': tank.to_dict()})


# ─────────────────────────────────────────────
#  UPDATE TANK SETTINGS (threshold, notes etc.)
# ─────────────────────────────────────────────

@inventory_bp.route('/tanks/<string:tank_id>/settings', methods=['PUT'])
def update_tank_settings(tank_id):
    tank = FuelTank.query.filter_by(tank_id=tank_id).first_or_404()
    d    = request.get_json()

    if 'low_stock_threshold_l' in d:
        tank.low_stock_threshold_l = float(d['low_stock_threshold_l'])
    if 'notes' in d:
        tank.notes = d['notes']
    if 'location' in d:
        tank.location = d['location']

    db.session.commit()
    return jsonify({'message': 'Settings updated', 'tank': tank.to_dict()})


# ─────────────────────────────────────────────
#  SUMMARY — KPIs for dashboard
# ─────────────────────────────────────────────

@inventory_bp.route('/summary')
def summary():
    tanks      = FuelTank.query.all()
    total_cap  = sum(t.capacity_l       for t in tanks)
    total_stock= sum(t.current_stock_l  for t in tanks)
    low_tanks  = [t.tank_id for t in tanks if t.is_low]

    return jsonify({
        'total_capacity_l':  round(total_cap,   2),
        'total_stock_l':     round(total_stock, 2),
        'overall_pct':       round((total_stock / total_cap * 100), 1) if total_cap else 0,
        'low_stock_tanks':   low_tanks,
        'tank_count':        len(tanks),
    })