from flask import Flask
import mysql.connector
import boto3
import json
import os
app = Flask(__name__)

def get_db_credentials():
    session = boto3.session.Session()
    client = session.client("secretsmanager", region_name=os.environ.get("AWS_REGION", "us-east-2"))
    response = client.get_secret_value(SecretId="arn:aws:secretsmanager:us-east-2:418272754287:secret:myapp-db-credentials-z2by6s")
    return json.loads(response["SecretString"])

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
