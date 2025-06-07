import os

class Config:
    AZURE_CLIENT_ID = os.getenv("AZURE_CLIENT_ID")
    KEY_VAULT_URI = os.getenv("KEY_VAULT_URI")
    ENV = os.getenv("FLASK_ENV", "production")
    CONNECTION_STRING = os.getenv('APPLICATIONINSIGHTS_CONNECTION_STRING')