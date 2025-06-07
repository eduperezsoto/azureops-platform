FROM python:3.13-slim

# Working directory
WORKDIR /app

# Dependencies
COPY app/requirements.txt dev-requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt  -r dev-requirements.txt

# Copy only the app code
COPY app/ .

# Port exposure
EXPOSE 8000

# Default command
CMD ["gunicorn", "--bind=0.0.0.0:8000", "main:app"]
