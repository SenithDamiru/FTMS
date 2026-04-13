from flask import Blueprint, render_template, jsonify, request, session
from ..models.sales import DailySale, CreditSale, CreditPayment, CreditAccount, FuelDelivery
from ..models.expenses import Expense
from ..models.lubricants import Lubricant, LubricantSale
from ..models.pumps import Pump, PumpFault, PumpMaintenance
from ..models.suppliers import SupplierInvoice
from ..models.user import User
from ..models.shift import Shift
from ..models.inventory import FuelTank
from .. import db
from datetime import datetime, date, timedelta
from sqlalchemy import func

dashboard_bp = Blueprint('dashboard', __name__, url_prefix='/dashboard')

# ─────────────────────────────────────────────
#  PAGE
# ─────────────────────────────────────────────

@dashboard_bp.route('/')
@dashboard_bp.route('')
def dashboard_page():
    return render_template('index.html')


# ─────────────────────────────────────────────
#  MAIN SUMMARY  — single endpoint for all KPIs
# ─────────────────────────────────────────────

@dashboard_bp.route('/summary')
def summary():
    today = date.today()
    now   = datetime.now()

    # ── Today's cash sales ──
    today_cash = db.session.query(
        func.sum(DailySale.total_amount).label('revenue'),
        func.sum(DailySale.litres_sold).label('litres'),
        func.count(DailySale.sale_id).label('txns')
    ).filter(DailySale.sale_date == today).first()

    # ── Today's credit sales ──
    today_credit = db.session.query(
        func.sum(CreditSale.total_amount).label('revenue'),
        func.sum(CreditSale.litres_sold).label('litres')
    ).filter(CreditSale.sale_date == today).first()

    today_revenue = float((today_cash.revenue or 0)) + float((today_credit.revenue or 0))
    today_litres  = float((today_cash.litres  or 0)) + float((today_credit.litres  or 0))

    # ── This month revenue ──
    month_start = today.replace(day=1)
    month_rev = (
        (db.session.query(func.sum(DailySale.total_amount))
         .filter(DailySale.sale_date >= month_start).scalar() or 0) +
        (db.session.query(func.sum(CreditSale.total_amount))
         .filter(CreditSale.sale_date >= month_start).scalar() or 0)
    )

    # ── Credit outstanding ──
    total_outstanding = db.session.query(
        func.sum(CreditAccount.outstanding_balance)
    ).filter(CreditAccount.status == 'Active').scalar() or 0

    # ── Pump status counts ──
    pumps = Pump.query.all()
    pump_active = sum(1 for p in pumps if p.Status == 'Active')
    pump_inactive = sum(1 for p in pumps if p.Status == 'Inactive')
    pump_maint = sum(1 for p in pumps if p.Status == 'Under Maintenance')
    open_faults = PumpFault.query.filter(PumpFault.Status != 'Resolved').count()

          # ── Staff on shift now (handles midnight-crossing shifts) ──
    current_time = now.time()
    all_shifts = db.session.query(Shift).join(
        User, Shift.UserID == User.user_id
    ).filter(
        Shift.ShiftDate == today,
        User.status == 'Active'
    ).all()
    
    # Filter shifts that are currently active (handling midnight-crossing)
    staff_on_duty = 0
    for shift in all_shifts:
        if shift.StartTime <= shift.EndTime:  # Normal shift (same day)
            if shift.StartTime <= current_time <= shift.EndTime:
                staff_on_duty += 1
        else:  # Midnight-crossing shift
            if current_time >= shift.StartTime or current_time <= shift.EndTime:
                staff_on_duty += 1

    # ── Today's expense total ──
    today_expenses = db.session.query(func.sum(Expense.Amount)
    ).filter(Expense.ExpenseDate == today).scalar() or 0

    return jsonify({
        'today_revenue':     round(float(today_revenue), 2),
        'today_litres':      round(float(today_litres), 2),
        'today_cash':        round(float(today_cash.revenue or 0), 2),
        'today_credit':      round(float(today_credit.revenue or 0), 2),
        'today_txns':        int(today_cash.txns or 0),
        'month_revenue':     round(float(month_rev), 2),
        'total_outstanding': round(float(total_outstanding), 2),
        'pump_active':       pump_active,
        'pump_inactive':     pump_inactive,
        'pump_maint':        pump_maint,
        'open_faults':       open_faults,
        'staff_on_duty':     staff_on_duty,
        'today_expenses':    round(float(today_expenses), 2),
        'total_pumps':       len(pumps),
    })


