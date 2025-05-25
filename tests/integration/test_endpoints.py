import os
import pytest
from app.main import app

@pytest.fixture
def client(monkeypatch):
    # Aseguramos que no hay KEY_VAULT_URI para simular entorno local
    monkeypatch.delenv("KEY_VAULT_URI", raising=False)
    return app.test_client()

def test_index_without_secret(client):
    resp = client.get("/")
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["message"] == "Hello, world!"
    assert data["secret_loaded"] is False
    assert data["secret_value"] is None

def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "healthy"}

def test_secret_route(client):
    resp = client.get("/secret")
    assert resp.status_code == 200
    data = resp.get_json()
    assert "secret_loaded" in data
    assert "secret_value" in data
    assert data["secret_loaded"] is False
    assert data["secret_value"] is None
