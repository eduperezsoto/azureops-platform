import os
import logging
from flask import Flask, jsonify, render_template
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient
from config import Config
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from azure.monitor.opentelemetry.exporter import AzureMonitorTraceExporter


logging.basicConfig(
    level=logging.DEBUG if Config.ENV == "development" else logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)

app = Flask(__name__)
app.config.from_object(Config)


if Config.CONNECTION_STRING:
    # Set global TracerProvider before instrumenting
    trace.set_tracer_provider(
        TracerProvider(
            resource=Resource.create({SERVICE_NAME: "flask-app"})
        )
    )

    # Enable tracing for Flask library
    FlaskInstrumentor().instrument_app(app)

    # Enable tracing for requests library
    RequestsInstrumentor().instrument()

    trace_exporter = AzureMonitorTraceExporter(connection_string=Config.CONNECTION_STRING)
    trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(trace_exporter))
else:
    app.logger.info(f"Open telemetry no se ha configurado ya que no hay ningun Connection String especificado.")

def fetch_secret(name: str):
    if not app.config["KEY_VAULT_URI"]:
        app.logger.error(f"Error al obtener secreto '{name}'porque KEY_VAULT_URI no está configurado")
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
    return render_template('index.html')


@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200


@app.route("/secret")
def secret():
    _, value = fetch_secret("mysecret")
    return render_template('secret.html', secret=value)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=(Config.ENV == "development"))
