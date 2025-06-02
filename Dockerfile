FROM python:3.13-slim

# 1. Directorio de trabajo
WORKDIR /app

# 2. Dependencias
COPY app/requirements.txt dev-requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt  -r dev-requirements.txt

# 3. Copia solo el código de tu aplicación
COPY app/ .

# 4. Variables de entorno para Flask
ENV FLASK_APP=main.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=5000

# 5. Expón el puerto
EXPOSE 8000

# 6. Comando por defecto
CMD ["flask", "run"]
