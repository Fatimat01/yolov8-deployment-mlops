# YOLOv8 End-to-End Deployment (MLOps)

This project implements a production-grade MLOps pipeline for **real-time object detection** using [YOLOv8](https://github.com/ultralytics/ultralytics) with a **live stream inference** backend built in **FastAPI**, deployed on **AWS EKS**, and automated with **GitHub Actions**. It is designed with scalability, observability, and ML tracking in mind.

---

## Features

- **Live video stream inference** using YOLOv8
- FastAPI backend serving real-time detection output
- Dockerized and deployed to AWS EKS
- GitHub Actions CI/CD (build → push → deploy)
- Kubernetes-native monitoring (Prometheus, Grafana – in progress)
- MLflow tracking for model versioning & inference metrics (planned)
- Infrastructure-as-Code with Terraform

---

## Project Structure

```bash
.
├── app/                  # YOLOv8 + FastAPI live stream backend
│   ├── best.pt
│   ├── main.py
│   ├── static/live.js
│   └── templates/index.html
├── Dockerfile            # Container build instructions
├── infra/                # Infra + Kubernetes configuration
│   ├── Argo-Apps/
│   │   └── prometheus-stack-app.yaml
│   ├── config/           # Key K8s YAMLs used:
│   │   ├── yolov8.yaml
│   │   ├── yolov8-service.yaml
│   │   ├── prometheus-cr.yaml
│   │   └── alert-rules.yaml
│   ├── module/           # Terraform modules (EKS, ALB, IAM, etc.)
│   │   ├── alb.tf
│   │   ├── iam.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   │   └── outputs.tf
├── requirements.txt      # Python dependencies
└── .github/workflows/    # CI/CD and automation pipelines

---

## Local Development

```bash
buildx build --platform linux/amd64,linux/arm64 -t repo-name/yolov8:latest --push .
docker run -p 8000:8000 repo-name/yolov8:latest
# --platform is to allow the image run on multi-platform especially if the build will be on mac
# Then open: http://localhost:8000/
```


---

## Production Deployment via GitHub Actions

1. Create a GitHub repository
2. Add secrets:
   - `DOCKER_USERNAME`, `DOCKER_PASSWORD`
   - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

3. Push to `main` → GitHub Actions will:
   - Build and push the Docker image to DockerHub
   - Deploy it to your EKS cluster
   - Update the running container with the new image

---


## 📈 Monitoring & Model Tracking (Planned)

### Monitoring (in progress):
- Prometheus Operator (via `prometheus-cr.yaml`)
- Grafana dashboards
- Custom alerts (`alert-rules.yaml`)

### Model Tracking (next step):
- MLflow integration for:
  - Model versioning
  - Inference time tracking
  - Image/frame logging
  - Deployment stage/version association

---

## Roadmap

- [x] Deploy YOLOv8 FastAPI app on EKS
- [x] GitHub Actions CI/CD pipeline
- [ ] Integrate Prometheus and Grafana for observability
- [ ] Add MLflow model tracking
- [ ] ArgoCD GitOps auto-sync
- [ ] Add logging/alerting to Slack or email

---

## Credits

- [Ultralytics YOLOv8](https://github.com/ultralytics/ultralytics)
- [FastAPI](https://fastapi.tiangolo.com/)
- [Prometheus Operator](https://github.com/prometheus-operator)
- [MLflow](https://mlflow.org/)
- [Kubernetes](https://kubernetes.io/)
- [Terraform](https://www.terraform.io/)

---