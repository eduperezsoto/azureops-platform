# tests/integration/test_endpoints.py
import pytest
from app.main import app


@pytest.fixture
def client():
    """
    Creates a Flask test client using the real application.
    """
    # Disable any previous value in KEY_VAULT_URI
    app.config["KEY_VAULT_URI"] = None
    app.config["AZURE_CLIENT_ID"] = None

    # Create the test client
    with app.test_client() as c:
        yield c


def test_index_endpoint_status_and_content(client):
    """
    GET "/" should return 200 and contain the known prompt from the index template
    """
    response = client.get("/")
    assert response.status_code == 200

    html = response.get_data(as_text=True)
    assert "Quieres saber un secreto?" in html


def test_health_endpoint_returns_json_healthy(client):
    """
    GET "/health" should return 200 with JSON {"status": "healthy"}.
    """
    response = client.get("/health")
    assert response.status_code == 200

    data = response.get_json()
    assert isinstance(data, dict)
    assert data.get("status") == "healthy"


def test_secret_endpoint_without_keyvault(client):
    """
    When no KEY_VAULT_URI is configured, GET "/secret" renders the error message.
    """
    # Ensure KEY_VAULT_URI is None
    app.config["KEY_VAULT_URI"] = None

    response = client.get("/secret")
    assert response.status_code == 200

    html = response.get_data(as_text=True)
    assert "Error: El secreto no pudo ser leido!" in html


def test_secret_endpoint_with_secret_success(monkeypatch, client):
    """
    When fetch_secret returns a valid secret, GET "/secret" displays that secret in the response.
    """
    # Configure KEY_VAULT_URI so fetch_secret triggers the reading logic
    app.config["KEY_VAULT_URI"] = "https://mi-vault.vault.azure.net/"

    # Patch fetch_secret to avoid calling Azure and return a fixed pair
    def fake_fetch_secret(name: str):
        return True, "valor-demo"

    monkeypatch.setattr("app.main.fetch_secret", fake_fetch_secret)

    response = client.get("/secret")
    assert response.status_code == 200

    html = response.get_data(as_text=True)
    assert "valor-demo" in html


def test_secret_endpoint_with_secret_error(monkeypatch, client):
    """
    When fetch_secret fails, GET "/secret" renders the error message.
    """
    # Configure KEY_VAULT_URI so fetch_secret attempts reading
    app.config["KEY_VAULT_URI"] = "https://mi-vault.vault.azure.net/"

    # Patch fetch_secret to return (False, None)
    monkeypatch.setattr("app.main.fetch_secret", lambda name: (False, None))

    response = client.get("/secret")
    assert response.status_code == 200
    
    html = response.get_data(as_text=True)
    assert "Error: El secreto no pudo ser leido!" in html 
