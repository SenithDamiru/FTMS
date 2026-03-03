from flask import Blueprint, request, jsonify, render_template
from ..models.suppliers import Supplier, SupplierInvoice, SupplierPayment, InvoicePaymentLink
from .. import db
from datetime import datetime, date
from collections import defaultdict

suppliers_bp = Blueprint('suppliers', __name__, url_prefix='/suppliers')


# ─────────────────────────────────────────────
#  PAGE
# ─────────────────────────────────────────────

@suppliers_bp.route('/page', methods=['GET'])
def suppliers_page():
    return render_template('suppliers.html')


# ─────────────────────────────────────────────
#  SUPPLIER DIRECTORY  CRUD
# ─────────────────────────────────────────────

@suppliers_bp.route('/', methods=['GET'])
def get_suppliers():
    sup_type  = request.args.get('type')
    is_active = request.args.get('active')
    query     = Supplier.query
    if sup_type:
        query = query.filter(Supplier.Type == sup_type)
    if is_active is not None:
        query = query.filter(Supplier.IsActive == (is_active.lower() == 'true'))
    suppliers = query.order_by(Supplier.Name).all()
    return jsonify([s.to_dict() for s in suppliers])


@suppliers_bp.route('/<int:id>', methods=['GET'])
def get_supplier(id):
    s = Supplier.query.get_or_404(id)
    return jsonify(s.to_dict())


@suppliers_bp.route('/add', methods=['POST'])
def add_supplier():
    d = request.json
    s = Supplier(
        Name          = d['name'],
        Type          = d['type'],
        ContactPerson = d.get('contact_person', ''),
        Phone         = d.get('phone', ''),
        Email         = d.get('email', ''),
        Address       = d.get('address', ''),
        TaxID         = d.get('tax_id', ''),
        BankDetails   = d.get('bank_details', ''),
        CreditDays    = int(d.get('credit_days', 30)),
        Notes         = d.get('notes', ''),
        IsActive      = True,
    )
    db.session.add(s)
    db.session.commit()
    return jsonify({"message": "Supplier added", "id": s.SupplierID}), 201


@suppliers_bp.route('/update/<int:id>', methods=['PUT'])
def update_supplier(id):
    s = Supplier.query.get_or_404(id)
    d = request.json
    s.Name           = d['name']
    s.Type           = d['type']
    s.ContactPerson  = d.get('contact_person', '')
    s.Phone          = d.get('phone', '')
    s.Email          = d.get('email', '')
    s.Address        = d.get('address', '')
    s.TaxID          = d.get('tax_id', '')
    s.BankDetails    = d.get('bank_details', '')
    s.CreditDays     = int(d.get('credit_days', 30))
    s.Notes          = d.get('notes', '')
    s.IsActive       = bool(d.get('is_active', True))
    db.session.commit()
    return jsonify({"message": "Supplier updated"})


@suppliers_bp.route('/delete/<int:id>', methods=['DELETE'])
def delete_supplier(id):
    s = Supplier.query.get_or_404(id)
    db.session.delete(s)
    db.session.commit()
    return jsonify({"message": "Supplier deleted"})


@suppliers_bp.route('/toggle-active/<int:id>', methods=['PATCH'])
def toggle_active(id):
    s = Supplier.query.get_or_404(id)
    s.IsActive = not s.IsActive
    db.session.commit()
    return jsonify({"message": "Status updated", "is_active": s.IsActive})


# ─────────────────────────────────────────────
#  INVOICES  CRUD
# ─────────────────────────────────────────────

