from fastapi.testclient import TestClient
#from app import app
from main import app

client = TestClient(app)

def test_health():
    r = client.get("/health")
    assert r.status_code in (200, 503)

