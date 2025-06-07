# tests/unit/test_main.py
import pytest
import app.main as main_module
from app.main import fetch_secret


class DummySecret:
    def __init__(self, value):
        self.value = value


@pytest.fixture(autouse=True)
def clear_env_and_config():
    """
    Reset app.config["KEY_VAULT_URI"] and app.config["KEY_VAULT_URI"] to avoid interference between tests.
    """
    orig_kv = main_module.app.config.get("KEY_VAULT_URI", None)
    orig_client_id = main_module.app.config.get("AZURE_CLIENT_ID", None)

    yield

    # Restore KEY_VAULT_URI
    if orig_kv is not None:
        main_module.app.config["KEY_VAULT_URI"] = orig_kv
    else:
        main_module.app.config.pop("KEY_VAULT_URI", None)

    # Restore AZURE_CLIENT_ID
    if orig_client_id is not None:
        main_module.app.config["AZURE_CLIENT_ID"] = orig_client_id
    else:
        main_module.app.config.pop("AZURE_CLIENT_ID", None)


def test_fetch_secret_uri_not_configured(monkeypatch):
    """
    If KEY_VAULT_URI is empty or None, fetch_secret should return (False, None).
    """
    main_module.app.config["KEY_VAULT_URI"] = None

    ok, value = fetch_secret("any")
    assert ok is False
    assert value is None


def test_fetch_secret_get_secret_error(monkeypatch):
    """
    If SecretClient.get_secret raises an exception, fetch_secret should catch the error and return (False, None).
    """
    # Configure KEY_VAULT_URI and AZURE_CLIENT_ID so that they are not None
    main_module.app.config["KEY_VAULT_URI"] = "https://my-vault.vault.azure.net/"
    main_module.app.config["AZURE_CLIENT_ID"] = "my-client-id"

    # Patch ManagedIdentityCredential in app.main to return a dummy credential
    monkeypatch.setattr(
        main_module,
        "ManagedIdentityCredential",
        lambda client_id=None: "cred-dummy"
    )

    # Create a fake SecretClient that always raises on get_secret
    class FakeClient:
        def __init__(self, vault_url, credential):
            pass

        def get_secret(self, name):
            raise Exception("Forced error")

    # Patch SecretClient in app.main
    monkeypatch.setattr(main_module, "SecretClient", FakeClient)

    ok, val = fetch_secret("fail")
    assert ok is False
    assert val is None


def test_fetch_secret_success(monkeypatch):
    """
    If SecretClient.get_secret() succeeds, fetch_secret should return (True, secret.value).
    """
    # Configure KEY_VAULT_URI and the AZURE_CLIENT_ID environment variable
    main_module.app.config["KEY_VAULT_URI"] = "https://my-vault.vault.azure.net/"
    main_module.app.config["AZURE_CLIENT_ID"] = "my-client-id"

    # Patch ManagedIdentityCredential in app.main to return a dummy credential
    monkeypatch.setattr(
        main_module,
        "ManagedIdentityCredential",
        lambda client_id=None: "dummy-credential"
    )

    # Patch SecretClient in app.main
    def fake_init(self, vault_url, credential):
        assert vault_url == "https://my-vault.vault.azure.net/"
        assert credential == "dummy-credential"
        return None

    monkeypatch.setattr(main_module.SecretClient, "__init__", fake_init)
    monkeypatch.setattr(
        main_module.SecretClient,
        "get_secret",
        lambda self, name: DummySecret(f"value-of-{name}")
    )

    ok, val = fetch_secret("my-secret")
    assert ok is True
    assert val == "value-of-my-secret"
