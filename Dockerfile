FROM python:3.11-slim 
# -- how do you pull custom image ? How to build an img, how to access it here?

WORKDIR app/

RUN apt-get update && apt-get install -y default-libmysqlclient-dev gcc

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
