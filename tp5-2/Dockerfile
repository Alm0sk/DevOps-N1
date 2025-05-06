FROM python:3.13.3-alpine3.21

# Création de l'utilisateur qui executera l'application pour que ce ne soit pas root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Installation des dépendances depuis requirements.txt
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt && \
    rm -rf /root/.cache

# Copie du code source dans le conteneur
COPY app /app
WORKDIR /app

# Exposition du port 8000
EXPOSE 8000

# Passage de l'utilisateur root à appuser pour plus de sécurité
USER appuser

# Commande pour démarrer l'application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
