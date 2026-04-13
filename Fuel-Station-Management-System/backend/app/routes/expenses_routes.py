from flask import Blueprint, request, jsonify, render_template
from ..models.expenses import Expense
from .. import db
from datetime import datetime
from .auth_routes import login_required, role_required

expenses_bp = Blueprint('expenses', __name__, url_prefix='/expenses')


@expenses_bp.route('/page', methods=['GET'])
def expenses_page():
    return render_template('expenses.html')


@expenses_bp.route('/', methods=['GET'])
def get_expenses():
    category = request.args.get('category')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 5, type=int)

    query = Expense.query

    if category:
        query = query.filter(Expense.Category == category)
    if start_date:
        query = query.filter(Expense.ExpenseDate >= start_date)
    if end_date:
        query = query.filter(Expense.ExpenseDate <= end_date)

    total_count = query.count()
    expenses = query.order_by(Expense.ExpenseDate.desc()).paginate(page=page, per_page=per_page)

    result = [{
        "id": e.ExpenseID,
        "title": e.Title,
        "category": e.Category,
        "amount": e.Amount,
        "payment_method": e.PaymentMethod,
        "description": e.Description,
        "date": e.ExpenseDate.strftime('%Y-%m-%d')
    } for e in expenses.items]

    return jsonify({
        "data": result,
        "pagination": {
            "page": page,
            "per_page": per_page,
            "total": total_count,
            "pages": (total_count + per_page - 1) // per_page,
            "has_prev": expenses.has_prev,
            "has_next": expenses.has_next
        }
    })


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
@login_required
@role_required(1, 7) 
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
@login_required
@role_required(1, 7) 
def delete_expense(id):
    expense = Expense.query.get(id)
    if not expense:
        return jsonify({"message": "Expense not found"}), 404

    db.session.delete(expense)
    db.session.commit()
    return jsonify({"message": "Expense deleted"})


@expenses_bp.route('/summary', methods=['GET'])
def expense_summary():
    from datetime import timedelta
    
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')

    query = Expense.query
    if start_date:
        query = query.filter(Expense.ExpenseDate >= start_date)
    if end_date:
        query = query.filter(Expense.ExpenseDate <= end_date)

    expenses = query.all()

    total = sum(e.Amount for e in expenses) if expenses else 0
    daily_avg = 0
    date_range_start = None
    date_range_end = None
    
    if expenses:
        date_range_start = min(e.ExpenseDate for e in expenses)
        date_range_end = max(e.ExpenseDate for e in expenses)
        date_span = (date_range_end - date_range_start).days + 1
        daily_avg = total / max(date_span, 1)
    else:
        from datetime import date
        today = date.today()
        date_range_start = today
        date_range_end = today

    # Categorize totals
    from collections import defaultdict
    category_totals = defaultdict(float)
    for e in expenses:
        category_totals[e.Category] += e.Amount

    # Calculate comparison with previous period
    trend_percentage = 0
    trend_direction = "neutral"
    avg_trend_percentage = 0
    avg_trend_direction = "neutral"
    
    if start_date and end_date:
        try:
            start = datetime.strptime(start_date, '%Y-%m-%d').date()
            end = datetime.strptime(end_date, '%Y-%m-%d').date()
            period_days = (end - start).days + 1
            prev_start = start - timedelta(days=period_days)
            prev_end = start - timedelta(days=1)
            
            prev_query = Expense.query.filter(
                Expense.ExpenseDate >= prev_start,
                Expense.ExpenseDate <= prev_end
            )
            prev_expenses = prev_query.all()
            prev_total = sum(e.Amount for e in prev_expenses) if prev_expenses else 0
            prev_daily_avg = prev_total / max(period_days, 1) if prev_expenses else 0
            
            if prev_total > 0:
                trend_percentage = ((total - prev_total) / prev_total) * 100
                trend_direction = "up" if trend_percentage >= 0 else "down"
            elif total > 0:
                trend_percentage = 100
                trend_direction = "up"
            else:
                trend_percentage = 0
                trend_direction = "neutral"
            
            # Calculate average daily trend
            if prev_daily_avg > 0:
                avg_trend_percentage = ((daily_avg - prev_daily_avg) / prev_daily_avg) * 100
                avg_trend_direction = "up" if avg_trend_percentage >= 0 else "down"
            elif daily_avg > 0:
                avg_trend_percentage = 100
                avg_trend_direction = "up"
            else:
                avg_trend_percentage = 0
                avg_trend_direction = "neutral"
        except:
            trend_percentage = 0
            trend_direction = "neutral"
            avg_trend_percentage = 0
            avg_trend_direction = "neutral"
    else:
        # Default: last 30 days vs 30 days before that
        today_date = datetime.now().date()
        end = today_date
        start = today_date - timedelta(days=30)
        period_days = 30
        prev_end = start - timedelta(days=1)
        prev_start = prev_end - timedelta(days=30)
        
        prev_query = Expense.query.filter(
            Expense.ExpenseDate >= prev_start,
            Expense.ExpenseDate <= prev_end
        )
        prev_expenses = prev_query.all()
        prev_total = sum(e.Amount for e in prev_expenses) if prev_expenses else 0
        prev_daily_avg = prev_total / max(period_days, 1) if prev_expenses else 0
        
        if prev_total > 0:
            trend_percentage = ((total - prev_total) / prev_total) * 100
            trend_direction = "up" if trend_percentage >= 0 else "down"
        elif total > 0:
            trend_percentage = 100
            trend_direction = "up"
        else:
            trend_percentage = 0
            trend_direction = "neutral"
        
        # Calculate average daily trend
        if prev_daily_avg > 0:
            avg_trend_percentage = ((daily_avg - prev_daily_avg) / prev_daily_avg) * 100
            avg_trend_direction = "up" if avg_trend_percentage >= 0 else "down"
        elif daily_avg > 0:
            avg_trend_percentage = 100
            avg_trend_direction = "up"
        else:
            avg_trend_percentage = 0
            avg_trend_direction = "neutral"

    return jsonify({
        "total": float(total),
        "average_per_day": float(daily_avg),
        "by_category": dict(category_totals),
        "date_range": {
            "start": date_range_start.strftime('%Y-%m-%d') if date_range_start else None,
            "end": date_range_end.strftime('%Y-%m-%d') if date_range_end else None
        },
        "trend": {
            "percentage": abs(round(trend_percentage, 1)),
            "direction": trend_direction
        },
        "average_trend": {
            "percentage": abs(round(avg_trend_percentage, 1)),
            "direction": avg_trend_direction
        },
        "expense_count": len(expenses)
    })
