# Use official Python 3.9 slim image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements.txt
COPY requirements.txt .

# Uninstall any old PyTorch just in case
RUN pip uninstall -y torch torchvision torchaudio || true

# Install PyTorch 2.1 CPU version (adjust if you have GPU/CUDA)
RUN pip install torch==2.1.0+cpu torchvision==0.16.0+cpu torchaudio==2.1.0+cpu \
    --index-url https://download.pytorch.org/whl/cpu

# Install remaining Python dependencies
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy app code
COPY . .

# Expose port
EXPOSE 10000

# Start Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:10000", "WebApp:app", "--workers", "1", "--threads", "4"]


