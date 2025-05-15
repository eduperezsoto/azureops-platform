from flask import Flask
from .config import Config

def create_app():
    # Crear la instancia de Flask
    app = Flask(__name__)
    # Cargar configuración desde config.py
    app.config.from_object(Config)

    # Registrar el blueprint de rutas
    from .routes import bp
    app.register_blueprint(bp)

    return app
