from flask import Blueprint, request, jsonify, render_template
from ..models.sales import (
    FuelPrice, DailySale, CreditAccount, CreditSale,
    CreditPayment, FuelDelivery
)
from ..models.pumps import Pump
from ..models.suppliers import Supplier
from ..models.shift import Shift
from ..models.user import User
from .. import db
from datetime import datetime, date, timedelta
from sqlalchemy import func

from .auth_routes import login_required, role_required

sales_bp = Blueprint('sales', __name__, url_prefix='/sales')

FUEL_TYPES = ['92 Octane', '95 Octane', 'Auto Diesel', 'Super Diesel']


# ─────────────────────────────────────────────
#  PAGE
# ─────────────────────────────────────────────

@sales_bp.route('/page')
def sales_page():
    return render_template('sales.html')


# ─────────────────────────────────────────────
#  DASHBOARD SUMMARY
# ─────────────────────────────────────────────

@sales_bp.route('/summary')
def summary():
    today            = date.today()
    this_month_start = today.replace(day=1)

    today_sales = db.session.query(
        func.sum(DailySale.total_amount).label('revenue'),
        func.sum(DailySale.litres_sold).label('litres'),
        func.count(DailySale.sale_id).label('txns')
    ).filter(DailySale.sale_date == today).first()

    today_credit = db.session.query(
        func.sum(CreditSale.total_amount).label('revenue'),
        func.sum(CreditSale.litres_sold).label('litres')
    ).filter(CreditSale.sale_date == today).first()

    month_cash = db.session.query(
        func.sum(DailySale.total_amount)
    ).filter(DailySale.sale_date >= this_month_start).scalar() or 0

    month_credit_sales = db.session.query(
        func.sum(CreditSale.total_amount)
    ).filter(CreditSale.sale_date >= this_month_start).scalar() or 0

    total_outstanding = db.session.query(
        func.sum(CreditAccount.outstanding_balance)
    ).filter(CreditAccount.status == 'Active').scalar() or 0

    fuel_breakdown = {}
    for ft in FUEL_TYPES:
        cash_l = db.session.query(func.sum(DailySale.litres_sold)).join(
            Pump, DailySale.pump_id == Pump.PumpID
        ).filter(DailySale.sale_date == today, Pump.FuelType == ft).scalar() or 0
        credit_l = db.session.query(func.sum(CreditSale.litres_sold)).filter(
            CreditSale.sale_date == today, CreditSale.fuel_type == ft
        ).scalar() or 0
        fuel_breakdown[ft] = round(float(cash_l) + float(credit_l), 2)

    trend = []
    for i in range(6, -1, -1):
        d = today - timedelta(days=i)
        cash_r   = db.session.query(func.sum(DailySale.total_amount)).filter(DailySale.sale_date   == d).scalar() or 0
        credit_r = db.session.query(func.sum(CreditSale.total_amount)).filter(CreditSale.sale_date == d).scalar() or 0
        trend.append({'date': str(d), 'cash': float(cash_r), 'credit': float(credit_r), 'total': float(cash_r) + float(credit_r)})

    return jsonify({
        'today_cash_revenue':   float(today_sales.revenue  or 0),
        'today_cash_litres':    float(today_sales.litres   or 0),
        'today_credit_revenue': float(today_credit.revenue or 0),
        'today_credit_litres':  float(today_credit.litres  or 0),
        'today_total_revenue':  float((today_sales.revenue or 0) + (today_credit.revenue or 0)),
        'today_total_litres':   float((today_sales.litres  or 0) + (today_credit.litres  or 0)),
        'month_cash_revenue':   float(month_cash),
        'month_credit_revenue': float(month_credit_sales),
        'month_total_revenue':  float(month_cash) + float(month_credit_sales),
        'total_outstanding':    float(total_outstanding),
        'fuel_breakdown':       fuel_breakdown,
        'trend':                trend,
    })


