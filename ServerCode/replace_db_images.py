#replace_db_images.py
#
# Small script to demonstrate how one can update documents using
# Couchbase's python SDK
#
# remember to pip install couchbase

import glob
from pprint import pprint
import base64
import random

from couchbase import Couchbase
from couchbase.exceptions import CouchbaseError

#Folder containing some images (create list)
#replace with your own 
myImagesList = glob.glob("cacheDemoAppImages/*")
#myImagesList = glob.glob("bwCacheDemoAppImages/*")

c = Couchbase.connect(bucket='shadow', host='localhost')

#first parameter is the design name, followed by the view name
#these can be created with Couchbase's web interface
view_results = c.query("myViews", "allImages")

#the view I added as 'allImages' is an index containing images cache
#documents only, like this:
# function (doc, meta) {
#   if((doc.MIMEType.indexOf("image") > -1) && (doc.responseData)) 
#   emit(meta.id, null);
# }

itemsProcessed = 0
for result in view_results:
	imageDoc = c.get(result.docid).value
	imagePath = random.choice(myImagesList)
	f = open(imagePath, 'r')
	imageDoc['responseData'] = base64.b64encode(f.read())
	f.close()
	c.set(result.docid, imageDoc)
	itemsProcessed += 1

pprint("Done processing " + str(itemsProcessed) + " items.")
