from flask import Flask, jsonify
import psycopg2

# Database connection details
DB_NAME = "omridb"
DB_USER = "omri"
DB_PASSWORD = "Hapoe_l6984"
DB_HOST = "10.2.0.4"
DB_PORT = 8080  # PostgreSQL default port

app = Flask(__name__)

try:
    connection = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
except Exception as e:
    raise Exception(f"Error connecting to the database: {e}")

cursor = connection.cursor()

@app.route("/")
def get_clients():
    try:
        cursor.execute("""SELECT * FROM clients""")
        clients = cursor.fetchall()
        return jsonify(clients)
    except Exception as e:
        return str(e), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=DB_PORT, debug=True)

