from flask import Blueprint, request, jsonify
from ..models.iot import IoTReading, FireEvent
from ..models.inventory import FuelTank
from .. import db
from datetime import datetime, timedelta
from sqlalchemy import func

iot_bp = Blueprint('iot', __name__, url_prefix='/iot')

# Capacity map — used to calculate litres from percentage
# Keyed by iot_device_id
DEVICE_CAPACITY = {}

def _get_capacity(device_id):
    """Look up tank capacity from DB for litre calculation."""
    if device_id not in DEVICE_CAPACITY:
        tank = FuelTank.query.filter_by(iot_device_id=device_id).first()
        DEVICE_CAPACITY[device_id] = tank.capacity_l if tank else 0
    return DEVICE_CAPACITY[device_id]


# ─────────────────────────────────────────────
#  SAVE SNAPSHOT  — called by frontend every 5 mins
# ─────────────────────────────────────────────

@iot_bp.route('/snapshot', methods=['POST'])
def save_snapshot():
    """
    Frontend sends current Firebase state every 5 minutes.
    We save it to PostgreSQL for historical charts.
    """
    d         = request.get_json()
    device_id = d.get('device_id')

    if not device_id:
        return jsonify({'message': 'device_id is required'}), 400

    capacity      = _get_capacity(device_id)
    fuel_pct      = float(d.get('fuel_level_pct', 0))
    fuel_l        = round(fuel_pct * capacity / 100, 2)

    reading = IoTReading(
        device_id      = device_id,
        fuel_level_pct = fuel_pct,
        fuel_level_l   = fuel_l,
        temperature    = float(d.get('temperature', 0)),
        distance       = float(d.get('distance', 0)),
        fire_detected  = bool(d.get('fire_detected', False)),
        pump_running   = bool(d.get('pump_running', False)),
        in_cooldown    = bool(d.get('in_cooldown', False)),
        alert_level    = d.get('alert_level', 'normal'),
        recorded_at    = datetime.utcnow(),
    )
    db.session.add(reading)

    # Also update the manual tank's current_stock_l to stay in sync
    tank = FuelTank.query.filter_by(iot_device_id=device_id).first()
    if tank:
        tank.current_stock_l = fuel_l
        tank.last_updated    = datetime.utcnow()

    db.session.commit()
    return jsonify({'message': 'Snapshot saved', 'fuel_l': fuel_l}), 201


# ─────────────────────────────────────────────
#  SAVE FIRE EVENT  — called when fire detected
# ─────────────────────────────────────────────

@iot_bp.route('/fire-event', methods=['POST'])
def save_fire_event():
    """
    Called by frontend when a new fire event appears in Firebase.
    Uses firebase_event_key for deduplication — same event won't be saved twice.
    """
    d         = request.get_json()
    device_id = d.get('device_id')
    event_key = d.get('firebase_event_key')

    if not device_id:
        return jsonify({'message': 'device_id is required'}), 400

    # Deduplication check
    if event_key:
        existing = FireEvent.query.filter_by(
            device_id=device_id,
            firebase_event_key=event_key
        ).first()
        if existing:
            return jsonify({'message': 'Event already recorded'}), 200

    capacity  = _get_capacity(device_id)
    fuel_pct  = float(d.get('fuel_level_pct', 0))
    fuel_l    = round(fuel_pct * capacity / 100, 2)

    event = FireEvent(
        device_id          = device_id,
        fuel_level_pct     = fuel_pct,
        fuel_level_l       = fuel_l,
        temperature        = float(d.get('temperature', 0)),
        pump_activated     = bool(d.get('pump_activated', False)),
        status             = d.get('status', 'detected'),
        firebase_event_key = event_key,
        firebase_timestamp = d.get('firebase_timestamp'),
        recorded_at        = datetime.utcnow(),
    )
    db.session.add(event)
    db.session.commit()
    return jsonify({'message': 'Fire event saved', 'id': event.id}), 201


# ─────────────────────────────────────────────
#  GET READING HISTORY  — last 7 days for charts
# ─────────────────────────────────────────────

@iot_bp.route('/history/<string:device_id>')
def get_history(device_id):
    days  = int(request.args.get('days', 7))
    since = datetime.utcnow() - timedelta(days=days)

    readings = IoTReading.query.filter(
        IoTReading.device_id  == device_id,
        IoTReading.recorded_at >= since
    ).order_by(IoTReading.recorded_at.asc()).all()

    return jsonify([r.to_dict() for r in readings])


# ─────────────────────────────────────────────
#  GET FIRE EVENTS  — full timeline
# ─────────────────────────────────────────────

@iot_bp.route('/fire-events/<string:device_id>')
def get_fire_events(device_id):
    events = FireEvent.query.filter_by(
        device_id=device_id
    ).order_by(FireEvent.recorded_at.desc()).all()
    return jsonify([e.to_dict() for e in events])


# ─────────────────────────────────────────────
#  LATEST READING  — most recent snapshot
# ─────────────────────────────────────────────

@iot_bp.route('/latest/<string:device_id>')
def get_latest(device_id):
    reading = IoTReading.query.filter_by(
        device_id=device_id
    ).order_by(IoTReading.recorded_at.desc()).first()

    if not reading:
        return jsonify({'message': 'No readings found'}), 404
    return jsonify(reading.to_dict())


# ─────────────────────────────────────────────
#  STATS  — min/max/avg for a device
# ─────────────────────────────────────────────

@iot_bp.route('/stats/<string:device_id>')
def get_stats(device_id):
    days  = int(request.args.get('days', 7))
    since = datetime.utcnow() - timedelta(days=days)

    stats = db.session.query(
        func.min(IoTReading.fuel_level_pct).label('min_fuel'),
        func.max(IoTReading.fuel_level_pct).label('max_fuel'),
        func.avg(IoTReading.fuel_level_pct).label('avg_fuel'),
        func.min(IoTReading.temperature).label('min_temp'),
        func.max(IoTReading.temperature).label('max_temp'),
        func.avg(IoTReading.temperature).label('avg_temp'),
        func.count(IoTReading.id).label('reading_count'),
    ).filter(
        IoTReading.device_id   == device_id,
        IoTReading.recorded_at >= since
    ).first()

    fire_count = FireEvent.query.filter(
        FireEvent.device_id   == device_id,
        FireEvent.recorded_at >= since
    ).count()

    return jsonify({
        'device_id':     device_id,
        'days':          days,
        'reading_count': int(stats.reading_count or 0),
        'fire_count':    fire_count,
        'fuel': {
            'min': round(float(stats.min_fuel or 0), 1),
            'max': round(float(stats.max_fuel or 0), 1),
            'avg': round(float(stats.avg_fuel or 0), 1),
        },
        'temperature': {
            'min': round(float(stats.min_temp or 0), 1),
            'max': round(float(stats.max_temp or 0), 1),
            'avg': round(float(stats.avg_temp or 0), 1),
        },
    })