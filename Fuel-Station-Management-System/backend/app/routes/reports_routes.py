from flask import Blueprint, request, jsonify, render_template
from ..models.sales import DailySale, CreditSale, CreditPayment, CreditAccount, FuelDelivery
from ..models.expenses import Expense
from ..models.lubricants import Lubricant, LubricantSale, LubricantPurchase
from ..models.pumps import Pump, PumpMaintenance, PumpFault
from ..models.suppliers import Supplier, SupplierInvoice, SupplierPayment
from ..models.user import User
from ..models.shift import Shift
from ..models.inventory import FuelTank
from .. import db
from datetime import datetime, date, timedelta
from sqlalchemy import func, and_
from collections import defaultdict

reports_bp = Blueprint('reports', __name__, url_prefix='/reports')

# ─────────────────────────────────────────────
#  PAGE
# ─────────────────────────────────────────────

@reports_bp.route('/')
@reports_bp.route('/page')
def reports_page():
    return render_template('reports.html')

# ─────────────────────────────────────────────
#  DATE HELPERS
# ─────────────────────────────────────────────

def _parse(val):
    if not val: return None
    if isinstance(val, date): return val
    return datetime.strptime(val, '%Y-%m-%d').date()

def _default_range():
    today = date.today()
    return today - timedelta(days=29), today

def _get_range(req):
    s = _parse(req.args.get('start_date'))
    e = _parse(req.args.get('end_date'))
    if not s or not e:
        s, e = _default_range()
    return s, e

def _date_series(start, end):
    """Return list of date strings between start and end inclusive."""
    out, cur = [], start
    while cur <= end:
        out.append(str(cur))
        cur += timedelta(days=1)
    return out

# ─────────────────────────────────────────────
#  1. SALES & REVENUE
# ─────────────────────────────────────────────

