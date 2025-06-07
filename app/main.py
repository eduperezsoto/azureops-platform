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
    # Opentelemetry configuration
    trace.set_tracer_provider(
        TracerProvider(
            resource=Resource.create({SERVICE_NAME: "flask-app"})
        )
    )

    FlaskInstrumentor().instrument_app(app)
    RequestsInstrumentor().instrument()

    trace_exporter = AzureMonitorTraceExporter(connection_string=Config.CONNECTION_STRING)
    trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(trace_exporter))
else:
    app.logger.info(f"Open telemetry has not been configured because no connection string has been specified.")


def fetch_secret(name: str):
    app.logger.info(f"Fetching secret '{name}'")

    if not app.config["KEY_VAULT_URI"]:
        app.logger.error(f"Error getting secret '{name}' because KEY_VAULT_URI is not configured")
        return False, None

    try:
        credential = ManagedIdentityCredential(client_id=app.config["AZURE_CLIENT_ID"])
        client = SecretClient(vault_url=app.config["KEY_VAULT_URI"], credential=credential)
        secret = client.get_secret(name)
        return True, secret.value
    except Exception as e:
        app.logger.error(f"Error getting secret '{name}': {e}")
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