# ─────────────────────────────────────────────
#  7-DAY REVENUE TREND
# ─────────────────────────────────────────────

@dashboard_bp.route('/trend')
def trend():
    today = date.today()
    rows  = []
    for i in range(6, -1, -1):
        d = today - timedelta(days=i)
        cash = db.session.query(func.sum(DailySale.total_amount)
               ).filter(DailySale.sale_date == d).scalar() or 0
        cred = db.session.query(func.sum(CreditSale.total_amount)
               ).filter(CreditSale.sale_date == d).scalar() or 0
        litres = (
            (db.session.query(func.sum(DailySale.litres_sold)).filter(DailySale.sale_date == d).scalar() or 0) +
            (db.session.query(func.sum(CreditSale.litres_sold)).filter(CreditSale.sale_date == d).scalar() or 0)
        )
        rows.append({
            'date':   str(d),
            'label':  d.strftime('%a'),   # Mon, Tue …
            'cash':   round(float(cash), 2),
            'credit': round(float(cred), 2),
            'total':  round(float(cash) + float(cred), 2),
            'litres': round(float(litres), 2),
        })
    return jsonify(rows)


# ─────────────────────────────────────────────
#  PUMP STATUS LIST
# ─────────────────────────────────────────────

@dashboard_bp.route('/pumps')
def pumps_status():
    pumps = Pump.query.order_by(Pump.PumpNumber).all()
    today = date.today()
    result = []
    for p in pumps:
        # Litres dispensed today via daily sales
        today_l = db.session.query(func.sum(DailySale.litres_sold)
                  ).filter(DailySale.pump_id == p.PumpID,
                           DailySale.sale_date == today).scalar() or 0
        today_l += db.session.query(func.sum(CreditSale.litres_sold)
                   ).filter(CreditSale.pump_id == p.PumpID,
                            CreditSale.sale_date == today).scalar() or 0
        open_f = PumpFault.query.filter(
            PumpFault.PumpID == p.PumpID,
            PumpFault.Status != 'Resolved'
        ).count()
        result.append({
            'id':           p.PumpID,
            'pump_number':  p.PumpNumber,
            'pump_name':    p.PumpName,
            'fuel_type':    p.FuelType,
            'status':       p.Status,
            'today_litres': round(float(today_l), 2),
            'total_dispensed': round(float(p.TotalDispensedL or 0), 2),
            'open_faults':  open_f,
            'alert':        p.maintenance_alert(),
        })
    return jsonify(result)


# ─────────────────────────────────────────────
#  TODAY'S SHIFTS  (all + currently active)
# ─────────────────────────────────────────────

@dashboard_bp.route('/shifts')
def shifts_today():
    today = date.today()
    now   = datetime.now().time()

    shifts = Shift.query.filter(Shift.ShiftDate == today
             ).order_by(Shift.StartTime).all()

    result = []
    for s in shifts:
        is_active = s.StartTime <= now <= s.EndTime
        result.append({
            'id':        s.ShiftID,
            'user_name': s.user.full_name if s.user else '—',
            'role':      s.role.RoleName  if s.role  else '—',
            'start':     s.StartTime.strftime('%H:%M'),
            'end':       s.EndTime.strftime('%H:%M'),
            'is_active': is_active,
            'emp_no':    s.user.emp_no if s.user else '',
            'profile_image': s.user.profile_image if s.user else '',
        })
    return jsonify(result)


# ─────────────────────────────────────────────
#  ALERTS  — aggregated from all modules
# ─────────────────────────────────────────────

