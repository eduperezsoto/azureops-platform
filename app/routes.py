from flask import Blueprint, jsonify, current_app as app
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

bp = Blueprint('main', __name__)

@bp.route("/")
def hello():
    # Recuperamos la URI del Key Vault desde la configuración
    kv_uri = app.config["KEY_VAULT_URI"]
    # Autenticación automática con Managed Identity o credenciales locales
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=kv_uri, credential=credential)
    # Obtenemos el secreto "MY_SECRET"
    secret = client.get_secret("MY_SECRET").value

    return jsonify({
        "message": "Hello, DevSecOps on Azure!",
        "secret_loaded": bool(secret)
    })

@bp.route("/health")
def health():
    # Endpoint de comprobación de estado
    return jsonify({"status": "ok"})
