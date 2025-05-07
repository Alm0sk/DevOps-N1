import os
import logging
from flask import Flask

logging.basicConfig(filename='/logs/app.log', level=logging.INFO)

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('FLASK_SECRET_KEY', 'defaultkey')

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"
