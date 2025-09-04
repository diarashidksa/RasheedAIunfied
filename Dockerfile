# Use slim Python image for smaller size
FROM python:3.9-slim

# Prevent Python from buffering stdout/stderr and writing pyc files
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies (needed for pandas, PyTorch, etc.)
RUN apt-get update && apt-get install -y \
    build-essential \
    libopenblas-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source
COPY . .

# Expose for documentation (Render overrides this with $PORT)
EXPOSE 5000

# Run with Gunicorn, binding to Render's $PORT
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT} WebApp:app"]
