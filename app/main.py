from fastapi import FastAPI, File, UploadFile, Request  # receive images
from fastapi.responses import HTMLResponse, StreamingResponse  # send HTML and images
from fastapi.templating import Jinja2Templates  # render HTML templates
from fastapi.staticfiles import StaticFiles  # serve static files
from ultralytics import YOLO
from PIL import Image
import io
import base64
import logging
import cv2

app = FastAPI()
model = YOLO("app/best.pt") # load trained model

templates = Jinja2Templates(directory="app/templates") # html templates
# serve static files (css, js, images)
app.mount("/static", StaticFiles(directory="app/static"), name="static")


# serves the HTML UI when a user visits /
@app.get("/", response_class=HTMLResponse)
# request is passed into the template so Jinja2 can use it if needed
# load the file app/templates/index.html
def home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

# serves the HTML UI when a user visits /predict

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    image = Image.open(io.BytesIO(await file.read()))
    results = model(image)[0]

    predictions = []
    for box in results.boxes:
        x1, y1, x2, y2 = box.xyxy[0].tolist()
        cls_id = int(box.cls[0])
        label = model.names[cls_id]
        conf = float(box.conf[0])
        predictions.append({
            "label": label,
            "confidence": conf,
            "box": [x1, y1, x2, y2]
        })
    return {"detections": predictions}


# set up logging
logging.basicConfig(level=logging.INFO)

# log when the server starts
@app.on_event("startup")
async def startup_event():
    logging.info("Server started")
#  log when the server stops
@app.on_event("shutdown")
async def shutdown_event():
    logging.info("Server stopped")
# log when the server receives a request
@app.middleware("http")
async def log_request(request: Request, call_next):
    logging.info(f"Request: {request.method} {request.url}")
    response = await call_next(request)
    logging.info(f"Response: {response.status_code}")
    return response
