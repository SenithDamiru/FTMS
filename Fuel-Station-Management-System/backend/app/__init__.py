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

    from flask import render_template
    @app.route('/')
    def index():
        return render_template("index.html")

    return app