# ─────────────────────────────────────────────
#  FUEL PRICES
# ─────────────────────────────────────────────

@sales_bp.route('/prices')
def get_prices():
    return jsonify([p.to_dict() for p in FuelPrice.query.order_by(FuelPrice.fuel_type).all()])

@sales_bp.route('/prices/update/<int:id>', methods=['PUT'])
@login_required
@role_required(1, 7)
def update_price(id):
    fp = FuelPrice.query.get_or_404(id)
    d  = request.json
    fp.price_per_litre = float(d['price_per_litre'])
    fp.effective_date  = _parse_date(d.get('effective_date')) or date.today()
    fp.updated_by      = d.get('updated_by', '')
    fp.notes           = d.get('notes', '')
    db.session.commit()
    return jsonify({'message': 'Price updated', 'price': fp.to_dict()})


# ─────────────────────────────────────────────
#  DAILY SALES  CRUD
# ─────────────────────────────────────────────

@sales_bp.route('/daily')
def get_daily_sales():
    sale_date  = request.args.get('date')
    pump_id    = request.args.get('pump_id')
    start      = request.args.get('start_date')
    end        = request.args.get('end_date')
    shift      = request.args.get('shift_period')
    pay_method = request.args.get('payment_method')

    q = DailySale.query
    if sale_date:  q = q.filter(DailySale.sale_date      == sale_date)
    if start:      q = q.filter(DailySale.sale_date      >= _parse_date(start))
    if end:        q = q.filter(DailySale.sale_date      <= _parse_date(end))
    if pump_id:    q = q.filter(DailySale.pump_id        == int(pump_id))
    if shift:      q = q.filter(DailySale.shift_period   == shift)
    if pay_method: q = q.filter(DailySale.payment_method == pay_method)

    return jsonify([s.to_dict() for s in q.order_by(DailySale.sale_date.desc(), DailySale.sale_id.desc()).all()])

@sales_bp.route('/daily/add', methods=['POST'])
def add_daily_sale():
    d      = request.json
    litres = _calc_litres(d)
    if litres is None or litres <= 0:
        return jsonify({'message': 'Invalid litres: check meter readings or quantity'}), 400

    price = float(d['price_per_litre'])
    sale  = DailySale(
        sale_date       = _parse_date(d['sale_date']),
        pump_id         = int(d['pump_id']),
        shift_id        = int(d['shift_id'])       if d.get('shift_id')       else None,
        user_id         = int(d['user_id'])         if d.get('user_id')         else None,
        record_type     = d.get('record_type', 'shift'),
        opening_meter   = float(d['opening_meter']) if d.get('opening_meter')  else None,
        closing_meter   = float(d['closing_meter']) if d.get('closing_meter')  else None,
        litres_sold     = litres,
        price_per_litre = price,
        total_amount    = round(litres * price, 2),
        payment_method  = d.get('payment_method', 'Cash'),
        shift_period    = d.get('shift_period',   'Morning'),
        notes           = d.get('notes', ''),
    )
    db.session.add(sale)
    pump = Pump.query.get(int(d['pump_id']))
    if pump:
        pump.TotalDispensedL = float(pump.TotalDispensedL or 0) + litres
    db.session.commit()
    return jsonify({'message': 'Sale recorded', 'id': sale.sale_id}), 201

