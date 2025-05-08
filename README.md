# TP cours de DevOps

<br>

## Sommaire

- [TP cours de DevOps](#tp-cours-de-devops)
  - [Introduction](#introduction)
  - [TP 5](#tp-5)
  - [TP 5-2](#tp-5-2)
  - [TP 6](#tp-6)
  - [TP 7](#tp-7)
  - [TP 8](#tp-8)
  - [TP 9](#tp-9)
    - [TP 9-1 Dockerfile basique](#tp-9-1-dockerfile-basique)
    - [TP 9-2 Dockerfile avec gestion des fichiers et métadonnées](#tp-9-2-dockerfile-avec-gestion-des-fichiers-et-métadonnées)
    - [TP 9-3 Dockerfile avec environnement et persistance](#tp-9-3-dockerfile-avec-environnement-et-persistance)
  - [TP 10](#tp-10)
    - [TP 10-1 Créer une machine virtuelle azure](#tp-10-1-créer-une-machine-virtuelle-azure)
    - [TP 10-2 Héberger un site web statique sur Azure Storage](#tp-10-2-héberger-un-site-web-statique-sur-azure-storage)
    - [TP 10-3 Connecter deux réseaux virtuels avec peering](#tp-10-3-connecter-deux-réseaux-virtuels-avec-peering)
  - [TP 11](#tp-11)



<br>


## Introduction

Chaque partie est lié à un TP d'on les fichiers sont dans le dossier `tpX` correspondant <br>

Les différents codes sont prévus pour être lancé dans un terminal Linux ou WSL2 dans le repertoire du TP correspondant.

Les commandes sont prévu pour fonctionner sur un OS ArchLinux. Je ne pense pas qu'il y ai des différences avec les autres distributions, mais je le précise au cas où.

Mon utilisateur fais partie du groupe docker, donc je n'ai pas besoin de rajouter `sudo` devant les commandes docker. je ne le précise pas dans les commandes.


## TP 5

**Objectif** : déployer une application multiconteneurs

#### Mise en place

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

#### lancement de l'application

```bash
docker-compose up -d
```

pour l'arrêter :

```bash
docker-compose down
```

pour le supprimer :

```bash
docker rmi grafana/grafana-enterprise:latest prom/prometheus:latest && \
docker volume rm tp5_data
```

#### Démonstration

On peut ensuite se connecter sur le port 3000 pour grafana et sur le port 9090 pour prometheus.

![lancement de l'application](media/TP5-launch.png)

![Accès au URL](media/TP5-final.png)

<br>

## TP 5-2

*En relisant l'énoncé j'ai l'impression qu'il était attendu d'appeler un code local avec docker*

#### Mise en place

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

#### Lancement de l'application

Je peux maintenant construire l'image, la lancer et vérifier que les appels API fonctionnent

```bash
docker build -t fastapi-img .
```
```bash
docker run -p 8000:8000 -d --name fastapi-app fastapi-img
```
```bash
curl http://localhost:8000/
````

Affichage des logs de l'application :

```bash
docker logs fastapi-app
```

Pour l'arrêter :

```bash
docker stop fastapi-app
```

Pour le supprimer :

```bash
docker rm fastapi-app && docker rmi fastapi-app
```

#### Démonstration

![Lancement de l'app](media/TP5-2-launch.png)

<br>

## TP 6

**Objectif**  : Deployer une application multi conteneur wordpress et nginx

#### Mise en place

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

#### Lancement de l'application

```bash
docker-compose up -d
```

pour l'arrêter :

```bash
docker-compose down
```

pour le supprimer :

```bash
docker volume rm tp6_db tp6_wordpress
```

#### Démonstration

On peux ensuite se connecter au wordpress sur le port 8080

![Lancement des containeurs](media/TP6-launch.png)

![Résultat](media/TP6-final.png)

<br>

## TP 7

**Objectif** : Déployer un conteneur de base de données et sécurisé ces données

#### Mise en place

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

#### Lancement de l'application

J'ai mis en place les secrets avec docker swarm:

```bash
docker swarm init
```

*Il peut être nécéssaire de spécifier l'adresse IP avec l'option :* `--advertise-addr`

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

Pour verifier que tout fonctionne, on peux ce connecter :

```bash
docker exec -it mysql_tp7_db.1.<Identifiant_swarm> mysql -u root -p
```

*la touche Tab pour réccupérer l'ID swarm rapidement*

où verifier les logs du conteneur :

```bash
docker logs mysql_tp7_db
```

pour l'arrêter :

```bash
docker stack rm mysql_tp7
```
pour supprimer les secrets :

```bash
docker secret rm mysql_root_password && docker secret rm mysql_user_password
```

```bash
docker swarm leave --force
```

```bash
docker volume rm mysql_tp7_db_data
```

#### Remarque

- On pourrait pousser les bonnes pratiques en mettant en place un vault pour stocker les secrets couplé avec ansible. Mais le TP n'a pas l'air de demander ça, et doit durer 15 minutes.

- L'application est très basique, le but étais de tester la mise en place de secrets docker

#### Démonstration

![Lancement](media/TP7-launch.png)

<br>

## TP 8

**Objectif** : Déployer un conteneur de base de données et
sécurisé ces données (avec un .env)

#### Mise en place

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

#### Lancement de l'application


```bash
docker-compose up -d
```

pour l'arrêter :

```bash
docker-compose down
```

pour le supprimer :

```bash
docker rmi mysql:8.0 && docker volume rm tp8_db_data
```

#### Démonstration

![Lancement de l'app](media/TP8-launch.png)

On peux ensuite se connecter à la base de données avec le client mysql

```bash
docker exec -it mysql_db mysql -u root -p
```

![Connexion à la base de donnée](media/TP8-final.png)

<br>

## TP 9

**Objectif** : Plusieurs Dockerfile à mettre en place

<hr>

### TP 9-1 Dockerfile basique

**Objectif** : Créer un Dockerfile basique d'un nginx sur une image ubuntu

#### Mise en place
J'ai mis en place un dockerfile basique d'un nginx sur une image ubuntu<br>
*Je n'ai pas mis de docker-compose.yml pour un seul conteneur*

[Dockerfile](tp9/tp9-1/Dockerfile)

```dockerfile

```yaml
FROM ubuntu:latest

# Installation de nginx
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean

# Expose port 80
EXPOSE 80

# Start
CMD ["nginx", "-g", "daemon off;"]
```

#### Lancement de l'application


```bash
docker build -t tp9-1 .
```

Et pour lancer le conteneur :

```bash
docker run -d -p 80:80 --name tp9-1-app tp9-1
```

Pour l'arrêter :

```bash
docker stop tp9-1-app
```

Pour le supprimer :

```bash
docker rm tp9-1-app && docker rmi tp9-1
```

#### Démonstration

Après ça on peux se connecter.

![Lancement](media/TP9-1-final.png)

<hr>

### TP 9-2 Dockerfile avec gestion des fichiers et métadonnées

**Objectif** : Ajouter des la complxité avec une base web

#### Mise en place

[Dockerfile](tp9/tp9-2/Dockerfile)

```dockerfile
FROM ubuntu:latest

# Quelques métadonnées
LABEL maintainer="Alvin <alvinkita@edu.igencia.com>"
LABEL description="Application pour TP9-2"
LABEL version="0.1"

# Installation de nginx
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean

# Création du dossier de travail
WORKDIR /var/www/html

# Copie des fichiers de l'application
COPY webapp/ .

# Expose port 80
EXPOSE 80

# Start
CMD ["nginx", "-g", "daemon off;"]
```

avec un dossier webapp contenant un index.html avec un page (très) simple

#### Lancement de l'application

```bash

pour lancer l'application :

```bash
docker build -t tp9-2 .
```

```bash
docker run -d -p 80:80 --name tp9-2-app tp9-2
```

Pour l'arrêter :

```bash
docker stop tp9-2-app
```

Pour le supprimer :

```bash
docker rm tp9-2-app && docker rmi tp9-2
```

#### Démonstration

Le résultat ci dessous avec un test curl :

![Lancement de l'application](media/TP9-2-launch.png)

<hr>

### TP 9-3 Dockerfile avec environnement et persistance

**Objectif** : Déployer une application Python Flask utilisant une variable d'environnement pour sa configuration, avec un dossier pour la persistance des logs

*Réalisé à l'aide de la documentation de Flask :* https://flask.palletsprojects.com/en/stable/quickstart/#a-minimal-application

#### Mise en place

Le code est découpé en plusieurs fichiers : <br>
![arbre des fichier](media/TP9-3-tree.png)

- La racine du projet contenant les fichier de configuration de docker

[Dockerfile](tp9/tp9-3/Dockerfile)
```dockerfile
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
```
[requirements.txt](tp9/tp9-3/requirements.txt)
```text
flask
```

[.env](tp9/tp9-3/.env)
```text
# Je laisse le fichier dans le repo, mais c'est une mauvaise pratique de le faire habituellement.
FLASK_SECRET_KEY=Ma_cle_super_secrete
```

[docker-compose.yml](tp9/tp9-3/docker-compose.yml)
```yaml
services:
  flask:
    build: .
    ports:
      - "5000:5000"
    env_file:
      - .env
    volumes:
      - ./logs:/logs
```

<br>

- Le dossier app contenant le code de l'application flask

[app.py](tp9/tp9-3/app/__init__.py)
```python
import os
import logging
from flask import Flask

logging.basicConfig(filename='/logs/app.log', level=logging.INFO)

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('FLASK_SECRET_KEY', 'defaultkey')

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"

```

<br>

- Le dossier logs contenant les logs du volume persistant de l'application

[logs](tp9/tp9-3/logs/app.log)

*A noter que au premier lancement de l'application j'ai eu une erreur :*<br> `flask-1  | PermissionError: [Errno 13] Permission denied: '/logs/app.log'`

*Que j'ai corriger modifiant les droits d'acces au dossier des logs :*
```bash
sudo chmod 777 logs
```

#### Lancement de l'application

```bash
docker-compose up -d
```
Pour l'arrêter :
```bash
docker-compose down
```

Pour le supprimer :
```bash
docker rmi tp9-3-flask
```

#### Démonstration

![Démonstration de l'application](media/TP9-3-final.png)

- Au lancement de m'application on a bien le conteneur de logs qui est monté

- Et en consultant le fichier des logs on retrouve les logs actuel, et du lancement précédent

<br>

## TP 10

**Objectif** : Manipuler Azure

*Je vais profiter de cet exercice pour utiliser Terraform pour le déploiement*

### Pré-requis

- Terraform
- Azure CLI

Authentification avec Azure CLI
*Je me suis appuyé sur la documentation terraform :* https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli

```bash
az login
```
Une fois connecté, on peux vérifier que l'on est bien authentifié avec la commande suivante :

```bash
az account list
```

![az connetion](media/TP10-az-login.png)

<br>

### TP 10-1 Créer une machine virtuelle azure

#### Mise en place

Je me suis appuyé sur la documentation Azure très complète pour mettre en place la configuration de la machine virtuelle :<br> https://learn.microsoft.com/fr-fr/azure/virtual-machines/linux/quick-create-terraform?tabs=azure-cli<br>
*J'ai changé le nom de la machine virtuelle, le type de stockage qui ne fonctionnait pas, et la localisation pour mettre la France. Ainsi que quelques variables de confort comme le nom d'utilisateur, où l'ajout de la clé ssh directement dans les fichier locaux du PC pour pouvoir acceder à la VM depuis mon PC sans manipulations supplémentaire.*

Il y'a plusieurs fichers pour la configuration qui sont les suivants :

- [main.tf](tp10/tp10-1/main.tf)<br>
  On retrouve la configuration de la machine virtuelle dans la ressource : `azurerm_linux_virtual_machine" "my_terraform_vm`

- [variables.tf](tp10/tp10-1/variables.tf)
- [outputs.tf](tp10/tp10-1/outputs.tf)
- [ssh.tf](tp10/tp10-1/ssh.tf)
- [provider.tf](tp10/tp10-1/provider.tf)

Tous accessible dans le dossier [tp10/tp10-1](tp10/tp10-1)

#### Lancement de l'application

Initialisation de terraform

```bash
terraform init -upgrade
```

Mise en forme de la configuration

```bash
terraform fmt
```

verification de la configuration pendant le developpement

```bash
terraform plan
```

Une fois que tout est bon, on peux lancer la création de la machine virtuelle

```bash
terraform apply
```

#### Démonstration

Toutes les ressources sont créées, on y retrouve notement la machine virtuelle et ces caractéristiques

![terraform plan](media/TP10-1-plan.png)

Une fois terminé on retrouve bien la machine sur Azure :
![TP10-1 VM azure](media/TP10-1-azure.png)

Et je peux me connecter à la machine virtuelle en ssh avec la commande suivante :

![Connection SSH](media/TP10-1-SSH.png)

Cette configuration sera la base pour la suite du TP.
<br>
### TP 10-2 Héberger un site web statique sur Azure Storage

#### Mise en place

Suite au TP 10-1, le compte de stockage est en place :
![Compte de stockage](media/TP-10-2-storage.png)

Je vais donc mettre en place un site web statique sur le compte de stockage créé précédement, en ajoutant à la configuration terraform la ressource `azurerm_storage_account_static_website`<br>
*Documentation :* https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_static_website

J'ai rajouté la resources suivante dans le fichier [main.tf](tp10/main.tf)

```tf
resource "azurerm_storage_account_static_website" "static_site" {
  storage_account_id = azurerm_storage_account.my_storage_account.id
  index_document     = "index.html"
  error_404_document = "404.html"
}
```

Et également un petit template web simple dans le dossier [web](tp10/web) contenant un index.html et un 404.html

Template que j'upload en blob dans le compte de stockage avec la ressource `azurerm_storage_blob`<br>
*Documentation :* https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob

```tf
resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.my_storage_account.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/web/index.html"
  content_type           = "text/html"
  depends_on             = [azurerm_storage_account_static_website.static_site]
}

resource "azurerm_storage_blob" "error_html" {
  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.my_storage_account.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/web/404.html"
  content_type           = "text/html"
  depends_on             = [azurerm_storage_account_static_website.static_site]
}
```

*J'ai eu une erreur au premier lancement de la commande terraform apply, car le compte de stockage n'était pas encore crée.J'ai donc rajouté la dépendance sur la ressource `azurerm_storage_account_static_website` pour que le blob ne soit créé qu'une fois le compte de stockage prêt.*

*Pour plus de confort j'ai également rajouté l'ouput de l'url du compte de stockage dans* [outputs.tf](tp10/outputs.tf)
```tf
output "static_website_url" {
  value = azurerm_storage_account.my_storage_account.primary_web_endpoint
}
```

#### Lancement de l'application

```bash
terraform apply
```

#### Démonstration

![Lancement de l'application](media/TP10-2-launch.png)

Et directement sur navigateur : <br>
![Lancement de l'application](media/TP10-2-final.png)

<br>

### TP 10-3 Connecter deux réseaux virtuels avec peering

**Objectif** : Créer  2  VMs  puis créer  des  réseaux  virtuels  (VNet)  isolés,  déployer  des  machines virtuelles  dans  chacun,  puis  établir  un  peering  entre  les  VNet  pour  permettre  la communication entreles VMs

#### Mise en place

Pour cette partie, je vais m'appuyer sur les ressource ``azurerm_virtual_network`` et ``azurerm_virtual_network_peering`` en plus des modules déjà utilisé dans le 10-1 pour créer la première vm et ainsi modifier le fichier [main.tf](tp10/main.tf)<br>

*Documentation :* https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering

#### Lancement de l'application

```bash
terraform apply
```

#### Démonstration

Les machines virtuelles sont bien créées, mais n'ont pas d'adresse IP publique.

Je peux récupperer leurs adresse privé avec la commande suivante :

```bash
az vm list-ip-addresses -g rg-more-iguana -n vm1 --query "[].virtualMachine.network.privateIpAddresses" -o tsv
```

```bash
az vm list-ip-addresses -g rg-more-iguana -n vm2 --query "[].virtualMachine.network.privateIpAddresses" -o tsv
```
*rg-more-iguana est à remplacer par le nom de votre groupe de ressource*

![Reccuperation de l'ip](media/TP10-3-IP.png)

J'ai alors créer un mot de passe pour la `vm1` dans main.tf pour m'y connecter via la console série Azure et ping la deuxième.

![Ping de la deuxieme vm](media/TP-10-ping.png)

<br>

## TP 11

**Objectif** : Faire des manipulations de pipeline CI/CD avec Azure DevOps

### TP 11-1 Pipeline CI/CD automatisé avec Azure DevOps Starter (.NET)

**Objectif** : Créer un projet DevOps Starter pour une appli .NET, ce qui génère automatiquement un pipeline d’intégration continue et de déploiement continu vers Azure App Service, avec codesource, build/release et monitoring intégrés

**Remarque** : Je devais m'appuyer sur la documentation Microsoft pour mettre en place le projet DevOps Starter :<br> 
https://azuredevopslabs.com/labs/vstsextend/azuredevopsprojectdotnet
*Mais à la première étape je n'arrive pas à trouver `DevOps starter`*

![DevOps starter](media/TP11-DevOps-starter.png)

J'ai donc trouvé une autre documentation sur laquel je vais m'appuyer, le résultat risque de différer très légèrement de l'énoncé :<br>
https://learn.microsoft.com/fr-fr/azure/devops/pipelines/get-started/azure-devops-starter?view=azure-devops&tabs=dotnet-core

**pré-requis** :<br>
- Avoir un compte Azure DevOps
- Avoir un compte Azure
- dotnet 8.0

#### Mise en place

Dans un premier temps je créer un projet .Net basique en local avec la commande suivante :

*Initialisation du code .Net*

```bash
dotnet new webapp -f net8.0
```
On peux ensuite le tester en local avec la commande suivante :

```bash
dotnet run
```

*Initialisation de Azure DevOps*

J'ai ensuite créer un projet Azure DevOps avec le nom `TP11`<br>

J'en profite pour ajouter une clé SSH et GPG pour mettre tout de suite en place les bonnes pratiques de sécurité.
Mais à ma grande surprise, en 2025 Azure DevOps n'a pas l'air de supporter le GPG et les clé ssh de type ssh-ed25519 ont l'air trop récentes.<br>

Je préfère ne pas commenter ces informations...

Je ne met donc rien en place pour le moment. de ce côté là, et retourne sur la création du projet.

![Création du projet](media/TP11-1-create-project.png)

Et j'ai ajouté le code source de l'application .Net dans le projet Azure DevOps avec les commandes suivante :

Initialisation de git

```bash
git init -b main
```
Ajout de tout les fichiers du repertoire

```bash
git add .
```
Commit des fichiers

```bash
git commit -m "Initial commit"
```
Envoi du code sur le projet Azure DevOps

```bash
git remote add origin https://almoskEdu@dev.azure.com/almoskEdu/TP11/_git/TP11
```
```bash
git push -u origin --all
```

Le projet est maintenant sur Azure DevOps

![Projet sur Azure DevOps](media/TP11-AzureDevOps.png)

*Initialisation du pipeline*

Je vais maintenant mettre en place le pipeline CI/CD avec l'interface Azure DevOps depuis le menu `Pipelines`<br>
en choisissant :

- `Azure Repos Git`<br>
- `TP11`<br>
- `Starter pipeline`<br>

![Pipeline Etape1](media/TP11-Pipeline.png)

Et au premier run du pipeline, j'ai une erreur de build :
```bash
##[error]No hosted parallelism has been purchased or granted. To request a free parallelism grant, please fill out the following form https://aka.ms/azpipelines-parallelism-request
```

La page me renvoie vers un formulaire pour demander l'accès à un agent de build...
Je l'ai rempli aujourd'hui le 07 mai, à voir quand j'aurais une réponse.

Sinon il y'a l'air d'avoir la possibilité de créer un agent de build auto-hébergé comme sur GitLab, je me garde cette solution sous le coude si je n'ai pas de réponse rapidement.

