##FROM python:3.11-slim
FROM docker.arvancloud.ir/python:3.8-slim-buster

WORKDIR /app

COPY . .

RUN pip3 install --no-cache-dir -r requirements.txt

#EXPOSE 5000

#CMD ["python", "app.py"]
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0"]
