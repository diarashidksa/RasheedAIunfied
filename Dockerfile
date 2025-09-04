# Use official Python 3.9 image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements first
COPY requirements.txt .

# Upgrade pip
RUN pip install --upgrade pip

# Install all requirements except torch
RUN pip install --no-deps -r requirements.txt

# Install the correct PyTorch CPU version last to ensure compatibility
RUN pip install torch==2.1.0+cpu torchvision==0.16.0+cpu torchaudio==2.1.0+cpu \
    --index-url https://download.pytorch.org/whl/cpu

# Copy the rest of your application code
COPY . .

# Expose port
EXPOSE 10000

# Start Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:10000", "WebApp:app", "--workers", "1", "--threads", "4"]
