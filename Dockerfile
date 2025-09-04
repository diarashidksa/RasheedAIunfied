# Base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt .

# Install PyTorch 2.1 CPU wheel and dependencies
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir torch==2.1.0+cpu --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY . .

# Expose the port Render expects
ENV PORT=10000
EXPOSE 10000

# Start the Gunicorn server
CMD ["gunicorn", "--bind", "0.0.0.0:10000", "WebApp:app"]
