from .. import db
from datetime import datetime


class Supplier(db.Model):
    """Master supplier directory — fuel & lubricant vendors."""
    __tablename__ = 'suppliers'

    SupplierID   = db.Column('supplier_id',   db.Integer,     primary_key=True)
    Name         = db.Column('name',           db.String(120), nullable=False)
    Type         = db.Column('type',           db.String(30),  nullable=False)   # Fuel / Lubricant / Both
    ContactPerson= db.Column('contact_person', db.String(100))
    Phone        = db.Column('phone',          db.String(30))
    Email        = db.Column('email',          db.String(120))
    Address      = db.Column('address',        db.Text)
    TaxID        = db.Column('tax_id',         db.String(60))   # VAT / GST / TIN
    BankDetails  = db.Column('bank_details',   db.Text)         # free-text bank info
    CreditDays   = db.Column('credit_days',    db.Integer,     default=30)       # payment terms
    Notes        = db.Column('notes',          db.Text)
    IsActive     = db.Column('is_active',      db.Boolean,     default=True)
    CreatedAt    = db.Column('created_at',     db.DateTime,    server_default=db.func.now())
    UpdatedAt    = db.Column('updated_at',     db.DateTime,    server_default=db.func.now(),
                             onupdate=datetime.utcnow)

    # relationships
    invoices = db.relationship('SupplierInvoice', back_populates='supplier',
                               lazy='dynamic', cascade='all, delete-orphan')
    payments = db.relationship('SupplierPayment', back_populates='supplier',
                               lazy='dynamic', cascade='all, delete-orphan')

    def to_dict(self):
        total_invoiced = sum(i.Amount for i in self.invoices)
        total_paid     = sum(p.Amount for p in self.payments)
        return {
            "id":             self.SupplierID,
            "name":           self.Name,
            "type":           self.Type,
            "contact_person": self.ContactPerson,
            "phone":          self.Phone,
            "email":          self.Email,
            "address":        self.Address,
            "tax_id":         self.TaxID,
            "bank_details":   self.BankDetails,
            "credit_days":    self.CreditDays,
            "notes":          self.Notes,
            "is_active":      self.IsActive,
            "total_invoiced": total_invoiced,
            "total_paid":     total_paid,
            "balance_due":    total_invoiced - total_paid,
        }


class SupplierInvoice(db.Model):
    """A purchase order / invoice raised against a supplier.
       May be linked to a fuel delivery or lubricant purchase."""
    __tablename__ = 'supplier_invoices'

    InvoiceID    = db.Column('invoice_id',    db.Integer,     primary_key=True)
    SupplierID   = db.Column('supplier_id',   db.Integer,
                             db.ForeignKey('suppliers.supplier_id'), nullable=False)
    InvoiceRef   = db.Column('invoice_ref',   db.String(100), nullable=False)
    Category     = db.Column('category',      db.String(30),  nullable=False)   # Fuel / Lubricant / Other
    Description  = db.Column('description',   db.Text)
    Amount       = db.Column('amount',        db.Float,       nullable=False)
    DueDate      = db.Column('due_date',      db.Date)
    InvoiceDate  = db.Column('invoice_date',  db.Date,        nullable=False)
    Status       = db.Column('status',        db.String(20),  default='Unpaid')  # Unpaid/Partial/Paid
    CreatedAt    = db.Column('created_at',    db.DateTime,    server_default=db.func.now())

    supplier = db.relationship('Supplier', back_populates='invoices')
    payment_links = db.relationship('InvoicePaymentLink', back_populates='invoice',
                                    cascade='all, delete-orphan')

    def amount_paid(self):
        return sum(lnk.payment.Amount for lnk in self.payment_links if lnk.payment)

    def to_dict(self):
        paid = self.amount_paid()
        return {
            "id":            self.InvoiceID,
            "supplier_id":   self.SupplierID,
            "supplier_name": self.supplier.Name if self.supplier else '',
            "invoice_ref":   self.InvoiceRef,
            "category":      self.Category,
            "description":   self.Description,
            "amount":        self.Amount,
            "amount_paid":   paid,
            "balance":       self.Amount - paid,
            "due_date":      self.DueDate.strftime('%Y-%m-%d') if self.DueDate else None,
            "invoice_date":  self.InvoiceDate.strftime('%Y-%m-%d'),
            "status":        self.Status,
        }


class SupplierPayment(db.Model):
    """A payment made to a supplier (may settle one or more invoices)."""
    __tablename__ = 'supplier_payments'

    PaymentID    = db.Column('payment_id',    db.Integer,  primary_key=True)
    SupplierID   = db.Column('supplier_id',   db.Integer,
                             db.ForeignKey('suppliers.supplier_id'), nullable=False)
    Amount       = db.Column('amount',        db.Float,    nullable=False)
    PaymentMethod= db.Column('payment_method',db.String(50), nullable=False)
    Reference    = db.Column('reference',     db.String(100))   # cheque / transfer ref
    Notes        = db.Column('notes',         db.Text)
    PaymentDate  = db.Column('payment_date',  db.Date,     nullable=False)
    CreatedAt    = db.Column('created_at',    db.DateTime, server_default=db.func.now())

    supplier      = db.relationship('Supplier', back_populates='payments')
    invoice_links = db.relationship('InvoicePaymentLink', back_populates='payment',
                                    cascade='all, delete-orphan')

    def to_dict(self):
        linked_invoices = [lnk.invoice.InvoiceRef for lnk in self.invoice_links if lnk.invoice]
        return {
            "id":             self.PaymentID,
            "supplier_id":    self.SupplierID,
            "supplier_name":  self.supplier.Name if self.supplier else '',
            "amount":         self.Amount,
            "payment_method": self.PaymentMethod,
            "reference":      self.Reference,
            "notes":          self.Notes,
            "date":           self.PaymentDate.strftime('%Y-%m-%d'),
            "linked_invoices":linked_invoices,
        }


class InvoicePaymentLink(db.Model):
    """Many-to-many bridge: one payment can settle multiple invoices."""
    __tablename__ = 'invoice_payment_links'

    LinkID      = db.Column('link_id',    db.Integer, primary_key=True)
    InvoiceID   = db.Column('invoice_id', db.Integer,
                            db.ForeignKey('supplier_invoices.invoice_id'), nullable=False)
    PaymentID   = db.Column('payment_id', db.Integer,
                            db.ForeignKey('supplier_payments.payment_id'), nullable=False)
    AllocatedAmount = db.Column('allocated_amount', db.Float, nullable=False)

    invoice = db.relationship('SupplierInvoice', back_populates='payment_links')
    payment = db.relationship('SupplierPayment', back_populates='invoice_links')