@suppliers_bp.route('/invoices', methods=['GET'])
def get_invoices():
    supplier_id = request.args.get('supplier_id')
    status      = request.args.get('status')
    start_date  = request.args.get('start_date')
    end_date    = request.args.get('end_date')

    query = SupplierInvoice.query
    if supplier_id:
        query = query.filter(SupplierInvoice.SupplierID == int(supplier_id))
    if status:
        query = query.filter(SupplierInvoice.Status == status)
    if start_date:
        query = query.filter(SupplierInvoice.InvoiceDate >= start_date)
    if end_date:
        query = query.filter(SupplierInvoice.InvoiceDate <= end_date)

    invoices = query.order_by(SupplierInvoice.InvoiceDate.desc()).all()
    return jsonify([i.to_dict() for i in invoices])


@suppliers_bp.route('/invoices/add', methods=['POST'])
def add_invoice():
    d = request.json
    inv = SupplierInvoice(
        SupplierID  = int(d['supplier_id']),
        InvoiceRef  = d['invoice_ref'],
        Category    = d['category'],
        Description = d.get('description', ''),
        Amount      = float(d['amount']),
        InvoiceDate = datetime.strptime(d['invoice_date'], '%Y-%m-%d').date(),
        DueDate     = datetime.strptime(d['due_date'], '%Y-%m-%d').date() if d.get('due_date') else None,
        Status      = 'Unpaid',
    )
    db.session.add(inv)
    db.session.commit()
    return jsonify({"message": "Invoice added", "id": inv.InvoiceID}), 201


@suppliers_bp.route('/invoices/update/<int:id>', methods=['PUT'])
def update_invoice(id):
    inv = SupplierInvoice.query.get_or_404(id)
    d   = request.json
    inv.SupplierID  = int(d['supplier_id'])
    inv.InvoiceRef  = d['invoice_ref']
    inv.Category    = d['category']
    inv.Description = d.get('description', '')
    inv.Amount      = float(d['amount'])
    inv.InvoiceDate = datetime.strptime(d['invoice_date'], '%Y-%m-%d').date()
    inv.DueDate     = datetime.strptime(d['due_date'], '%Y-%m-%d').date() if d.get('due_date') else None
    _recalc_invoice_status(inv)
    db.session.commit()
    return jsonify({"message": "Invoice updated"})


@suppliers_bp.route('/invoices/delete/<int:id>', methods=['DELETE'])
def delete_invoice(id):
    inv = SupplierInvoice.query.get_or_404(id)
    db.session.delete(inv)
    db.session.commit()
    return jsonify({"message": "Invoice deleted"})


# ─────────────────────────────────────────────
#  PAYMENTS  CRUD
# ─────────────────────────────────────────────

@suppliers_bp.route('/payments', methods=['GET'])
def get_payments():
    supplier_id = request.args.get('supplier_id')
    start_date  = request.args.get('start_date')
    end_date    = request.args.get('end_date')

    query = SupplierPayment.query
    if supplier_id:
        query = query.filter(SupplierPayment.SupplierID == int(supplier_id))
    if start_date:
        query = query.filter(SupplierPayment.PaymentDate >= start_date)
    if end_date:
        query = query.filter(SupplierPayment.PaymentDate <= end_date)

    payments = query.order_by(SupplierPayment.PaymentDate.desc()).all()
    return jsonify([p.to_dict() for p in payments])


@suppliers_bp.route('/payments/add', methods=['POST'])
def add_payment():
    """
    Body:
      supplier_id, amount, payment_method, reference, notes, date,
      invoice_allocations: [ {invoice_id, allocated_amount}, … ]   (optional)
    """
    d           = request.json
    supplier_id = int(d['supplier_id'])
    amount      = float(d['amount'])

    payment = SupplierPayment(
        SupplierID    = supplier_id,
        Amount        = amount,
        PaymentMethod = d['payment_method'],
        Reference     = d.get('reference', ''),
        Notes         = d.get('notes', ''),
        PaymentDate   = datetime.strptime(d['date'], '%Y-%m-%d').date(),
    )
    db.session.add(payment)
    db.session.flush()   # get PaymentID before linking

    # allocate to invoices
    allocations = d.get('invoice_allocations', [])
    for alloc in allocations:
        inv = SupplierInvoice.query.get(int(alloc['invoice_id']))
        if not inv:
            continue
        link = InvoicePaymentLink(
            InvoiceID       = inv.InvoiceID,
            PaymentID       = payment.PaymentID,
            AllocatedAmount = float(alloc['allocated_amount']),
        )
        db.session.add(link)
        db.session.flush()
        _recalc_invoice_status(inv)

    db.session.commit()
    return jsonify({"message": "Payment recorded", "id": payment.PaymentID}), 201


