from app import create_app


def test_dashboard_response():
    client = create_app().test_client()

    response = client.get("/")

    assert response.status_code == 200
    assert response.content_type.startswith("text/html")
    assert b"Your infrastructure" in response.data