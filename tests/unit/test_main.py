# tests/unit/test_main.py
import os
import pytest
import app.main as main_module
from app.main import fetch_secret


class DummySecret:
    def __init__(self, value):
        self.value = value


@pytest.fixture(autouse=True)
def clear_env_and_config():
    """
    Antes de cada test, reseteamos app.config["KEY_VAULT_URI"] y la variable de entorno AZURE_CLIENT_ID
    para evitar interferencias entre tests.
    """
    orig_kv = main_module.app.config.get("KEY_VAULT_URI", None)
    orig_client_id = os.environ.get("AZURE_CLIENT_ID", None)

    yield

    # Restauramos KEY_VAULT_URI
    if orig_kv is not None:
        main_module.app.config["KEY_VAULT_URI"] = orig_kv
    else:
        main_module.app.config.pop("KEY_VAULT_URI", None)

    # Restauramos AZURE_CLIENT_ID
    if orig_client_id is not None:
        os.environ["AZURE_CLIENT_ID"] = orig_client_id
    else:
        os.environ.pop("AZURE_CLIENT_ID", None)


def test_fetch_secret_uri_no_configurado(monkeypatch):
    """
    Si KEY_VAULT_URI está vacío o None, fetch_secret debe devolver (False, None).
    """
    main_module.app.config["KEY_VAULT_URI"] = None

    ok, value = fetch_secret("cualquier")
    assert ok is False
    assert value is None


def test_fetch_secret_error_en_get_secret(monkeypatch):
    """
    Si SecretClient.get_secret lanza excepción, fetch_secret atrapa el error y devuelve (False, None).
    """
    # Configuramos KEY_VAULT_URI para que no sea None
    main_module.app.config["KEY_VAULT_URI"] = "https://mi-vault.vault.azure.net/"
    os.environ["AZURE_CLIENT_ID"] = "mi-client-id"

    # Parcheamos ManagedIdentityCredential dentro de app.main para que devuelva un "dummy-credential"
    monkeypatch.setattr(
        main_module,
        "ManagedIdentityCredential",
        lambda client_id=None: "cred-dummy"
    )

    # Creamos un SecretClient simulado que siempre lanza excepción en get_secret
    class FakeClient:
        def __init__(self, vault_url, credential):
            pass

        def get_secret(self, name):
            raise Exception("error forzado")

    # Parcheamos SecretClient dentro de app.main
    monkeypatch.setattr(main_module, "SecretClient", FakeClient)

    ok, val = fetch_secret("fail")
    assert ok is False
    assert val is None


def test_fetch_secret_exito(monkeypatch):
    """
    Si SecretClient.get_secret() funciona, fetch_secret debe devolver (True, secret.value).
    """
    # Configuramos KEY_VAULT_URI y la variable de entorno AZURE_CLIENT_ID
    main_module.app.config["KEY_VAULT_URI"] = "https://mi-vault.vault.azure.net/"
    os.environ["AZURE_CLIENT_ID"] = "mi-client-id"

    # Parcheamos ManagedIdentityCredential dentro de app.main para que devuelva "dummy-credential"
    monkeypatch.setattr(
        main_module,
        "ManagedIdentityCredential",
        lambda client_id=None: "dummy-credential"
    )

    # Parcheamos SecretClient dentro de app.main
    def fake_init(self, vault_url, credential):
        assert vault_url == "https://mi-vault.vault.azure.net/"
        assert credential == "dummy-credential"
        return None

    monkeypatch.setattr(main_module.SecretClient, "__init__", fake_init)
    monkeypatch.setattr(
        main_module.SecretClient,
        "get_secret",
        lambda self, name: DummySecret(f"valor-de-{name}")
    )

    ok, val = fetch_secret("mi-secreto")
    assert ok is True
    assert val == "valor-de-mi-secreto"
