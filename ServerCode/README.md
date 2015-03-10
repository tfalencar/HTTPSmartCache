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


###Running cb_mitm_flask_app

This demo server app works like a "Man in The Middle", intercepting HTTP requests and storing them in Couchbase Server as documents before giving the response back to the requesting client.

Say if one has something like this:

```
/*
Client -----> HTTP Request ------------> Server
Client <---- HTTP Response ------------< Server

This script goes:

            ------------
Client --->| mitm.py app |---------> Server
            ------------               |
                 |                     |
                 | <---------------- Server
                 | ----------------> Couchbase Server
Client <-------- | 
*/

```

---

####To run it:

I've used a mysql table to hold response data 
(simply for development/debugging purposes: this way I can delete rows from mysql and make it rewrite the contents in Couchbase Server. So if you want to use the script as-is, setup mysql first.

- Install mysql on your system, then:

```
CREATE database demoapp_db;
CREATE USER 'demoapp_flask' IDENTIFIED BY 'letmein'
grant all privileges on demoapp_db.* to demoapp_flask@localhost identified by 'letmein' with grant option;
```


- Install the required packages

`pip install -r requirements.txt`

- Setup Couchbase Server:

The script assumes there's a Couchbase server instance running in the localhost, requiring that:
1) A "shadow" bucket exists (used to synchronise with sync gateway) 
2) the following variables in the mitm.py script are properly set:

```
serverURL = 'https://yourserver.com/replace/with/your/API?'
cb_bucket = 'shadow'
cb_host = 'localhost'
``` 

- Now run it: 
`python run.py`

When you want a certain response doc to be updated, delete the respective (or simply all) row from:

```
use demoapp_db
delete from recordedresponses;
```