@reports_bp.route('/sales')
def sales_report():
    start, end = _get_range(request)

    # Daily revenue (cash)
    daily_cash = db.session.query(
        DailySale.sale_date,
        func.sum(DailySale.total_amount).label('cash'),
        func.sum(DailySale.litres_sold).label('litres'),
        func.count(DailySale.sale_id).label('txns')
    ).filter(DailySale.sale_date.between(start, end)
    ).group_by(DailySale.sale_date).all()

    # Daily revenue (credit)
    daily_credit = db.session.query(
        CreditSale.sale_date,
        func.sum(CreditSale.total_amount).label('credit'),
        func.sum(CreditSale.litres_sold).label('litres')
    ).filter(CreditSale.sale_date.between(start, end)
    ).group_by(CreditSale.sale_date).all()

    cash_map   = {str(r.sale_date): {'cash': float(r.cash or 0), 'litres': float(r.litres or 0), 'txns': int(r.txns or 0)} for r in daily_cash}
    credit_map = {str(r.sale_date): {'credit': float(r.credit or 0), 'litres': float(r.litres or 0)} for r in daily_credit}
    dates      = _date_series(start, end)

    trend = []
    for d in dates:
        c  = cash_map.get(d,   {'cash': 0, 'litres': 0, 'txns': 0})
        cr = credit_map.get(d, {'credit': 0, 'litres': 0})
        trend.append({
            'date':    d,
            'cash':    c['cash'],
            'credit':  cr['credit'],
            'total':   c['cash'] + cr['credit'],
            'litres':  c['litres'] + cr['litres'],
            'txns':    c['txns'],
        })

    # Payment method breakdown
    pay_bkdn = db.session.query(
        DailySale.payment_method,
        func.sum(DailySale.total_amount).label('amount'),
        func.count(DailySale.sale_id).label('count')
    ).filter(DailySale.sale_date.between(start, end)
    ).group_by(DailySale.payment_method).all()

    # Fuel type breakdown (cash sales via pump)
    fuel_bkdn = db.session.query(
        Pump.FuelType,
        func.sum(DailySale.total_amount).label('revenue'),
        func.sum(DailySale.litres_sold).label('litres')
    ).join(Pump, DailySale.pump_id == Pump.PumpID
    ).filter(DailySale.sale_date.between(start, end)
    ).group_by(Pump.FuelType).all()

    # Fuel type from credit sales too
    credit_fuel = db.session.query(
        CreditSale.fuel_type,
        func.sum(CreditSale.total_amount).label('revenue'),
        func.sum(CreditSale.litres_sold).label('litres')
    ).filter(CreditSale.sale_date.between(start, end),
             CreditSale.fuel_type != None
    ).group_by(CreditSale.fuel_type).all()

    fuel_map = defaultdict(lambda: {'revenue': 0, 'litres': 0})
    for r in fuel_bkdn:
        fuel_map[r.FuelType]['revenue'] += float(r.revenue or 0)
        fuel_map[r.FuelType]['litres']  += float(r.litres or 0)
    for r in credit_fuel:
        if r.fuel_type:
            fuel_map[r.fuel_type]['revenue'] += float(r.revenue or 0)
            fuel_map[r.fuel_type]['litres']  += float(r.litres or 0)

    # Per-pump performance
    pump_perf = db.session.query(
        Pump.PumpNumber, Pump.PumpName, Pump.FuelType,
        func.sum(DailySale.total_amount).label('revenue'),
        func.sum(DailySale.litres_sold).label('litres'),
        func.count(DailySale.sale_id).label('txns')
    ).join(DailySale, DailySale.pump_id == Pump.PumpID
    ).filter(DailySale.sale_date.between(start, end)
    ).group_by(Pump.PumpID).all()

    # Shift period breakdown
    shift_bkdn = db.session.query(
        DailySale.shift_period,
        func.sum(DailySale.total_amount).label('revenue'),
        func.count(DailySale.sale_id).label('txns')
    ).filter(DailySale.sale_date.between(start, end)
    ).group_by(DailySale.shift_period).all()

    total_cash   = sum(r['cash']   for r in trend)
    total_credit = sum(r['credit'] for r in trend)
    total_litres = sum(r['litres'] for r in trend)

    return jsonify({
        'start_date': str(start),
        'end_date':   str(end),
        'trend':      trend,
        'totals': {
            'cash_revenue':   total_cash,
            'credit_revenue': total_credit,
            'total_revenue':  total_cash + total_credit,
            'total_litres':   total_litres,
            'avg_daily':      round((total_cash + total_credit) / max(len(dates), 1), 2),
        },
        'payment_breakdown': [{'method': r.payment_method, 'amount': float(r.amount or 0), 'count': int(r.count or 0)} for r in pay_bkdn],
        'fuel_breakdown':    [{'fuel_type': ft, 'revenue': v['revenue'], 'litres': v['litres']} for ft, v in fuel_map.items()],
        'pump_performance':  [{'pump_number': r.PumpNumber, 'pump_name': r.PumpName, 'fuel_type': r.FuelType, 'revenue': float(r.revenue or 0), 'litres': float(r.litres or 0), 'txns': int(r.txns or 0)} for r in pump_perf],
        'shift_breakdown':   [{'shift': r.shift_period, 'revenue': float(r.revenue or 0), 'txns': int(r.txns or 0)} for r in shift_bkdn],
    })


# ─────────────────────────────────────────────
#  2. INVENTORY / FUEL STOCK
# ─────────────────────────────────────────────

