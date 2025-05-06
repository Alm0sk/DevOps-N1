# TP cours de DevOps

<br>

## Sommaire

- [TP cours de DevOps](#tp-cours-de-devops)
  - [TP 5](#tp-5)
  - [TP 5-2](#tp-5-2)
  - [TP 6](#tp-6)
  - [TP 7](#tp-7)
  - [TP 8](#tp-8)

<br>


## TP 5

**Objectif** : d&ployer une application multiconteneurs

Mise en place d'un grafana avec un prometheus :

[Dockerfile](tp5/docker-compose.yml)

```yaml
services:
  grafana:
    image: grafana/grafana-enterprise
    container_name: grafana
    restart: unless-stopped
    user: '0'
    ports:
     - '3000:3000'
    volumes:
     - 'data:/var/lib/grafana'
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    restart: unless-stopped
    ports:
     - '9090:9090'
    volumes:
     - 'data:/prometheus'
volumes:
  data: {}
```

Puis lancement de l'application :

```bash
docker-compose up -d
```
On peut ensuite se connecter sur le port 3000 pour grafana et sur le port 9090 pour prometheus.

![lancement de l'application](media/TP5-launch.png)

![Accès au URL](media/TP5-final.png)

<br>

## TP 5-2

*En relisant l'énoncé j'ai l'impression qu'il étais attendu d'appeler un un code avec docker*

J'ai donc mis en place une application simple en python fastapi qui renvoie un "Hello World" sur le port 8000

[Dockerfile](tp5-2/Dockerfile)

```dockerfile
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
```

Je peux maintenant construire l'image, la lancer et vérifié que les appels API fonctionnent

```bash
docker build -t fastapi-app .
```
```bash
docker run -p 8000:8000 -d --name fastapi_app fastapi
```
```bash
curl http://localhost:8000/
````

```bash
docker logs fastapi_app
```

![Lancement de l'app](media/TP5-2-launch.png)

<br>

## TP 6

**Objectif**  : Deployer une application multi conteneur wordpress et nginx

J'ai mis en place un docker-compose.yml en prenant exemple sur la documentation docker hub
<https://hub.docker.com/_/wordpress>

[Dockerfile](tp6/docker-compose.yml)

```yaml
services:

  wordpress:
    image: wordpress:latest
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: user
      WORDPRESS_DB_PASSWORD: pass
      WORDPRESS_DB_NAME: database
    volumes:
      - wordpress:/var/www/html

  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_DATABASE: database
      MYSQL_USER: user
      MYSQL_PASSWORD: pass
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db:
```

Puis lancement de l'application :

```bash
docker-compose up -d
```

On peux ensuite se connecter au wordpress sur le port 8080

![Lancement des containeurs](media/TP6-launch.png)

![alt text](media/TP6-final.png)

<br>

## TP 7

**Objectif** : Déployer un conteneur de base de données et sécurisé ces données

J'ai mis en place un docker-compose.yml en prenant exemple sur la documentation docker hub de mysql
<https://hub.docker.com/_/mysql> avec une utilisation de secrets docker pour stocker les mots de passes

[Dockerfile](tp7/docker-compose.yml)

```yaml
services:
  db:
    image: mysql:8.0
    container_name: mysql_db
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
      MYSQL_PASSWORD_FILE: /run/secrets/mysql_user_password
      MYSQL_DATABASE: database
      MYSQL_USER: user
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - db_network
    restart: unless-stopped
    secrets:
      - mysql_root_password
      - mysql_user_password

volumes:
  db_data:

networks:
  db_network:

secrets:
  mysql_root_password:
    external: true
  mysql_user_password:
    external: true
```

Et j'ai mis en place les secrets avec docker swarm:

```bash
docker swarm init
```

```bash
echo "IncroyableMDP" | docker secret create mysql_root_password -
```

```bash
echo "BasiqueMDP" | docker secret create mysql_user_password -
```

On peux vérifier que les secrets sont bien créés avec la commande suivante :

```bash
docker secret ls
```

Et enfin on peut lancer l'application :

```bash
docker stack deploy -c docker-compose.yml mysql_tp7
```

On pourrait pousser les bonnes pratiques en mettant en place un vault pour stocker les secrets couplé avec ansible. Mais le TP n'a pas l'air de demander ça, et doit durer 15 minutes.

Et pour verifier que tout fonctionne, on peux ce connecter où verifier les logs du conteneur :

```bash
docker exec -it mysql_tp7_db mysql -u root -p
```

```bash
docker logs mysql_tp7_db
```
<br>

## TP 8

**Objectif** : Déployer un conteneur de base de données et
sécurisé ces données (avec un .env)

J'ai mis en place un docker-compose.yml en prenant exemple sur la documentation docker hub de mysql
<https://hub.docker.com/_/mysql>
[Dockerfile](tp8/docker-compose.yml)

```yaml
services:
  db:
    image: mysql:8.0
    container_name: mysql_db
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - db_network
    restart: unless-stopped

volumes:
  db_data:

networks:
  db_network:
```

J'ai également mis en place un fichier .env pour stocker les variables d'environnement

[fichier .env](tp8/.env)

```bash
# Je laisse le fichier dans le repo, mais c'est une mauvaise pratique de le faire habituellement.
MYSQL_ROOT_PASSWORD=rootpass
MYSQL_DATABASE=database
MYSQL_USER=user
MYSQL_PASSWORD=sqlpass
```

Puis lancement de l'application :

```bash
docker-compose up -d
```

![Lancement de l'app](media/TP8-launch.png)

On peux ensuite se connecter à la base de données avec le client mysql

```bash
docker exec -it mysql_db mysql -u root -p
```

![Connexion à la base de donnée](media/TP8-final.png)