@sales_bp.route('/daily/update/<int:id>', methods=['PUT'])
@login_required
@role_required(1, 7)
def update_daily_sale(id):
    sale       = DailySale.query.get_or_404(id)
    d          = request.json
    old_litres = float(sale.litres_sold)
    litres     = _calc_litres(d)
    if litres is None or litres <= 0:
        return jsonify({'message': 'Invalid litres'}), 400

    price = float(d['price_per_litre'])
    sale.sale_date       = _parse_date(d['sale_date'])
    sale.pump_id         = int(d['pump_id'])
    sale.shift_id        = int(d['shift_id'])       if d.get('shift_id')       else None
    sale.user_id         = int(d['user_id'])         if d.get('user_id')         else None
    sale.record_type     = d.get('record_type',     sale.record_type)
    sale.opening_meter   = float(d['opening_meter']) if d.get('opening_meter')  else None
    sale.closing_meter   = float(d['closing_meter']) if d.get('closing_meter')  else None
    sale.litres_sold     = litres
    sale.price_per_litre = price
    sale.total_amount    = round(litres * price, 2)
    sale.payment_method  = d.get('payment_method',  sale.payment_method)
    sale.shift_period    = d.get('shift_period',     sale.shift_period)
    sale.notes           = d.get('notes', '')

    pump = Pump.query.get(int(d['pump_id']))
    if pump:
        pump.TotalDispensedL = float(pump.TotalDispensedL or 0) - old_litres + litres
    db.session.commit()
    return jsonify({'message': 'Sale updated'})

@sales_bp.route('/daily/delete/<int:id>', methods=['DELETE'])
@login_required
@role_required(1, 7)
def delete_daily_sale(id):
    sale = DailySale.query.get_or_404(id)
    pump = Pump.query.get(sale.pump_id)
    if pump:
        pump.TotalDispensedL = max(0, float(pump.TotalDispensedL or 0) - float(sale.litres_sold))
    db.session.delete(sale)
    db.session.commit()
    return jsonify({'message': 'Sale deleted'})


# ─────────────────────────────────────────────
#  CREDIT ACCOUNTS  CRUD
# ─────────────────────────────────────────────

@sales_bp.route('/credit/accounts')
def get_credit_accounts():
    status = request.args.get('status')
    q = CreditAccount.query
    if status:
        q = q.filter(CreditAccount.status == status)
    return jsonify([a.to_dict() for a in q.order_by(CreditAccount.account_name).all()])

@sales_bp.route('/credit/accounts/add', methods=['POST'])
def add_credit_account():
    d = request.json
    a = CreditAccount(
        account_name   = d['account_name'],
        contact_person = d.get('contact_person', ''),
        contact_phone  = d.get('contact_phone',  ''),
        contact_email  = d.get('contact_email',  ''),
        address        = d.get('address',        ''),
        credit_limit   = float(d.get('credit_limit', 0)),
        status         = d.get('status', 'Active'),
        notes          = d.get('notes', ''),
    )
    db.session.add(a)
    db.session.commit()
    return jsonify({'message': 'Account created', 'id': a.account_id}), 201

@sales_bp.route('/credit/accounts/update/<int:id>', methods=['PUT'])
def update_credit_account(id):
    a = CreditAccount.query.get_or_404(id)
    d = request.json
    a.account_name   = d['account_name']
    a.contact_person = d.get('contact_person', '')
    a.contact_phone  = d.get('contact_phone',  '')
    a.contact_email  = d.get('contact_email',  '')
    a.address        = d.get('address',        '')
    a.credit_limit   = float(d.get('credit_limit', a.credit_limit))
    a.status         = d.get('status', a.status)
    a.notes          = d.get('notes', '')
    db.session.commit()
    return jsonify({'message': 'Account updated'})

@sales_bp.route('/credit/accounts/delete/<int:id>', methods=['DELETE'])
@login_required
@role_required(1, 7)
def delete_credit_account(id):
    a = CreditAccount.query.get_or_404(id)
    if len(a.credit_sales) > 0 or len(a.credit_payments) > 0:
        return jsonify({'message': 'Cannot delete account with existing transactions'}), 400
    db.session.delete(a)
    db.session.commit()
    return jsonify({'message': 'Account deleted'})


# ─────────────────────────────────────────────
#  CREDIT SALES  CRUD
# ─────────────────────────────────────────────