@reports_bp.route('/inventory')
def inventory_report():
    start, end = _get_range(request)

    tanks = FuelTank.query.order_by(FuelTank.tank_id).all()

    # Deliveries over period
    deliveries = db.session.query(
        FuelDelivery.fuel_type,
        FuelDelivery.delivery_date,
        func.sum(FuelDelivery.litres_delivered).label('litres'),
        func.sum(FuelDelivery.total_cost).label('cost')
    ).filter(FuelDelivery.delivery_date.between(start, end)
    ).group_by(FuelDelivery.fuel_type, FuelDelivery.delivery_date).all()

    # Consumption (cash + credit sales) per fuel type per day
    cash_consumption = db.session.query(
        Pump.FuelType,
        DailySale.sale_date,
        func.sum(DailySale.litres_sold).label('litres')
    ).join(Pump, DailySale.pump_id == Pump.PumpID
    ).filter(DailySale.sale_date.between(start, end)
    ).group_by(Pump.FuelType, DailySale.sale_date).all()

    credit_consumption = db.session.query(
        CreditSale.fuel_type,
        CreditSale.sale_date,
        func.sum(CreditSale.litres_sold).label('litres')
    ).filter(CreditSale.sale_date.between(start, end),
             CreditSale.fuel_type != None
    ).group_by(CreditSale.fuel_type, CreditSale.sale_date).all()

    # Aggregate deliveries by fuel type
    deliv_by_fuel = defaultdict(float)
    deliv_timeline = defaultdict(lambda: defaultdict(float))
    for r in deliveries:
        deliv_by_fuel[r.fuel_type] += float(r.litres or 0)
        deliv_timeline[str(r.delivery_date)][r.fuel_type] += float(r.litres or 0)

    # Aggregate consumption by fuel type
    cons_by_fuel = defaultdict(float)
    for r in cash_consumption:
        cons_by_fuel[r.FuelType] += float(r.litres or 0)
    for r in credit_consumption:
        if r.fuel_type:
            cons_by_fuel[r.fuel_type] += float(r.litres or 0)

    fuel_types = list(set(list(deliv_by_fuel.keys()) + list(cons_by_fuel.keys())))

    return jsonify({
        'start_date': str(start),
        'end_date':   str(end),
        'tanks': [t.to_dict() for t in tanks],
        'fuel_types': fuel_types,
        'delivery_vs_consumption': [{
            'fuel_type':   ft,
            'delivered':   round(deliv_by_fuel.get(ft, 0), 2),
            'consumed':    round(cons_by_fuel.get(ft, 0), 2),
            'net':         round(deliv_by_fuel.get(ft, 0) - cons_by_fuel.get(ft, 0), 2),
        } for ft in fuel_types],
        'delivery_timeline': [
            {'date': d, **deliv_timeline[d]} for d in sorted(deliv_timeline.keys())
        ],
    })


# ─────────────────────────────────────────────
#  3. CREDIT ACCOUNTS
# ─────────────────────────────────────────────

@reports_bp.route('/credit')
def credit_report():
    start, end = _get_range(request)

    accounts = CreditAccount.query.order_by(CreditAccount.account_name).all()

    # Monthly sales per account
    monthly_sales = db.session.query(
        CreditSale.account_id,
        func.date_trunc('month', CreditSale.sale_date).label('month'),
        func.sum(CreditSale.total_amount).label('amount')
    ).filter(CreditSale.sale_date.between(start, end)
    ).group_by(CreditSale.account_id, func.date_trunc('month', CreditSale.sale_date)
    ).all()

    # Monthly payments per account
    monthly_payments = db.session.query(
        CreditPayment.account_id,
        func.date_trunc('month', CreditPayment.payment_date).label('month'),
        func.sum(CreditPayment.amount).label('amount')
    ).filter(CreditPayment.payment_date.between(start, end)
    ).group_by(CreditPayment.account_id, func.date_trunc('month', CreditPayment.payment_date)
    ).all()

    # Outstanding per account
    account_summary = []
    total_outstanding = 0
    for a in accounts:
        period_sales = db.session.query(func.sum(CreditSale.total_amount)).filter(
            CreditSale.account_id == a.account_id,
            CreditSale.sale_date.between(start, end)
        ).scalar() or 0
        period_payments = db.session.query(func.sum(CreditPayment.amount)).filter(
            CreditPayment.account_id == a.account_id,
            CreditPayment.payment_date.between(start, end)
        ).scalar() or 0
        total_outstanding += float(a.outstanding_balance)
        account_summary.append({
            'id':                  a.account_id,
            'account_name':        a.account_name,
            'credit_limit':        float(a.credit_limit),
            'outstanding_balance': float(a.outstanding_balance),
            'utilisation_pct':     a.utilisation_pct,
            'period_sales':        float(period_sales),
            'period_payments':     float(period_payments),
            'status':              a.status,
        })

    # Payment trend (daily payments received)
    pay_trend = db.session.query(
        CreditPayment.payment_date,
        func.sum(CreditPayment.amount).label('amount')
    ).filter(CreditPayment.payment_date.between(start, end)
    ).group_by(CreditPayment.payment_date).order_by(CreditPayment.payment_date).all()

    # Sales trend (daily credit sales)
    sale_trend = db.session.query(
        CreditSale.sale_date,
        func.sum(CreditSale.total_amount).label('amount')
    ).filter(CreditSale.sale_date.between(start, end)
    ).group_by(CreditSale.sale_date).order_by(CreditSale.sale_date).all()

    return jsonify({
        'start_date':        str(start),
        'end_date':          str(end),
        'total_outstanding': total_outstanding,
        'account_summary':   account_summary,
        'payment_trend':     [{'date': str(r.payment_date), 'amount': float(r.amount or 0)} for r in pay_trend],
        'sale_trend':        [{'date': str(r.sale_date),    'amount': float(r.amount or 0)} for r in sale_trend],
    })


