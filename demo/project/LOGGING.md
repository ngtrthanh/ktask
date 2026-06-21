# Logging

This project uses JSON-formatted logging for HTTP requests.

## JSON Log Format

Each request produces a single JSON log entry with the following fields:

```json
{
  "timestamp": "2026-06-21T08:05:30",
  "method": "GET",
  "path": "/api/users",
  "status_code": 200,
  "duration_ms": 1.23
}
```

### Field Descriptions

| Field | Description |
|-------|-------------|
| `timestamp` | Request timestamp in ISO 8601 format (YYYY-MM-DDTHH:MM:SS) |
| `method` | HTTP method (GET, POST, PUT, DELETE, etc.) |
| `path` | Request path (e.g., `/api/users/1`) |
| `status_code` | HTTP response status code |
| `duration_ms` | Request duration in milliseconds (rounded to 2 decimal places) |

## Configuration

### Log Level

Set the `LOG_LEVEL` environment variable to change the log level:

```bash
export LOG_LEVEL=DEBUG    # for debug logging
export LOG_LEVEL=INFO     # for info logging (default)
export LOG_LEVEL=WARNING  # for warning logging
export LOG_LEVEL=ERROR    # for error logging
export LOG_LEVEL=CRITICAL # for critical logging
```

### Log Output Destination

By default, logs are written to `stdout`. To write to a file:

```bash
python app.py > app.log 2>&1
```

Or modify the handler in `app.py` to use `logging.FileHandler` instead of `logging.StreamHandler`.

## Default Behavior

- **Output**: `stdout`
- **Format**: JSON (one entry per line)
- **Logger name**: `request`
- **Log level**: `INFO`
