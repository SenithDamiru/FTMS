from flask import Blueprint, request, jsonify, render_template
from ..models.expenses import Expense
from .. import db
from datetime import datetime

expenses_bp = Blueprint('expenses', __name__, url_prefix='/expenses')


@expenses_bp.route('/page', methods=['GET'])
def expenses_page():
    return render_template('expenses.html')


@expenses_bp.route('/', methods=['GET'])
def get_expenses():
    category = request.args.get('category')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')

    query = Expense.query

    if category:
        query = query.filter(Expense.Category == category)
    if start_date:
        query = query.filter(Expense.ExpenseDate >= start_date)
    if end_date:
        query = query.filter(Expense.ExpenseDate <= end_date)

    expenses = query.order_by(Expense.ExpenseDate.desc()).all()

    result = [{
        "id": e.ExpenseID,
        "title": e.Title,
        "category": e.Category,
        "amount": e.Amount,
        "payment_method": e.PaymentMethod,
        "description": e.Description,
        "date": e.ExpenseDate.strftime('%Y-%m-%d')
    } for e in expenses]

    return jsonify(result)


@expenses_bp.route('/add', methods=['POST'])
def add_expense():
    data = request.json
    new_expense = Expense(
        Title=data['title'],
        Category=data['category'],
        Amount=data['amount'],
        PaymentMethod=data['payment_method'],
        Description=data.get('description', ''),
        ExpenseDate=datetime.strptime(data['date'], '%Y-%m-%d').date()
    )
    db.session.add(new_expense)
    db.session.commit()
    return jsonify({"message": "Expense added successfully"}), 201


@expenses_bp.route('/update/<int:id>', methods=['PUT'])
def update_expense(id):
    expense = Expense.query.get(id)
    if not expense:
        return jsonify({"message": "Expense not found"}), 404

    data = request.json
    expense.Title = data['title']
    expense.Category = data['category']
    expense.Amount = data['amount']
    expense.PaymentMethod = data['payment_method']
    expense.Description = data.get('description', '')
    expense.ExpenseDate = datetime.strptime(data['date'], '%Y-%m-%d').date()

    db.session.commit()
    return jsonify({"message": "Expense updated"})


@expenses_bp.route('/delete/<int:id>', methods=['DELETE'])
def delete_expense(id):
    expense = Expense.query.get(id)
    if not expense:
        return jsonify({"message": "Expense not found"}), 404

    db.session.delete(expense)
    db.session.commit()
    return jsonify({"message": "Expense deleted"})


@expenses_bp.route('/summary', methods=['GET'])
def expense_summary():
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')

    query = Expense.query
    if start_date:
        query = query.filter(Expense.ExpenseDate >= start_date)
    if end_date:
        query = query.filter(Expense.ExpenseDate <= end_date)

    expenses = query.all()

    total = sum(e.Amount for e in expenses)
    daily_avg = 0
    if expenses:
        date_span = (max(e.ExpenseDate for e in expenses) - min(e.ExpenseDate for e in expenses)).days + 1
        daily_avg = total / max(date_span, 1)

    # Categorize totals
    from collections import defaultdict
    category_totals = defaultdict(float)
    for e in expenses:
        category_totals[e.Category] += e.Amount

    return jsonify({
        "total": total,
        "average_per_day": daily_avg,
        "by_category": category_totals
    })
