{
   "interface":":4984",
   "adminInterface":":4985",
   "log": ["REST","CRUD", "CRUD+", "HTTP", "HTTP+", "Access", "Cache", "Shadow", "Shadow+", "Changes", "Changes+"],
   "databases":{
      "sync_gw_demo":{
         "server":"http://localhost:8091",
         "bucket":"sync_gw_demo",
	 "shadow": {
        	         "server": "http://localhost:8091",
              		 "bucket": "shadow"
            	   },
	 "users": {
	        "GUEST": {
        		"disabled": false,
			"admin_channels": ["popularity"],
			"admin_channels": ["brand"],
			"admin_channels": ["name"],
			"admin_channels": ["price"],
			"admin_channels": ["*"]
         	}
		},
         "sync":`

// sync function
function(doc,oldDoc) {
	//channel('public_cache');
	channel(doc.channels);
	//only allow update from localhost:
	requireUser("noWriteAccess");
}
`
      }
   }
}