@sales_bp.route('/credit/sales')
def get_credit_sales():
    account_id = request.args.get('account_id')
    pump_id    = request.args.get('pump_id')
    start      = request.args.get('start_date')
    end        = request.args.get('end_date')

    q = CreditSale.query
    if account_id: q = q.filter(CreditSale.account_id == int(account_id))
    if pump_id:    q = q.filter(CreditSale.pump_id    == int(pump_id))
    if start:      q = q.filter(CreditSale.sale_date  >= _parse_date(start))
    if end:        q = q.filter(CreditSale.sale_date  <= _parse_date(end))
    return jsonify([s.to_dict() for s in q.order_by(CreditSale.sale_date.desc()).all()])

@sales_bp.route('/credit/sales/add', methods=['POST'])
def add_credit_sale():
    d       = request.json
    account = CreditAccount.query.get_or_404(int(d['account_id']))

    if account.status == 'Suspended':
        return jsonify({'message': 'Account is suspended. Cannot record credit sale.'}), 400

    litres    = float(d['litres_sold'])
    price     = float(d['price_per_litre'])
    amount    = round(litres * price, 2)
    available = float(account.credit_limit) - float(account.outstanding_balance)

    if amount > available:
        return jsonify({'message': f'Credit limit exceeded. Available: Rs.{available:,.2f}, Requested: Rs.{amount:,.2f}'}), 400

    sale = CreditSale(
        sale_date       = _parse_date(d['sale_date']),
        account_id      = int(d['account_id']),
        pump_id         = int(d['pump_id']),
        shift_id        = int(d['shift_id']) if d.get('shift_id') else None,
        user_id         = int(d['user_id'])  if d.get('user_id')  else None,
        vehicle_number  = d.get('vehicle_number', ''),
        litres_sold     = litres,
        price_per_litre = price,
        total_amount    = amount,
        fuel_type       = d.get('fuel_type', ''),
        reference       = d.get('reference', ''),
        notes           = d.get('notes', ''),
    )
    db.session.add(sale)
    account.outstanding_balance = float(account.outstanding_balance) + amount
    pump = Pump.query.get(int(d['pump_id']))
    if pump:
        pump.TotalDispensedL = float(pump.TotalDispensedL or 0) + litres
    db.session.commit()
    return jsonify({'message': 'Credit sale recorded', 'id': sale.credit_sale_id}), 201

@sales_bp.route('/credit/sales/update/<int:id>', methods=['PUT'])

def update_credit_sale(id):
    sale       = CreditSale.query.get_or_404(id)
    d          = request.json
    account    = CreditAccount.query.get_or_404(sale.account_id)
    old_amount = float(sale.total_amount)
    old_litres = float(sale.litres_sold)
    litres     = float(d['litres_sold'])
    price      = float(d['price_per_litre'])
    new_amount = round(litres * price, 2)

    sale.sale_date       = _parse_date(d['sale_date'])
    sale.shift_id        = int(d['shift_id']) if d.get('shift_id') else None
    sale.user_id         = int(d['user_id'])  if d.get('user_id')  else None
    sale.vehicle_number  = d.get('vehicle_number', '')
    sale.litres_sold     = litres
    sale.price_per_litre = price
    sale.total_amount    = new_amount
    sale.fuel_type       = d.get('fuel_type', sale.fuel_type)
    sale.reference       = d.get('reference', '')
    sale.notes           = d.get('notes', '')

    account.outstanding_balance = float(account.outstanding_balance) - old_amount + new_amount
    pump = Pump.query.get(sale.pump_id)
    if pump:
        pump.TotalDispensedL = float(pump.TotalDispensedL or 0) - old_litres + litres
    db.session.commit()
    return jsonify({'message': 'Credit sale updated'})

@sales_bp.route('/credit/sales/delete/<int:id>', methods=['DELETE'])
@login_required
@role_required(1, 7)
def delete_credit_sale(id):
    sale    = CreditSale.query.get_or_404(id)
    account = CreditAccount.query.get(sale.account_id)
    if account:
        account.outstanding_balance = max(0, float(account.outstanding_balance) - float(sale.total_amount))
    pump = Pump.query.get(sale.pump_id)
    if pump:
        pump.TotalDispensedL = max(0, float(pump.TotalDispensedL or 0) - float(sale.litres_sold))
    db.session.delete(sale)
    db.session.commit()
    return jsonify({'message': 'Credit sale deleted'})


