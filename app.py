from flask import Flask
import mysql.connector

app = Flask(__name__)

@app.route("/")
def home():
    try:
        conn = mysql.connector.connect(
            host="my-python-db.cdska6wmq49g.us-east-2.rds.amazonaws.com",
            user="User1",
            password="Admin123",
            database="myappdb"
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
