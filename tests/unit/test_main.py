import os
import pytest
from app.main import fetch_secret

class DummySecret:
    def __init__(self, value):
        self.value = value

class DummyClient:
    def __init__(self, vault_url, credential):
        pass
    def get_secret(self, name):
        return DummySecret("dummy-value")

@pytest.fixture(autouse=True)
def mock_azure(monkeypatch):
    # Simula KEY_VAULT_URI definido
    monkeypatch.setenv("KEY_VAULT_URI", "https://fake.vault.azure.net")
    # Sustituye DefaultAzureCredential y SecretClient
    monkeypatch.setattr("app.main.DefaultAzureCredential", lambda: None)
    monkeypatch.setattr("app.main.SecretClient", DummyClient)
    yield
    # Limpia después
    monkeypatch.delenv("KEY_VAULT_URI", raising=False)

# def test_fetch_secret_success():
#     loaded, value = fetch_secret("MY_SECRET")
#     assert loaded is True
#     assert value == "dummy-value"

def test_fetch_secret_no_uri(monkeypatch):
    # Si no hay URI, no intenta llamar al vault
    monkeypatch.delenv("KEY_VAULT_URI", raising=False)
    loaded, value = fetch_secret("MY_SECRET")
    assert loaded is False
    assert value is None