# ─────────────────────────────────────────────
#  CREDIT PAYMENTS  CRUD
# ─────────────────────────────────────────────

@sales_bp.route('/credit/payments')
def get_credit_payments():
    account_id = request.args.get('account_id')
    start      = request.args.get('start_date')
    end        = request.args.get('end_date')

    q = CreditPayment.query
    if account_id: q = q.filter(CreditPayment.account_id   == int(account_id))
    if start:      q = q.filter(CreditPayment.payment_date >= _parse_date(start))
    if end:        q = q.filter(CreditPayment.payment_date <= _parse_date(end))
    return jsonify([p.to_dict() for p in q.order_by(CreditPayment.payment_date.desc()).all()])

@sales_bp.route('/credit/payments/add', methods=['POST'])
def add_credit_payment():
    d       = request.json
    account = CreditAccount.query.get_or_404(int(d['account_id']))
    amount  = float(d['amount'])

    payment = CreditPayment(
        payment_date     = _parse_date(d['payment_date']),
        account_id       = int(d['account_id']),
        user_id          = int(d['user_id']) if d.get('user_id') else None,
        amount           = amount,
        payment_method   = d.get('payment_method', 'Cash'),
        reference_number = d.get('reference_number', ''),
        notes            = d.get('notes', ''),
    )
    db.session.add(payment)
    account.outstanding_balance = max(0, float(account.outstanding_balance) - amount)
    db.session.commit()
    return jsonify({'message': 'Payment recorded', 'id': payment.payment_id}), 201

@sales_bp.route('/credit/payments/delete/<int:id>', methods=['DELETE'])
@login_required
@role_required(1, 7)
def delete_credit_payment(id):
    payment = CreditPayment.query.get_or_404(id)
    account = CreditAccount.query.get(payment.account_id)
    if account:
        account.outstanding_balance = float(account.outstanding_balance) + float(payment.amount)
    db.session.delete(payment)
    db.session.commit()
    return jsonify({'message': 'Payment deleted'})


# ─────────────────────────────────────────────
#  CREDIT ACCOUNT STATEMENT
# ─────────────────────────────────────────────

@sales_bp.route('/credit/accounts/<int:id>/statement')
def account_statement(id):
    account = CreditAccount.query.get_or_404(id)
    start   = request.args.get('start_date')
    end     = request.args.get('end_date')

    sq = CreditSale.query.filter(CreditSale.account_id == id)
    pq = CreditPayment.query.filter(CreditPayment.account_id == id)
    if start:
        sq = sq.filter(CreditSale.sale_date       >= _parse_date(start))
        pq = pq.filter(CreditPayment.payment_date >= _parse_date(start))
    if end:
        sq = sq.filter(CreditSale.sale_date       <= _parse_date(end))
        pq = pq.filter(CreditPayment.payment_date <= _parse_date(end))

    entries = []
    for s in sq.order_by(CreditSale.sale_date).all():
        entries.append({
            'date':        str(s.sale_date),
            'type':        'sale',
            'description': f"{s.fuel_type} — {s.pump.PumpNumber if s.pump else ''} — {s.vehicle_number or ''}",
            'debit':       float(s.total_amount),
            'credit':      0,
            'reference':   s.reference or '',
        })
    for p in pq.order_by(CreditPayment.payment_date).all():
        entries.append({
            'date':        str(p.payment_date),
            'type':        'payment',
            'description': f"Payment — {p.payment_method}",
            'debit':       0,
            'credit':      float(p.amount),
            'reference':   p.reference_number or '',
        })
    entries.sort(key=lambda x: x['date'])

    running = 0
    for e in entries:
        running += e['debit'] - e['credit']
        e['balance'] = round(running, 2)

    return jsonify({
        'account':         account.to_dict(),
        'entries':         entries,
        'total_sales':     sum(e['debit']  for e in entries),
        'total_payments':  sum(e['credit'] for e in entries),
        'closing_balance': running,
    })


