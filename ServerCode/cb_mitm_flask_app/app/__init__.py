from flask import Flask, g
from peewee import *
from config import DevelopmentConfig
from app.api_1_0 import blueprint as api

app = Flask(__name__)
app.config.from_object(DevelopmentConfig)

app.peeweedb = MySQLDatabase('demoapp_db', user='demoapp_flask', passwd='letmein')

app.register_blueprint(api, url_prefix='/api/v1.0')