# ─────────────────────────────────────────────
#  4. STAFF & SHIFTS
# ─────────────────────────────────────────────

@reports_bp.route('/staff')
def staff_report():
    start, end = _get_range(request)

    # Sales per staff member
    staff_sales = db.session.query(
        DailySale.user_id,
        User.full_name,
        func.sum(DailySale.total_amount).label('revenue'),
        func.sum(DailySale.litres_sold).label('litres'),
        func.count(DailySale.sale_id).label('txns')
    ).join(User, DailySale.user_id == User.user_id
    ).filter(DailySale.sale_date.between(start, end)
    ).group_by(DailySale.user_id, User.full_name).all()

    # Shifts per staff (count)
    staff_shifts = db.session.query(
        Shift.UserID,
        User.full_name,
        func.count(Shift.ShiftID).label('shift_count')
    ).join(User, Shift.UserID == User.user_id
    ).filter(Shift.ShiftDate.between(start, end)
    ).group_by(Shift.UserID, User.full_name).all()

    # Role distribution (all active users)
    from ..models.role import Role
    role_dist = db.session.query(
        Role.RoleName,
        func.count(User.user_id).label('count')
    ).join(User, User.role_id == Role.RoleID
    ).filter(User.status == 'Active'
    ).group_by(Role.RoleName).all()

    # Status distribution
    status_dist = db.session.query(
        User.status,
        func.count(User.user_id).label('count')
    ).group_by(User.status).all()

    # Shifts by day of week
    shifts_dow = db.session.query(
        func.extract('dow', Shift.ShiftDate).label('dow'),
        func.count(Shift.ShiftID).label('count')
    ).filter(Shift.ShiftDate.between(start, end)
    ).group_by(func.extract('dow', Shift.ShiftDate)).all()

    dow_map = {int(r.dow): int(r.count) for r in shifts_dow}
    dow_labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    dow_data = [{'day': dow_labels[i], 'shifts': dow_map.get(i, 0)} for i in range(7)]

    shift_map = {r.UserID: int(r.shift_count) for r in staff_shifts}

    return jsonify({
        'start_date':    str(start),
        'end_date':      str(end),
        'staff_sales':   [{'user_id': r.user_id, 'name': r.full_name, 'revenue': float(r.revenue or 0), 'litres': float(r.litres or 0), 'txns': int(r.txns or 0)} for r in staff_sales],
        'staff_shifts':  [{'user_id': r.UserID, 'name': r.full_name, 'shift_count': int(r.shift_count)} for r in staff_shifts],
        'role_dist':     [{'role': r.RoleName, 'count': int(r.count)} for r in role_dist],
        'status_dist':   [{'status': r.status, 'count': int(r.count)} for r in status_dist],
        'shifts_by_dow': dow_data,
    })


# ─────────────────────────────────────────────
#  5. EXPENSES
# ─────────────────────────────────────────────

@reports_bp.route('/expenses')
def expenses_report():
    start, end = _get_range(request)

    expenses = Expense.query.filter(
        Expense.ExpenseDate.between(start, end)
    ).order_by(Expense.ExpenseDate).all()

    # By category
    cat_totals = defaultdict(float)
    for e in expenses:
        cat_totals[e.Category] += float(e.Amount)

    # By payment method
    pay_totals = defaultdict(float)
    for e in expenses:
        pay_totals[e.PaymentMethod] += float(e.Amount)

    # Daily trend
    daily = defaultdict(float)
    for e in expenses:
        daily[str(e.ExpenseDate)] += float(e.Amount)

    dates = _date_series(start, end)
    daily_trend = [{'date': d, 'amount': daily.get(d, 0)} for d in dates]

    # Monthly totals
    monthly = defaultdict(float)
    for e in expenses:
        key = e.ExpenseDate.strftime('%Y-%m')
        monthly[key] += float(e.Amount)

    total = sum(e.Amount for e in expenses)
    days_span = (end - start).days + 1

    return jsonify({
        'start_date':     str(start),
        'end_date':       str(end),
        'total':          round(total, 2),
        'avg_per_day':    round(total / max(days_span, 1), 2),
        'count':          len(expenses),
        'by_category':    [{'category': k, 'amount': round(v, 2)} for k, v in sorted(cat_totals.items(), key=lambda x: -x[1])],
        'by_payment':     [{'method': k, 'amount': round(v, 2)} for k, v in sorted(pay_totals.items(), key=lambda x: -x[1])],
        'daily_trend':    daily_trend,
        'monthly_totals': [{'month': k, 'amount': round(v, 2)} for k, v in sorted(monthly.items())],
    })


