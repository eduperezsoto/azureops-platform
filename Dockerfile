FROM python:3.13-slim

# 1. Directorio de trabajo
WORKDIR /app

# 2. Dependencias
COPY app/requirements.txt dev-requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt  -r dev-requirements.txt

# 3. Copia solo el código de tu aplicación
COPY app/ .

# 4. Expón el puerto
EXPOSE 8000

# 5. Comando por defecto
CMD ["gunicorn", "--bind=0.0.0.0:8000", "main:app"]
