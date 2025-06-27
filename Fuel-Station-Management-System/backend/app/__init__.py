from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from .config import Config

db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    db.init_app(app)

    from .routes.role_routes import role_bp
    app.register_blueprint(role_bp)

    from .routes.staff_routes import staff_bp
    app.register_blueprint(staff_bp)

    from .routes.shift_routes import shift_bp  
    app.register_blueprint(shift_bp)

    from .routes.expenses_routes import expenses_bp
    app.register_blueprint(expenses_bp)



    from flask import render_template
    @app.route('/')
    def index():
        return render_template("index.html")

    return app
