# Use official Python base image
FROM python:3.9-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip setuptools wheel

# Install PyTorch 2.1+ and GPU dependencies (adjust for CPU/GPU)
# For CPU-only:
RUN pip install torch==2.1.0+cpu torchvision==0.16.0+cpu torchaudio==2.1.0+cpu \
    --index-url https://download.pytorch.org/whl/cpu

# If using CUDA 12.1 GPU, comment above and use:
# RUN pip install torch==2.1.0+cu121 torchvision==0.16.0+cu121 torchaudio==2.1.0+cu121 \
#     --index-url https://download.pytorch.org/whl/cu121

# Install remaining Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy app code
COPY . /app
WORKDIR /app

# Expose port
EXPOSE 10000

# Start Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:10000", "WebApp:app", "--workers", "1", "--threads", "4"]

