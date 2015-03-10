from flask import Blueprint

blueprint = Blueprint('api_1_0', __name__)

from . import mitm