# ─────────────────────────────────────────────
#  6. LUBRICANTS
# ─────────────────────────────────────────────

@reports_bp.route('/lubricants')
def lubricants_report():
    start, end = _get_range(request)

    sales = LubricantSale.query.filter(
        LubricantSale.SaleDate.between(start, end)
    ).all()

    purchases = LubricantPurchase.query.filter(
        LubricantPurchase.PurchaseDate.between(start, end)
    ).all()

    # By product
    product_sales = defaultdict(lambda: {'revenue': 0, 'qty': 0, 'txns': 0, 'brand': '', 'category': ''})
    for s in sales:
        name = s.lubricant.Name if s.lubricant else 'Unknown'
        product_sales[name]['revenue'] += float(s.TotalAmount)
        product_sales[name]['qty']     += float(s.Quantity)
        product_sales[name]['txns']    += 1
        product_sales[name]['brand']    = s.lubricant.Brand if s.lubricant else ''
        product_sales[name]['category'] = s.lubricant.Category if s.lubricant else ''

    # By brand
    brand_sales = defaultdict(float)
    for s in sales:
        brand_sales[s.lubricant.Brand if s.lubricant else 'Unknown'] += float(s.TotalAmount)

    # By category
    cat_sales = defaultdict(float)
    for s in sales:
        cat_sales[s.lubricant.Category if s.lubricant else 'Unknown'] += float(s.TotalAmount)

    # Daily sales trend
    daily_sales_map = defaultdict(float)
    for s in sales:
        daily_sales_map[str(s.SaleDate)] += float(s.TotalAmount)

    dates = _date_series(start, end)
    sales_trend = [{'date': d, 'revenue': daily_sales_map.get(d, 0)} for d in dates]

    # Daily purchase trend
    daily_purch_map = defaultdict(float)
    for p in purchases:
        daily_purch_map[str(p.PurchaseDate)] += float(p.TotalCost)
    purchase_trend = [{'date': d, 'cost': daily_purch_map.get(d, 0)} for d in dates]

    # Low stock items
    all_products = Lubricant.query.all()
    low_stock = [p.to_dict() for p in all_products if p.StockQty <= p.LowStockThreshold]

    total_revenue = sum(s.TotalAmount for s in sales)
    total_cost    = sum(p.TotalCost   for p in purchases)

    return jsonify({
        'start_date':     str(start),
        'end_date':       str(end),
        'total_revenue':  round(total_revenue, 2),
        'total_cost':     round(total_cost, 2),
        'gross_profit':   round(total_revenue - total_cost, 2),
        'total_qty_sold': round(sum(s.Quantity for s in sales), 2),
        'sales_count':    len(sales),
        'top_products':   sorted([{'name': k, **v} for k, v in product_sales.items()], key=lambda x: -x['revenue'])[:10],
        'by_brand':       [{'brand': k, 'revenue': round(v, 2)} for k, v in sorted(brand_sales.items(), key=lambda x: -x[1])],
        'by_category':    [{'category': k, 'revenue': round(v, 2)} for k, v in sorted(cat_sales.items(), key=lambda x: -x[1])],
        'sales_trend':    sales_trend,
        'purchase_trend': purchase_trend,
        'low_stock':      low_stock,
        'stock_overview': [{'name': p.Name, 'brand': p.Brand, 'stock': p.StockQty, 'threshold': p.LowStockThreshold, 'is_low': p.StockQty <= p.LowStockThreshold} for p in all_products],
    })


# ─────────────────────────────────────────────
#  7. SUPPLIERS
# ─────────────────────────────────────────────