# ─────────────────────────────────────────────
#  FUEL SUPPLIERS  (read-only for delivery dropdowns)
# ─────────────────────────────────────────────

@sales_bp.route('/suppliers')
def get_fuel_suppliers():
    suppliers = Supplier.query.filter(
        Supplier.Type.in_(['Fuel', 'Both']),
        Supplier.IsActive == True
    ).order_by(Supplier.Name).all()
    return jsonify([{
        'supplier_id': s.SupplierID,
        'name':        s.Name,
        'type':        s.Type,
        'phone':       s.Phone,
        'email':       s.Email,
    } for s in suppliers])


# ─────────────────────────────────────────────
#  FUEL DELIVERIES  CRUD
# ─────────────────────────────────────────────

@sales_bp.route('/deliveries')
def get_deliveries():
    supplier_id = request.args.get('supplier_id')
    fuel_type   = request.args.get('fuel_type')
    start       = request.args.get('start_date')
    end         = request.args.get('end_date')

    q = FuelDelivery.query
    if supplier_id: q = q.filter(FuelDelivery.supplier_id   == int(supplier_id))
    if fuel_type:   q = q.filter(FuelDelivery.fuel_type     == fuel_type)
    if start:       q = q.filter(FuelDelivery.delivery_date >= _parse_date(start))
    if end:         q = q.filter(FuelDelivery.delivery_date <= _parse_date(end))
    return jsonify([d.to_dict() for d in q.order_by(FuelDelivery.delivery_date.desc()).all()])

@sales_bp.route('/deliveries/add', methods=['POST'])
def add_delivery():
    d      = request.json
    litres = float(d['litres_delivered'])
    price  = float(d['price_per_litre'])

    delivery = FuelDelivery(
        delivery_date    = _parse_date(d['delivery_date']),
        supplier_id      = int(d['supplier_id']) if d.get('supplier_id') else None,
        invoice_number   = d.get('invoice_number',   ''),
        fuel_type        = d['fuel_type'],
        litres_delivered = litres,
        price_per_litre  = price,
        total_cost       = round(litres * price, 2),
        delivery_vehicle = d.get('delivery_vehicle', ''),
        driver_name      = d.get('driver_name',      ''),
        received_by      = d.get('received_by',      ''),
        notes            = d.get('notes',            ''),
    )
    db.session.add(delivery)
    try:
        from ..models.inventory import FuelInventory
        inv = FuelInventory.query.filter_by(FuelType=d['fuel_type']).first()
        if inv:
            inv.CurrentStock = float(inv.CurrentStock or 0) + litres
    except Exception:
        pass
    db.session.commit()
    return jsonify({'message': 'Delivery recorded', 'id': delivery.delivery_id}), 201

@sales_bp.route('/deliveries/update/<int:id>', methods=['PUT'])
def update_delivery(id):
    delivery   = FuelDelivery.query.get_or_404(id)
    d          = request.json
    old_litres = float(delivery.litres_delivered)
    litres     = float(d['litres_delivered'])
    price      = float(d['price_per_litre'])

    delivery.delivery_date    = _parse_date(d['delivery_date'])
    delivery.supplier_id      = int(d['supplier_id']) if d.get('supplier_id') else None
    delivery.invoice_number   = d.get('invoice_number',   '')
    delivery.fuel_type        = d['fuel_type']
    delivery.litres_delivered = litres
    delivery.price_per_litre  = price
    delivery.total_cost       = round(litres * price, 2)
    delivery.delivery_vehicle = d.get('delivery_vehicle', '')
    delivery.driver_name      = d.get('driver_name',      '')
    delivery.received_by      = d.get('received_by',      '')
    delivery.notes            = d.get('notes',            '')
    try:
        from ..models.inventory import FuelInventory
        inv = FuelInventory.query.filter_by(FuelType=d['fuel_type']).first()
        if inv:
            inv.CurrentStock = max(0, float(inv.CurrentStock or 0) - old_litres + litres)
    except Exception:
        pass
    db.session.commit()
    return jsonify({'message': 'Delivery updated'})

