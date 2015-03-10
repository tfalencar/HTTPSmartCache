#mitm.py
# A demonstration of how http response cache documents can be
# created in couchbase for later sync with mobile devices

from flask import jsonify, request
from flask import current_app
from flask import g
from . import blueprint
from pprint import pprint
from peewee import *
import requests
import hashlib
import re
import base64

#couchbase
from couchbase import Couchbase
from couchbase.exceptions import CouchbaseError

serverURL = 'https://yourserver.com/replace/with/your/API?'
cb_bucket = 'shadow'
cb_host = 'localhost'

# The route below catches every request
#
# An user requests the following URL:
#    http://www.example.com/myapplication/page.html?x=y
# In this case the values of the above mentioned attributes would be the following:
#	request.path             /page.html
#	request.script_root      /myapplication
#	request.base_url         http://www.example.com/myapplication/page.html
#	request.url              http://www.example.com/myapplication/page.html?x=y
#	request.url_root         http://www.example.com/myapplication/
@blueprint.route('/', defaults={'path': ''})
@blueprint.route('/<path:path>')
def catch_all(path):

	db = current_app.peeweedb
	class BaseModel(Model):
    		class Meta:
        		database = current_app.peeweedb

	class RecordedResponses(BaseModel):
    		requestPath = TextField()
    		response = TextField()

	fullURL = request.url
	noRootURL = re.sub(request.url_root,'',fullURL)
	noRootURL = re.sub('api/v1.0/','',noRootURL)
	fullRequestURL = serverURL + noRootURL

	pprint("fullRequestURL = " + fullRequestURL)

	try:
		dbResponse = RecordedResponses.get(RecordedResponses.requestPath == fullRequestURL)
		if(dbResponse):
			pprint("Returning stored response")
			return dbResponse.response
	except: 
		pprint("Storing response..")
		response = requests.get(fullRequestURL)
		#return response.content
		if(response.status_code == 200):

			#create couchbase document according to channel
			c = Couchbase.connect(bucket=cb_bucket, host=cb_host)			

			#create document 
			doc = {}

			#example to add doc to a channel
			if "popularity" in request.url:
				doc['channels'] = "popularity"
			elif "price" in request.url:
				doc['channels'] = "price"
			elif "name" in request.url:
				doc['channels'] = "name"
			elif "brand" in request.url:
				doc['channels'] = "brand"
				
			doc['MIMEType'] = "application/json"
			doc['responseHeaders'] = str(response.headers)
			doc['statusCode'] = response.status_code
			doc['type'] = "requestCache" 
			doc['responseData'] =  base64.b64encode(response.content)
			
			try:
    				pprint(str(result = c.get(request.url)))
    				pprint(str(c.set(request.url, doc)))

			#except KeyNotFoundError:
			except:
    				pprint(str(c.set(request.url, doc)))

			#save response.content to mysql database
			db.connect()
			#db.create_tables([RecordedResponses])
			newResponse = RecordedResponses.create(requestPath=fullRequestURL, response=response.content)

			#finally reply request
			return response.content

	response = jsonify(result = 'Error')
	response.status_code = 500
	return response 