@reports_bp.route('/suppliers')
def suppliers_report():
    start, end = _get_range(request)

    invoices = SupplierInvoice.query.filter(
        SupplierInvoice.InvoiceDate.between(start, end)
    ).all()

    payments = SupplierPayment.query.filter(
        SupplierPayment.PaymentDate.between(start, end)
    ).all()

    all_suppliers = Supplier.query.filter_by(IsActive=True).all()

    # Per supplier
    sup_map = defaultdict(lambda: {'invoiced': 0, 'paid': 0, 'name': '', 'type': ''})
    for i in invoices:
        s = i.supplier
        if s:
            sup_map[s.SupplierID]['invoiced'] += float(i.Amount)
            sup_map[s.SupplierID]['name']      = s.Name
            sup_map[s.SupplierID]['type']      = s.Type
    for p in payments:
        s = p.supplier
        if s:
            sup_map[s.SupplierID]['paid'] += float(p.Amount)

    # Invoice status breakdown
    status_map = defaultdict(lambda: {'count': 0, 'amount': 0})
    for i in invoices:
        status_map[i.Status]['count']  += 1
        status_map[i.Status]['amount'] += float(i.Amount)

    # By category
    cat_map = defaultdict(float)
    for i in invoices:
        cat_map[i.Category] += float(i.Amount)

    # Overdue
    today = date.today()
    overdue = [i.to_dict() for i in SupplierInvoice.query.filter(
        SupplierInvoice.Status != 'Paid',
        SupplierInvoice.DueDate < today
    ).all()]

    # Payment timeline
    pay_timeline = defaultdict(float)
    for p in payments:
        pay_timeline[str(p.PaymentDate)] += float(p.Amount)

    inv_timeline = defaultdict(float)
    for i in invoices:
        inv_timeline[str(i.InvoiceDate)] += float(i.Amount)

    dates = _date_series(start, end)

    # Supplier type distribution
    type_dist = defaultdict(int)
    for s in all_suppliers:
        type_dist[s.Type] += 1

    return jsonify({
        'start_date':    str(start),
        'end_date':      str(end),
        'total_invoiced': round(sum(float(i.Amount) for i in invoices), 2),
        'total_paid':     round(sum(float(p.Amount) for p in payments), 2),
        'overdue_count':  len(overdue),
        'overdue_amount': round(sum(float(i['amount']) for i in overdue), 2),
        'by_supplier':   sorted([{'id': k, **v, 'balance': round(v['invoiced'] - v['paid'], 2)} for k, v in sup_map.items()], key=lambda x: -x['invoiced'])[:10],
        'by_status':     [{'status': k, 'count': v['count'], 'amount': round(v['amount'], 2)} for k, v in status_map.items()],
        'by_category':   [{'category': k, 'amount': round(v, 2)} for k, v in sorted(cat_map.items(), key=lambda x: -x[1])],
        'type_dist':     [{'type': k, 'count': v} for k, v in type_dist.items()],
        'pay_timeline':  [{'date': d, 'amount': pay_timeline.get(d, 0)} for d in dates],
        'inv_timeline':  [{'date': d, 'amount': inv_timeline.get(d, 0)} for d in dates],
        'overdue':       overdue,
    })


# ─────────────────────────────────────────────
#  8. PUMP ANALYTICS
# ─────────────────────────────────────────────