@sales_bp.route('/deliveries/delete/<int:id>', methods=['DELETE'])
@login_required
@role_required(1, 7)
def delete_delivery(id):
    delivery = FuelDelivery.query.get_or_404(id)
    try:
        from ..models.inventory import FuelInventory
        inv = FuelInventory.query.filter_by(FuelType=delivery.fuel_type).first()
        if inv:
            inv.CurrentStock = max(0, float(inv.CurrentStock or 0) - float(delivery.litres_delivered))
    except Exception:
        pass
    db.session.delete(delivery)
    db.session.commit()
    return jsonify({'message': 'Delivery deleted'})


# ─────────────────────────────────────────────
#  REPORTS
# ─────────────────────────────────────────────

@sales_bp.route('/reports/revenue')
def revenue_report():
    start = request.args.get('start_date')
    end   = request.args.get('end_date')
    if not start or not end:
        today = date.today()
        start = str(today.replace(day=1))
        end   = str(today)

    daily_cash = db.session.query(
        DailySale.sale_date,
        func.sum(DailySale.total_amount).label('cash_revenue'),
        func.sum(DailySale.litres_sold).label('cash_litres'),
        func.count(DailySale.sale_id).label('transactions')
    ).filter(
        DailySale.sale_date >= _parse_date(start),
        DailySale.sale_date <= _parse_date(end)
    ).group_by(DailySale.sale_date).all()

    daily_credit = db.session.query(
        CreditSale.sale_date,
        func.sum(CreditSale.total_amount).label('credit_revenue'),
        func.sum(CreditSale.litres_sold).label('credit_litres')
    ).filter(
        CreditSale.sale_date >= _parse_date(start),
        CreditSale.sale_date <= _parse_date(end)
    ).group_by(CreditSale.sale_date).all()

    cash_map   = {str(r.sale_date): r for r in daily_cash}
    credit_map = {str(r.sale_date): r for r in daily_credit}
    all_dates  = sorted(set(list(cash_map.keys()) + list(credit_map.keys())))

    rows = []
    for d in all_dates:
        cr = cash_map.get(d)
        cd = credit_map.get(d)
        cash_rev   = float(cr.cash_revenue   or 0) if cr else 0
        cash_l     = float(cr.cash_litres    or 0) if cr else 0
        credit_rev = float(cd.credit_revenue or 0) if cd else 0
        credit_l   = float(cd.credit_litres  or 0) if cd else 0
        rows.append({
            'date':           d,
            'cash_revenue':   cash_rev,
            'cash_litres':    cash_l,
            'credit_revenue': credit_rev,
            'credit_litres':  credit_l,
            'total_revenue':  cash_rev + credit_rev,
            'total_litres':   cash_l   + credit_l,
            'transactions':   int(cr.transactions or 0) if cr else 0,
        })

    pump_breakdown = db.session.query(
        Pump.PumpNumber, Pump.PumpName, Pump.FuelType,
        func.sum(DailySale.litres_sold).label('litres'),
        func.sum(DailySale.total_amount).label('revenue')
    ).join(DailySale, DailySale.pump_id == Pump.PumpID).filter(
        DailySale.sale_date >= _parse_date(start),
        DailySale.sale_date <= _parse_date(end)
    ).group_by(Pump.PumpID).all()

    pay_breakdown = db.session.query(
        DailySale.payment_method,
        func.sum(DailySale.total_amount).label('amount'),
        func.count(DailySale.sale_id).label('count')
    ).filter(
        DailySale.sale_date >= _parse_date(start),
        DailySale.sale_date <= _parse_date(end)
    ).group_by(DailySale.payment_method).all()

    return jsonify({
        'start_date': start,
        'end_date':   end,
        'daily_rows': rows,
        'totals': {
            'cash_revenue':   sum(r['cash_revenue']   for r in rows),
            'credit_revenue': sum(r['credit_revenue'] for r in rows),
            'total_revenue':  sum(r['total_revenue']  for r in rows),
            'total_litres':   sum(r['total_litres']   for r in rows),
        },
        'pump_breakdown': [{
            'pump_number': p.PumpNumber,
            'pump_name':   p.PumpName,
            'fuel_type':   p.FuelType,
            'litres':      float(p.litres  or 0),
            'revenue':     float(p.revenue or 0),
        } for p in pump_breakdown],
        'payment_breakdown': [{
            'method': p.payment_method,
            'amount': float(p.amount or 0),
            'count':  int(p.count   or 0),
        } for p in pay_breakdown],
    })

