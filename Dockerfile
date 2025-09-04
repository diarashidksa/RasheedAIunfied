# Use Python 3.9 slim base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies for PyTorch and faiss
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libopenblas-dev \
    libomp-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first for caching
COPY requirements.txt .

# Install Python dependencies (CPU-only PyTorch)
RUN pip install --no-cache-dir -r requirements.txt -f https://download.pytorch.org/whl/cpu

# Copy the rest of the app code
COPY . .

# Expose the port for Gunicorn
EXPOSE 8000

# Run the app with Gunicorn
CMD ["gunicorn", "WebApp:app", "--bind", "0.0.0.0:8000", "--workers", "1", "--timeout", "120"]