@reports_bp.route('/pumps')
def pumps_report():
    start, end = _get_range(request)

    pumps = Pump.query.all()

    # Faults in period
    faults = PumpFault.query.filter(
        PumpFault.FaultDate.between(start, end)
    ).all()

    # Maintenance in period
    maintenances = PumpMaintenance.query.filter(
        PumpMaintenance.MaintenanceDate.between(start, end)
    ).all()

    # Faults by severity
    sev_map = defaultdict(int)
    for f in faults:
        sev_map[f.Severity] += 1

    # Faults by status
    status_map = defaultdict(int)
    for f in faults:
        status_map[f.Status] += 1

    # Per pump fault count
    pump_fault_map = defaultdict(int)
    for f in faults:
        pump_fault_map[f.PumpID] += 1

    # Per pump maintenance cost
    pump_maint_cost = defaultdict(float)
    for m in maintenances:
        pump_maint_cost[m.PumpID] += float(m.Cost or 0)

    # Fault timeline (daily count)
    fault_daily = defaultdict(int)
    for f in faults:
        fault_daily[str(f.FaultDate)] += 1

    dates = _date_series(start, end)
    fault_timeline = [{'date': d, 'count': fault_daily.get(d, 0)} for d in dates]

    # Maintenance cost timeline (daily)
    maint_daily = defaultdict(float)
    for m in maintenances:
        maint_daily[str(m.MaintenanceDate)] += float(m.Cost or 0)
    maint_timeline = [{'date': d, 'cost': maint_daily.get(d, 0)} for d in dates]

    pump_summary = []
    for p in pumps:
        pump_summary.append({
            'pump_id':      p.PumpID,
            'pump_number':  p.PumpNumber,
            'pump_name':    p.PumpName,
            'fuel_type':    p.FuelType,
            'status':       p.Status,
            'total_dispensed': float(p.TotalDispensedL or 0),
            'fault_count':  pump_fault_map.get(p.PumpID, 0),
            'maint_cost':   round(pump_maint_cost.get(p.PumpID, 0), 2),
            'alert':        p.maintenance_alert(),
        })

    # Status distribution
    status_dist = defaultdict(int)
    for p in pumps:
        status_dist[p.Status] += 1

    return jsonify({
        'start_date':      str(start),
        'end_date':        str(end),
        'total_faults':    len(faults),
        'total_maint':     len(maintenances),
        'total_maint_cost': round(sum(float(m.Cost or 0) for m in maintenances), 2),
        'open_faults':     sum(1 for f in faults if f.Status != 'Resolved'),
        'by_severity':     [{'severity': k, 'count': v} for k, v in sev_map.items()],
        'by_fault_status': [{'status': k, 'count': v} for k, v in status_map.items()],
        'pump_status_dist':[{'status': k, 'count': v} for k, v in status_dist.items()],
        'pump_summary':    pump_summary,
        'fault_timeline':  fault_timeline,
        'maint_timeline':  maint_timeline,
    })


# ─────────────────────────────────────────────
#  OVERVIEW — all sections summary for top KPIs
# ─────────────────────────────────────────────

@reports_bp.route('/overview')
def overview():
    start, end = _get_range(request)
    today = date.today()

    total_revenue = (
        (db.session.query(func.sum(DailySale.total_amount)).filter(DailySale.sale_date.between(start, end)).scalar() or 0) +
        (db.session.query(func.sum(CreditSale.total_amount)).filter(CreditSale.sale_date.between(start, end)).scalar() or 0)
    )
    total_litres = (
        (db.session.query(func.sum(DailySale.litres_sold)).filter(DailySale.sale_date.between(start, end)).scalar() or 0) +
        (db.session.query(func.sum(CreditSale.litres_sold)).filter(CreditSale.sale_date.between(start, end)).scalar() or 0)
    )
    total_expenses    = db.session.query(func.sum(Expense.Amount)).filter(Expense.ExpenseDate.between(start, end)).scalar() or 0
    lub_revenue       = db.session.query(func.sum(LubricantSale.TotalAmount)).filter(LubricantSale.SaleDate.between(start, end)).scalar() or 0
    total_outstanding = db.session.query(func.sum(CreditAccount.outstanding_balance)).filter(CreditAccount.status == 'Active').scalar() or 0
    open_faults       = PumpFault.query.filter(PumpFault.Status != 'Resolved').count()
    low_stock_tanks   = FuelTank.query.filter(FuelTank.current_stock_l <= FuelTank.low_stock_threshold_l).count()
    active_staff      = User.query.filter(User.status == 'Active').count()
    overdue_invoices  = SupplierInvoice.query.filter(SupplierInvoice.Status != 'Paid', SupplierInvoice.DueDate < today).count()

    net_profit = float(total_revenue) + float(lub_revenue) - float(total_expenses)

    return jsonify({
        'start_date':        str(start),
        'end_date':          str(end),
        'total_revenue':     float(total_revenue),
        'total_litres':      float(total_litres),
        'lub_revenue':       float(lub_revenue),
        'total_expenses':    float(total_expenses),
        'net_profit':        round(net_profit, 2),
        'total_outstanding': float(total_outstanding),
        'open_faults':       open_faults,
        'low_stock_tanks':   low_stock_tanks,
        'active_staff':      active_staff,
        'overdue_invoices':  overdue_invoices,
    })