@sales_bp.route('/reports/credit')
def credit_report():
    accounts = CreditAccount.query.order_by(CreditAccount.account_name).all()
    rows = []
    for a in accounts:
        total_sales    = db.session.query(func.sum(CreditSale.total_amount)).filter(CreditSale.account_id == a.account_id).scalar() or 0
        total_payments = db.session.query(func.sum(CreditPayment.amount)).filter(CreditPayment.account_id == a.account_id).scalar() or 0
        rows.append({**a.to_dict(), 'total_sales': float(total_sales), 'total_payments': float(total_payments)})
    return jsonify(rows)


# ─────────────────────────────────────────────
#  HELPER DROPDOWN ENDPOINTS
# ─────────────────────────────────────────────

@sales_bp.route('/pumps')
def get_pumps():
    pumps = Pump.query.filter(Pump.Status == 'Active').order_by(Pump.PumpNumber).all()
    return jsonify([{
        'id':          p.PumpID,
        'pump_number': p.PumpNumber,
        'pump_name':   p.PumpName,
        'fuel_type':   p.FuelType,
    } for p in pumps])

@sales_bp.route('/shifts')
def get_shifts():
    shift_date = request.args.get('date', str(date.today()))
    shifts = Shift.query.filter(
        Shift.ShiftDate == _parse_date(shift_date)
    ).order_by(Shift.StartTime).all()
    return jsonify([{
        'id':           s.ShiftID,
        'user_id':      s.UserID,
        'user_name':    s.user.full_name if s.user else '',
        'start_time':   str(s.StartTime),
        'end_time':     str(s.EndTime),
        'label':        f"{s.user.full_name if s.user else 'Unknown'} ({str(s.StartTime)[:5]}–{str(s.EndTime)[:5]})",
        'shift_period': _derive_shift_period(s.StartTime),
    } for s in shifts])

@sales_bp.route('/users')
def get_users():
    users = User.query.filter(User.status == 'Active').order_by(User.full_name).all()
    return jsonify([{
        'id':        u.user_id,
        'full_name': u.full_name,
        'emp_no':    u.emp_no or '',
    } for u in users])


# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────

def _parse_date(val):
    if not val:
        return None
    if isinstance(val, date):
        return val
    return datetime.strptime(val, '%Y-%m-%d').date()

def _calc_litres(d):
    if d.get('record_type') == 'transaction' or (not d.get('opening_meter') and not d.get('closing_meter')):
        try:
            return float(d.get('litres_sold', 0))
        except (TypeError, ValueError):
            return None
    try:
        diff = float(d['closing_meter']) - float(d['opening_meter'])
        return round(diff, 2) if diff > 0 else None
    except (TypeError, ValueError, KeyError):
        return None

def _derive_shift_period(start_time):
    try:
        h = start_time.hour
        if 5  <= h < 13: return 'Morning'
        if 13 <= h < 20: return 'Evening'
        return 'Night'
    except Exception:
        return 'Morning'