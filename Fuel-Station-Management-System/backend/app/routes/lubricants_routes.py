from flask import Blueprint, request, jsonify, render_template
from ..models.lubricants import Lubricant, LubricantSale, LubricantPurchase
from .. import db
from datetime import datetime
from collections import defaultdict

lubricants_bp = Blueprint('lubricants', __name__, url_prefix='/lubricants')


# ─────────────────────────────────────────────
#  PAGE RENDER
# ─────────────────────────────────────────────

@lubricants_bp.route('/page', methods=['GET'])
def lubricants_page():
    return render_template('lubricants.html')


# ─────────────────────────────────────────────
#  PRODUCT CATALOG  CRUD
# ─────────────────────────────────────────────

@lubricants_bp.route('/products', methods=['GET'])
def get_products():
    """Return all lubricant products, optionally filtered by category."""
    category = request.args.get('category')
    query = Lubricant.query
    if category:
        query = query.filter(Lubricant.Category == category)
    products = query.order_by(Lubricant.Name).all()
    return jsonify([p.to_dict() for p in products])


@lubricants_bp.route('/products/<int:id>', methods=['GET'])
def get_product(id):
    product = Lubricant.query.get_or_404(id)
    return jsonify(product.to_dict())


@lubricants_bp.route('/products/add', methods=['POST'])
def add_product():
    data = request.json
    product = Lubricant(
        Name=data['name'],
        Brand=data['brand'],
        Grade=data['grade'],
        Category=data['category'],
        UnitType=data['unit_type'],
        SellingPrice=float(data['selling_price']),
        CostPrice=float(data['cost_price']),
        StockQty=float(data.get('stock_qty', 0)),
        LowStockThreshold=float(data.get('low_stock_threshold', 10)),
        Description=data.get('description', '')
    )
    db.session.add(product)
    db.session.commit()
    return jsonify({"message": "Product added successfully", "id": product.LubricantID}), 201


@lubricants_bp.route('/products/update/<int:id>', methods=['PUT'])
def update_product(id):
    product = Lubricant.query.get_or_404(id)
    data = request.json
    product.Name             = data['name']
    product.Brand            = data['brand']
    product.Grade            = data['grade']
    product.Category         = data['category']
    product.UnitType         = data['unit_type']
    product.SellingPrice     = float(data['selling_price'])
    product.CostPrice        = float(data['cost_price'])
    product.LowStockThreshold = float(data.get('low_stock_threshold', 10))
    product.Description      = data.get('description', '')
    db.session.commit()
    return jsonify({"message": "Product updated"})


@lubricants_bp.route('/products/delete/<int:id>', methods=['DELETE'])
def delete_product(id):
    product = Lubricant.query.get_or_404(id)
    # guard: don't delete if sales/purchase history exists
    if product.sales.count() > 0 or product.purchases.count() > 0:
        return jsonify({"message": "Cannot delete: product has transaction history"}), 400
    db.session.delete(product)
    db.session.commit()
    return jsonify({"message": "Product deleted"})


# ─────────────────────────────────────────────
#  SALES  CRUD
# ─────────────────────────────────────────────

@lubricants_bp.route('/sales', methods=['GET'])
def get_sales():
    start_date = request.args.get('start_date')
    end_date   = request.args.get('end_date')
    lub_id     = request.args.get('lubricant_id')

    query = LubricantSale.query
    if start_date:
        query = query.filter(LubricantSale.SaleDate >= start_date)
    if end_date:
        query = query.filter(LubricantSale.SaleDate <= end_date)
    if lub_id:
        query = query.filter(LubricantSale.LubricantID == int(lub_id))

    sales = query.order_by(LubricantSale.SaleDate.desc()).all()
    return jsonify([s.to_dict() for s in sales])


