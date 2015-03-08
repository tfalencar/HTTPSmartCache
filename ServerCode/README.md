> Note: this server code is by no means meant to be used directly in a production deployment. They're more about little hacks to demonstrate a caching concept.

###Basic setup

Before starting, make sure you have these components installed:

-Couchbase Server;
-Couchbase Python SDK;

Please refer to original documentation in Couchbase's website for instructions.

- Create a virtual environment: 

```
pip install virutalenv
virtualen venv
source venv/bin/activate
```

###Running replace_db_images.py

Install a Design in your Couchbase Server named 'myViews'

Install the following View in your Couchbase Server with name 'allImages' under the 'myViews' design you just created: 

```
 function (doc, meta) {
   if((doc.MIMEType.indexOf("image") > -1) && (doc.responseData)) 
   emit(meta.id, null);
 }
````

Then run from your python environment:

```
(venv) $ python replace_db_images.py
```

