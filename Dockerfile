# Use official Python 3.9 slim image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Avoid Python buffering logs
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for caching
COPY requirements.txt .

# Install dependencies
RUN pip install --upgrade pip
# Install PyTorch 2.1 CPU version + other packages
RUN pip install torch==2.1.0+cpu --index-url https://download.pytorch.org/whl/cpu
RUN pip install -r requirements.txt

# Copy application code
COPY . .

# Expose the port Render uses
ENV PORT=10000
EXPOSE $PORT

# Start Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:10000", "WebApp:app", "--workers", "1", "--threads", "4"]

