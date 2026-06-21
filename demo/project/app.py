"""
tiny-api — a minimal REST API for the ktask demo.
Deliberately has no logging, no error handling, no tests.
The demo will add these autonomously.
"""

from flask import Flask, jsonify, request

app = Flask(__name__)

users = {
    1: {"name": "Alice", "email": "alice@example.com", "role": "admin"},
    2: {"name": "Bob",   "email": "bob@example.com",   "role": "user"},
    3: {"name": "Carol", "email": "carol@example.com", "role": "user"},
}


@app.route("/api/users", methods=["GET"])
def list_users():
    return jsonify(list(users.values()))


@app.route("/api/users/<int:user_id>", methods=["GET"])
def get_user(user_id):
    user = users.get(user_id)
    if not user:
        return jsonify({"error": "not found"}), 404
    return jsonify(user)


@app.route("/api/users", methods=["POST"])
def create_user():
    data = request.get_json()
    new_id = max(users.keys()) + 1
    users[new_id] = data
    return jsonify({"id": new_id, **data}), 201


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    app.run(debug=True, port=5000)
