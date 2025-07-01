from flask import Flask
import mysql.connector
import json
import os

app = Flask(__name__)

def get_db_credentials():
    try:
        secret_str = os.environ.get("DB_SECRET")
        if not secret_str:
            raise Exception("Environment variable 'DB_SECRET' not found")

        creds = json.loads(secret_str)
        print("Secret fetched from env var")
        return creds

    except Exception as e:
        print("Error fetching secret:", e)
        raise
    
@app.route("/")
def home():
    try:
        creds = get_db_credentials()

        conn = mysql.connector.connect(
            host=creds['host'],
            user=creds['username'],
            password=creds['password'],
            database=creds['database']
        )
        cursor = conn.cursor()
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS greetings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            message VARCHAR(255)
        );
        """)
        cursor.execute("INSERT INTO greetings (message) VALUES ('terraformmm!');")
        conn.commit()

        cursor.execute("SELECT id, message FROM greetings;")
        rows = cursor.fetchall()
        conn.close()

        html = "<h2>Hello from Database</h2><ul>"
        for row in rows:
            html += f"<li>ID: {row[0]}, Message: {row[1]}</li>"
        html += "</ul>"

        return html

    except Exception as e:
        return f"<h3>ERROR: {e}</h3>", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
