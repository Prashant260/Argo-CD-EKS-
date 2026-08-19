from app import create_app


def test_hello_world_response():
    client = create_app().test_client()

    response = client.get("/")

    assert response.status_code == 200
    assert response.get_json()["message"] == "Hello World from EKS GitOps"


def test_health_and_readiness():
    client = create_app().test_client()

    assert client.get("/healthz").status_code == 200
    assert client.get("/readyz").get_json() == {"status": "ready"}