@lubricants_bp.route('/sales/add', methods=['POST'])
def add_sale():
    data = request.json
    product = Lubricant.query.get_or_404(int(data['lubricant_id']))

    qty = float(data['quantity'])
    if product.StockQty < qty:
        return jsonify({"message": f"Insufficient stock. Available: {product.StockQty} {product.UnitType}"}), 400

    unit_price   = float(data.get('unit_price', product.SellingPrice))
    total_amount = qty * unit_price

    sale = LubricantSale(
        LubricantID   = product.LubricantID,
        CustomerName  = data.get('customer_name', ''),
        Quantity      = qty,
        UnitPrice     = unit_price,
        TotalAmount   = total_amount,
        PaymentMethod = data['payment_method'],
        Notes         = data.get('notes', ''),
        SaleDate      = datetime.strptime(data['date'], '%Y-%m-%d').date()
    )

    # deduct stock
    product.StockQty -= qty

    db.session.add(sale)
    db.session.commit()
    return jsonify({"message": "Sale recorded", "id": sale.SaleID, "total_amount": total_amount}), 201


@lubricants_bp.route('/sales/update/<int:id>', methods=['PUT'])
def update_sale(id):
    sale = LubricantSale.query.get_or_404(id)
    data = request.json

    old_qty = sale.Quantity
    new_qty = float(data['quantity'])
    diff    = new_qty - old_qty   # positive = sold more, negative = sold less

    product = Lubricant.query.get_or_404(sale.LubricantID)
    if product.StockQty - diff < 0:
        return jsonify({"message": "Insufficient stock for this update"}), 400

    product.StockQty   -= diff
    sale.CustomerName   = data.get('customer_name', '')
    sale.Quantity       = new_qty
    sale.UnitPrice      = float(data.get('unit_price', sale.UnitPrice))
    sale.TotalAmount    = new_qty * sale.UnitPrice
    sale.PaymentMethod  = data['payment_method']
    sale.Notes          = data.get('notes', '')
    sale.SaleDate       = datetime.strptime(data['date'], '%Y-%m-%d').date()

    db.session.commit()
    return jsonify({"message": "Sale updated"})


@lubricants_bp.route('/sales/delete/<int:id>', methods=['DELETE'])
def delete_sale(id):
    sale = LubricantSale.query.get_or_404(id)
    # restore stock
    product = Lubricant.query.get(sale.LubricantID)
    if product:
        product.StockQty += sale.Quantity
    db.session.delete(sale)
    db.session.commit()
    return jsonify({"message": "Sale deleted and stock restored"})


# ─────────────────────────────────────────────
#  PURCHASES / RESTOCK  CRUD
# ─────────────────────────────────────────────

@lubricants_bp.route('/purchases', methods=['GET'])
def get_purchases():
    start_date = request.args.get('start_date')
    end_date   = request.args.get('end_date')
    lub_id     = request.args.get('lubricant_id')

    query = LubricantPurchase.query
    if start_date:
        query = query.filter(LubricantPurchase.PurchaseDate >= start_date)
    if end_date:
        query = query.filter(LubricantPurchase.PurchaseDate <= end_date)
    if lub_id:
        query = query.filter(LubricantPurchase.LubricantID == int(lub_id))

    purchases = query.order_by(LubricantPurchase.PurchaseDate.desc()).all()
    return jsonify([p.to_dict() for p in purchases])


@lubricants_bp.route('/purchases/add', methods=['POST'])
def add_purchase():
    data = request.json
    product = Lubricant.query.get_or_404(int(data['lubricant_id']))

    qty          = float(data['quantity'])
    cost_per_unit = float(data['cost_per_unit'])
    total_cost   = qty * cost_per_unit

    purchase = LubricantPurchase(
        LubricantID  = product.LubricantID,
        SupplierName = data['supplier_name'],
        Quantity     = qty,
        CostPerUnit  = cost_per_unit,
        TotalCost    = total_cost,
        InvoiceRef   = data.get('invoice_ref', ''),
        Notes        = data.get('notes', ''),
        PurchaseDate = datetime.strptime(data['date'], '%Y-%m-%d').date()
    )

    # add to stock
    product.StockQty += qty

    db.session.add(purchase)
    db.session.commit()
    return jsonify({"message": "Purchase recorded and stock updated", "id": purchase.PurchaseID, "total_cost": total_cost}), 201


