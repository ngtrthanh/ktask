import json
import logging
from io import StringIO

import pytest

from app import app


@pytest.fixture
def client():
    app.testing = True
    return app.test_client()


@pytest.fixture
def log_capture():
    """Capture JSON log output to a string buffer."""
    log_stream = StringIO()
    handler = logging.StreamHandler(log_stream)
    handler.setFormatter(
        logging.Formatter('%(message)s')
    )
    logger = logging.getLogger("request")
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    original_propagate = logger.propagate
    logger.propagate = False
    
    yield log_stream
    
    logger.removeHandler(handler)
    logger.propagate = original_propagate


def test_get_users_logs_json_entry(client, log_capture):
    """Test that a successful GET request produces a valid JSON log entry."""
    response = client.get("/api/users")
    assert response.status_code == 200
    
    log_output = log_capture.getvalue().strip()
    log_entry = json.loads(log_output)
    
    assert log_entry["method"] == "GET"
    assert log_entry["path"] == "/api/users"
    assert log_entry["status_code"] == 200
    assert "duration_ms" in log_entry
    assert isinstance(log_entry["duration_ms"], (int, float))
    assert "timestamp" in log_entry


def test_get_user_not_found_logs_json_entry(client, log_capture):
    """Test that a 404 error produces a valid JSON log entry."""
    response = client.get("/api/users/999")
    assert response.status_code == 404
    
    log_output = log_capture.getvalue().strip()
    log_entry = json.loads(log_output)
    
    assert log_entry["method"] == "GET"
    assert log_entry["path"] == "/api/users/999"
    assert log_entry["status_code"] == 404
    assert "duration_ms" in log_entry
    assert "timestamp" in log_entry


def test_create_user_logs_json_entry(client, log_capture):
    """Test that a successful POST request produces a valid JSON log entry."""
    response = client.post(
        "/api/users",
        data=json.dumps({"name": "Dave", "email": "dave@example.com", "role": "user"}),
        content_type="application/json"
    )
    assert response.status_code == 201
    
    log_output = log_capture.getvalue().strip()
    log_entry = json.loads(log_output)
    
    assert log_entry["method"] == "POST"
    assert log_entry["path"] == "/api/users"
    assert log_entry["status_code"] == 201
    assert "duration_ms" in log_entry
    assert "timestamp" in log_entry
