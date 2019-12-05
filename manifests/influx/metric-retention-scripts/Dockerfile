FROM python:3.8-alpine

RUN mkdir /app
WORKDIR /app
ADD . influxdb-size-based-metrics-retention.py
# RUN pip install -r requirements.txt

CMD ["python3", "/app/influxdb-size-based-metrics-retention.py"]