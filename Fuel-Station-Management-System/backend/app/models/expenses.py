from .. import db

class Expense(db.Model):
    __tablename__ = 'expenses'

    ExpenseID = db.Column('expense_id', db.Integer, primary_key=True)
    Title = db.Column('title', db.String(100), nullable=False)
    Category = db.Column('category', db.String(50), nullable=False)
    Amount = db.Column('amount', db.Float, nullable=False)
    PaymentMethod = db.Column('payment_method', db.String(50), nullable=False)
    Description = db.Column('description', db.Text)
    ExpenseDate = db.Column('expense_date', db.Date, nullable=False)
    CreatedAt = db.Column('created_at', db.DateTime, server_default=db.func.now())