@suppliers_bp.route('/payments/delete/<int:id>', methods=['DELETE'])
def delete_payment(id):
    payment = SupplierPayment.query.get_or_404(id)
    # collect linked invoices before cascade-delete
    linked_invs = [lnk.invoice for lnk in payment.invoice_links if lnk.invoice]
    db.session.delete(payment)
    db.session.flush()
    for inv in linked_invs:
        _recalc_invoice_status(inv)
    db.session.commit()
    return jsonify({"message": "Payment deleted"})


# ─────────────────────────────────────────────
#  SUPPLIER LEDGER  (all transactions for one supplier)
# ─────────────────────────────────────────────

@suppliers_bp.route('/<int:id>/ledger', methods=['GET'])
def get_ledger(id):
    s        = Supplier.query.get_or_404(id)
    invoices = SupplierInvoice.query.filter_by(SupplierID=id).order_by(SupplierInvoice.InvoiceDate).all()
    payments = SupplierPayment.query.filter_by(SupplierID=id).order_by(SupplierPayment.PaymentDate).all()

    total_invoiced = sum(i.Amount for i in invoices)
    total_paid     = sum(p.Amount for p in payments)

    return jsonify({
        "supplier":       s.to_dict(),
        "invoices":       [i.to_dict() for i in invoices],
        "payments":       [p.to_dict() for p in payments],
        "total_invoiced": total_invoiced,
        "total_paid":     total_paid,
        "balance_due":    total_invoiced - total_paid,
    })


# ─────────────────────────────────────────────
#  DASHBOARD SUMMARY
# ─────────────────────────────────────────────

@suppliers_bp.route('/summary', methods=['GET'])
def get_summary():
    suppliers  = Supplier.query.filter_by(IsActive=True).all()
    invoices   = SupplierInvoice.query.all()
    payments   = SupplierPayment.query.all()

    total_invoiced   = sum(i.Amount for i in invoices)
    total_paid       = sum(p.Amount for p in payments)
    balance_due      = total_invoiced - total_paid

    overdue_invoices = []
    today            = date.today()
    for inv in invoices:
        if inv.Status != 'Paid' and inv.DueDate and inv.DueDate < today:
            overdue_invoices.append(inv.to_dict())

    by_type = defaultdict(int)
    for s in suppliers:
        by_type[s.Type] += 1

    top_suppliers = sorted(
        [s.to_dict() for s in suppliers],
        key=lambda x: x['total_invoiced'],
        reverse=True
    )[:5]

    return jsonify({
        "total_suppliers":   len(suppliers),
        "total_invoiced":    total_invoiced,
        "total_paid":        total_paid,
        "balance_due":       balance_due,
        "overdue_count":     len(overdue_invoices),
        "overdue_invoices":  overdue_invoices,
        "unpaid_count":      sum(1 for i in invoices if i.Status == 'Unpaid'),
        "partial_count":     sum(1 for i in invoices if i.Status == 'Partial'),
        "suppliers_by_type": dict(by_type),
        "top_suppliers":     top_suppliers,
    })


# ─────────────────────────────────────────────
#  HELPER
# ─────────────────────────────────────────────

def _recalc_invoice_status(inv):
    """Recalculate and save invoice status based on payment links."""
    paid = inv.amount_paid()
    if paid <= 0:
        inv.Status = 'Unpaid'
    elif paid >= inv.Amount:
        inv.Status = 'Paid'
    else:
        inv.Status = 'Partial'