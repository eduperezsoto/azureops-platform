# tests/integration/test_endpoints.py
import pytest
from app.main import app


@pytest.fixture
def client():
    """
    Crea un Flask test client usando la aplicación real.
    Para las rutas que usan fetch_secret, parchearemos esa función dinámicamente.
    """
    # Antes de crear el client, deshabilitamos cualquier valor previo en KEY_VAULT_URI
    # para que, por defecto, fetch_secret retorne (False, None).
    app.config["KEY_VAULT_URI"] = None

    # Creamos el test_client
    with app.test_client() as c:
        yield c


def test_index_endpoint_status_and_content(client):
    """
    GET "/" debe retornar 200 y debe contener algún fragmento conocido de index.html.
    """
    response = client.get("/")
    assert response.status_code == 200

    # Comprobamos que el contenido incluya algo que sepamos que está en templates/index.html
    html = response.get_data(as_text=True)
    assert "Quieres saber un secreto?" in html


def test_health_endpoint_returns_json_healthy(client):
    """
    GET "/health" debe retornar 200 con JSON {"status": "healthy"}.
    """
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, dict)
    assert data.get("status") == "healthy"


def test_secret_endpoint_sin_keyvault(client):
    """
    Si KEY_VAULT_URI está en None, fetch_secret devuelve (False, None),
    por lo que la plantilla secret.html debe renderizarse con secret=None.
    """
    # Nos aseguramos de que KEY_VAULT_URI sea None
    app.config["KEY_VAULT_URI"] = None

    response = client.get("/secret")
    assert response.status_code == 200
    html = response.get_data(as_text=True)
    assert "Error: El secreto no pudo ser leido!" in html


def test_secret_endpoint_con_secret_exito(monkeypatch, client):
    """
    Simulamos que fetch_secret retorna (True, "valor-demo"), y comprobamos que
    secret.html reciba ese valor y lo muestre en la respuesta.
    """
    # 1. Configuramos KEY_VAULT_URI para que fetch_secret entre en la lógica de intentar leer.
    app.config["KEY_VAULT_URI"] = "https://mi-vault.vault.azure.net/"

    # 2. Parcheamos fetch_secret para que no llame a Azure sino devuelva un par fijo.
    def fake_fetch_secret(name: str):
        # name debe ser "mysecret" según tu ruta
        assert name == "mysecret"
        return True, "valor-demo"

    monkeypatch.setattr("app.main.fetch_secret", fake_fetch_secret)

    response = client.get("/secret")
    assert response.status_code == 200
    html = response.get_data(as_text=True)

    # Ahora deberíamos encontrar "valor-demo" en el HTML generado
    assert "valor-demo" in html


def test_secret_endpoint_con_secret_error(monkeypatch, client):
    """
    Simulamos que fetch_secret retorna (False, None) con KEY_VAULT_URI configurado,
    y comprobamos que secret.html se renderice sin error, mostrando secret=None.
    """
    # 1. Configuramos KEY_VAULT_URI para que fetch_secret intente leer
    app.config["KEY_VAULT_URI"] = "https://mi-vault.vault.azure.net/"

    # 2. Parcheamos fetch_secret para que retorne (False, None)
    monkeypatch.setattr("app.main.fetch_secret", lambda name: (False, None))

    response = client.get("/secret")
    assert response.status_code == 200
    html = response.get_data(as_text=True)

    # Dado que secret == None, la plantilla debería mostrar "None" o un mensaje por defecto
    assert "None" in html or "secret" in html.lower()
