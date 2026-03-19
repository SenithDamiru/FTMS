from flask import Flask, render_template
from flask_sqlalchemy import SQLAlchemy
from .config import Config

db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # ── Session config ──
    app.secret_key = 'fuelsys-secret-key-change-in-production'
    app.config['SESSION_COOKIE_HTTPONLY'] = True
    app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'

    db.init_app(app)

    from .routes.role_routes import role_bp
    app.register_blueprint(role_bp)

    from .routes.staff_routes import staff_bp
    app.register_blueprint(staff_bp)

    from .routes.shift_routes import shift_bp
    app.register_blueprint(shift_bp)

    from .routes.expenses_routes import expenses_bp
    app.register_blueprint(expenses_bp)

    from .routes.ml_routes import ml_bp
    app.register_blueprint(ml_bp)

    from .routes.lubricants_routes import lubricants_bp
    app.register_blueprint(lubricants_bp)

    from .routes.suppliers_routes import suppliers_bp
    app.register_blueprint(suppliers_bp)

    from .routes.pumps_routes import pumps_bp
    app.register_blueprint(pumps_bp)

    from .routes.sales_routes import sales_bp
    app.register_blueprint(sales_bp)

    # ── Auth blueprint ──
    from .routes.auth_routes import auth_bp
    app.register_blueprint(auth_bp)

    # ── Page routes ──
    @app.route('/')
    @app.route('/login')
    def login_page():
        return render_template('login.html')

    @app.route('/dashboard')
    def dashboard():
        return render_template('index.html')

    return app