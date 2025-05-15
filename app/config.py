import os

class Config:
    # URI de tu Key Vault, proporcionada como variable de entorno
    KEY_VAULT_URI = os.getenv("KEY_VAULT_URI", "")

    # Otras configuraciones comunes pueden ir aquí
    DEBUG = os.getenv("FLASK_DEBUG", "False") == "True"