@lubricants_bp.route('/purchases/update/<int:id>', methods=['PUT'])
def update_purchase(id):
    purchase = LubricantPurchase.query.get_or_404(id)
    data     = request.json

    old_qty = purchase.Quantity
    new_qty = float(data['quantity'])
    diff    = new_qty - old_qty   # positive = bought more

    product = Lubricant.query.get_or_404(purchase.LubricantID)
    # guard: can't remove more than current stock
    if product.StockQty + diff < 0:
        return jsonify({"message": "Cannot reduce purchase — stock would go negative"}), 400

    product.StockQty      += diff
    purchase.SupplierName  = data['supplier_name']
    purchase.Quantity      = new_qty
    purchase.CostPerUnit   = float(data['cost_per_unit'])
    purchase.TotalCost     = new_qty * purchase.CostPerUnit
    purchase.InvoiceRef    = data.get('invoice_ref', '')
    purchase.Notes         = data.get('notes', '')
    purchase.PurchaseDate  = datetime.strptime(data['date'], '%Y-%m-%d').date()

    db.session.commit()
    return jsonify({"message": "Purchase updated"})


@lubricants_bp.route('/purchases/delete/<int:id>', methods=['DELETE'])
def delete_purchase(id):
    purchase = LubricantPurchase.query.get_or_404(id)
    product  = Lubricant.query.get(purchase.LubricantID)
    if product:
        stock_after = product.StockQty - purchase.Quantity
        if stock_after < 0:
            return jsonify({"message": "Cannot delete — stock would go negative"}), 400
        product.StockQty = stock_after
    db.session.delete(purchase)
    db.session.commit()
    return jsonify({"message": "Purchase deleted and stock adjusted"})


# ─────────────────────────────────────────────
#  DASHBOARD SUMMARY
# ─────────────────────────────────────────────

@lubricants_bp.route('/summary', methods=['GET'])
def get_summary():
    all_products  = Lubricant.query.all()
    all_sales     = LubricantSale.query.all()
    all_purchases = LubricantPurchase.query.all()

    total_products  = len(all_products)
    low_stock_items = [p.to_dict() for p in all_products if p.StockQty <= p.LowStockThreshold]
    total_sales_rev = sum(s.TotalAmount for s in all_sales)
    total_purchase_cost = sum(p.TotalCost for p in all_purchases)

    # sales by product
    sales_by_product = defaultdict(float)
    for s in all_sales:
        sales_by_product[s.lubricant.Name if s.lubricant else 'Unknown'] += s.TotalAmount

    # sales by category
    sales_by_category = defaultdict(float)
    for s in all_sales:
        cat = s.lubricant.Category if s.lubricant else 'Unknown'
        sales_by_category[cat] += s.TotalAmount

    return jsonify({
        "total_products":      total_products,
        "low_stock_count":     len(low_stock_items),
        "low_stock_items":     low_stock_items,
        "total_sales_revenue": total_sales_rev,
        "total_purchase_cost": total_purchase_cost,
        "gross_profit":        total_sales_rev - total_purchase_cost,
        "total_sales_count":   len(all_sales),
        "sales_by_product":    dict(sales_by_product),
        "sales_by_category":   dict(sales_by_category),
    })


# ─────────────────────────────────────────────
#  LOW STOCK ALERTS
# ─────────────────────────────────────────────

@lubricants_bp.route('/low-stock', methods=['GET'])
def get_low_stock():
    products = Lubricant.query.all()
    low = [p.to_dict() for p in products if p.StockQty <= p.LowStockThreshold]
    return jsonify(low)