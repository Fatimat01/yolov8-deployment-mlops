FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt ./
RUN pip install opencv-python
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install python-multipart
RUN apt-get update && apt-get install ffmpeg libsm6 libxext6  -y

COPY app ./app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# docker buildx build --platform linux/amd64,linux/arm64 -t atanda/yolov8-app:latest --push