@dashboard_bp.route('/alerts')
def alerts():
    today   = date.today()
    now     = datetime.now()
    items   = []

    # 1. Low fuel tank stock
    tanks = FuelTank.query.all()
    for t in tanks:
        if t.is_low:
            pct = t.stock_pct
            items.append({
                'type':     'tank',
                'severity': 'critical' if pct <= 10 else 'warning',
                'icon':     'fa-gas-pump',
                'title':    f'Low Fuel — {t.fuel_type}',
                'message':  f'Tank {t.tank_id}: {round(t.current_stock_l)}L remaining ({pct}%)',
                'link':     '/inventory/page',
            })

    # 2. Open pump faults
    faults = PumpFault.query.filter(PumpFault.Status != 'Resolved'
             ).order_by(PumpFault.FaultDate.desc()).all()
    for f in faults:
        sev_map = {'Critical': 'critical', 'High': 'critical', 'Medium': 'warning', 'Low': 'info'}
        items.append({
            'type':     'fault',
            'severity': sev_map.get(f.Severity, 'warning'),
            'icon':     'fa-triangle-exclamation',
            'title':    f'Pump Fault — {f.pump.PumpNumber if f.pump else ""}',
            'message':  f'{f.Description[:60]}{"…" if len(f.Description) > 60 else ""}',
            'link':     '/pumps/page',
        })

    # 3. Overdue supplier invoices
    overdue = SupplierInvoice.query.filter(
        SupplierInvoice.Status != 'Paid',
        SupplierInvoice.DueDate < today
    ).order_by(SupplierInvoice.DueDate).all()
    for inv in overdue:
        days_over = (today - inv.DueDate).days
        items.append({
            'type':     'invoice',
            'severity': 'critical' if days_over > 14 else 'warning',
            'icon':     'fa-file-invoice',
            'title':    f'Overdue Invoice — {inv.InvoiceRef}',
            'message':  f'{inv.supplier.Name if inv.supplier else ""} · Rs.{inv.Amount:,.0f} · {days_over}d overdue',
            'link':     '/suppliers/page',
        })

    # 4. Credit accounts near limit (>80% utilised)
    accounts = CreditAccount.query.filter(CreditAccount.status == 'Active').all()
    for a in accounts:
        if a.utilisation_pct >= 80:
            items.append({
                'type':     'credit',
                'severity': 'critical' if a.utilisation_pct >= 95 else 'warning',
                'icon':     'fa-building-columns',
                'title':    f'Credit Limit — {a.account_name}',
                'message':  f'{a.utilisation_pct}% utilised · Rs.{float(a.outstanding_balance):,.0f} outstanding',
                'link':     '/sales/page',
            })

    # 5. Staff shifts ending within 30 minutes
    soon = (datetime.combine(today, datetime.now().time()) + timedelta(minutes=30)).time()
    ending = Shift.query.filter(
        Shift.ShiftDate == today,
        Shift.EndTime   >= now.time(),
        Shift.EndTime   <= soon
    ).all()
    for s in ending:
        items.append({
            'type':     'shift',
            'severity': 'info',
            'icon':     'fa-clock',
            'title':    f'Shift Ending — {s.user.full_name if s.user else ""}',
            'message':  f'Shift ends at {s.EndTime.strftime("%H:%M")} · {s.role.RoleName if s.role else ""}',
            'link':     '/shifts/page',
        })

    # 6. Low lubricant stock
    low_lub = Lubricant.query.filter(
        Lubricant.StockQty <= Lubricant.LowStockThreshold
    ).all()
    for l in low_lub:
        items.append({
            'type':     'lubricant',
            'severity': 'warning' if l.StockQty > 0 else 'critical',
            'icon':     'fa-spray-can-sparkles',
            'title':    f'Low Lubricant Stock — {l.Name}',
            'message':  f'{l.Brand} · {l.StockQty} {l.UnitType} remaining',
            'link':     '/lubricants/page',
        })

    # Sort: critical first, then warning, then info
    order = {'critical': 0, 'warning': 1, 'info': 2}
    items.sort(key=lambda x: order.get(x['severity'], 3))

    return jsonify({'alerts': items, 'count': len(items)})


