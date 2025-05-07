FROM python:3.13.3-alpine3.21

COPY requirements.txt /app/requirements.txt

# La bonne partiques est d'utiliser q'une seule commande RUN.
# Mais pour une meilleur lisibilité des étapes, je vais en utiliser plusieurs.  

# Installation des dépendances depuis requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt && \
    rm -rf /root/.cache

# Création de l'utilisateur qui executera l'application pour que ce ne soit pas root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Création du dossier de logs et attribution des droits à l'utilisateur appuser
RUN mkdir -p /logs && chown appuser:appgroup /logs
VOLUME ["/logs"]
    
# Copie du code source dans le conteneur
COPY app /app

EXPOSE 5000

# Variables d'environnement pour Flask
ENV FLASK_ENV=production

# Passage de l'utilisateur root à appuser pour plus de sécurité
USER appuser

CMD ["flask", "--app", "app", "run", "--host=0.0.0.0"]
