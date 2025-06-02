from flask import Flask, jsonify
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient
import os

class Config:
    KEY_VAULT_URI = os.getenv("KEY_VAULT_URI")
    ENV = os.getenv("FLASK_ENV", "production")

app = Flask(__name__)
app.config.from_object(Config)


def fetch_secret(name: str):
    """
    Intenta obtener un secreto de Key Vault.
    Devuelve tupla (secret_loaded, secret_value).
    """
    if not app.config["KEY_VAULT_URI"]:
        return False, None
    try:
        credential = ManagedIdentityCredential(client_id=os.getenv("AZURE_CLIENT_ID"))
        client = SecretClient(vault_url=app.config["KEY_VAULT_URI"], credential=credential)
        secret = client.get_secret(name)
        return True, secret.value
    except Exception as e:
        app.logger.error(f"Error al obtener secreto '{name}': {e}")
        return False, None


@app.route("/")
def index():
    loaded, value = fetch_secret("mysecret")
    return jsonify({
        "message": "Hello, world!",
        "secret_loaded": loaded,
        "secret_value": value
    })


@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200


@app.route("/secret")
def secret():
    loaded, value = fetch_secret("MY_SECRET")
    return jsonify({
        "secret_loaded": loaded,
        "secret_value": value
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=(Config.ENV == "development"))