# ─────────────────────────────────────────────
#  RECENT TRANSACTIONS  (last 12, mixed cash + credit)
# ─────────────────────────────────────────────

@dashboard_bp.route('/recent')
def recent_transactions():
    today = date.today()

    cash_sales = DailySale.query.filter(
        DailySale.sale_date == today
    ).order_by(DailySale.created_at.desc()).limit(8).all()

    credit_sales = CreditSale.query.filter(
        CreditSale.sale_date == today
    ).order_by(CreditSale.created_at.desc()).limit(6).all()

    txns = []
    for s in cash_sales:
        txns.append({
            'type':        'cash',
            'time':        s.created_at.strftime('%H:%M') if s.created_at else '—',
            'pump':        s.pump.PumpNumber if s.pump else '—',
            'fuel_type':   s.pump.FuelType   if s.pump else '—',
            'litres':      round(float(s.litres_sold), 1),
            'amount':      round(float(s.total_amount), 2),
            'payment':     s.payment_method,
            'recorded_by': s.user.full_name if s.user else '—',
            'sort_key':    str(s.created_at),
        })
    for s in credit_sales:
        txns.append({
            'type':        'credit',
            'time':        s.created_at.strftime('%H:%M') if s.created_at else '—',
            'pump':        s.pump.PumpNumber if s.pump else '—',
            'fuel_type':   s.fuel_type or '—',
            'litres':      round(float(s.litres_sold), 1),
            'amount':      round(float(s.total_amount), 2),
            'payment':     'Credit',
            'account':     s.account.account_name if s.account else '—',
            'vehicle':     s.vehicle_number or '—',
            'sort_key':    str(s.created_at),
        })

    txns.sort(key=lambda x: x['sort_key'], reverse=True)
    return jsonify(txns[:12])


# ─────────────────────────────────────────────
#  FUEL TYPE BREAKDOWN  (today)
# ─────────────────────────────────────────────

@dashboard_bp.route('/fuel-breakdown')
def fuel_breakdown():
    today = date.today()
    FUEL_TYPES = ['92 Octane', '95 Octane', 'Auto Diesel', 'Super Diesel']
    result = []
    for ft in FUEL_TYPES:
        cash_l = db.session.query(func.sum(DailySale.litres_sold)).join(
            Pump, DailySale.pump_id == Pump.PumpID
        ).filter(DailySale.sale_date == today, Pump.FuelType == ft).scalar() or 0
        cash_r = db.session.query(func.sum(DailySale.total_amount)).join(
            Pump, DailySale.pump_id == Pump.PumpID
        ).filter(DailySale.sale_date == today, Pump.FuelType == ft).scalar() or 0
        cred_l = db.session.query(func.sum(CreditSale.litres_sold)
                 ).filter(CreditSale.sale_date == today, CreditSale.fuel_type == ft).scalar() or 0
        cred_r = db.session.query(func.sum(CreditSale.total_amount)
                 ).filter(CreditSale.sale_date == today, CreditSale.fuel_type == ft).scalar() or 0
        result.append({
            'fuel_type': ft,
            'litres':    round(float(cash_l) + float(cred_l), 2),
            'revenue':   round(float(cash_r) + float(cred_r), 2),
        })
    return jsonify([r for r in result if r['litres'] > 0 or r['revenue'] > 0])


# ─────────────────────────────────────────────
#  STATION INFO
# ─────────────────────────────────────────────

@dashboard_bp.route('/station')
def station_info():
    try:
        from ..models.settings import StationSettings
        s = StationSettings.query.get(1)
        if s:
            return jsonify({
                'name':    s.name,
                'address': s.address or '',
                'phone':   s.phone   or '',
                'email':   s.email   or '',
                'logo':    s.logo_path or '',
            })
    except Exception:
        pass
    return jsonify({
        'name':    'BKS Damiru Filling Station',
        'address': 'Pore, Athurugiriya',
        'phone':   '',
        'email':   '',
        'logo':    '',
    })