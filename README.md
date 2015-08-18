
HttpSmartCache
================

![Alt text](https://github.com/tfalencar/HttpSmartCache/blob/master/AirplaneCouchRest.png)

Technique and helper classes for improved User Experience (speed) and off-line handling for HTTP/1.1 GET requests.


### What can it do for you?


1- 'Offline support' for HTTP GET requests

2- Fast response for already requested GET's (Improved UX)

3- Automatic handling of data update (eliminate problems caused by stale data)

All of that, for any of your standard GET REST APIs (no modifications in the API whatsoever required). 


### What it can not do for you?

As with any caching system, this project will provide little value to data which is completely dynamic, and will have no effect in the speed of requests other than "GET" (e.g. PUT, POST, etc). Therefore, such requests can be redirected to the API server with e.g., nginx (bypassing this caching layer).

That said, *differently* from most caching systems, frequent updates can be "speed-up" because of the "push nature" of the technique - no additional request is required for an already cached 'GET'.


### Requirements

The implementation requires Couchbase Lite at the mobile side, and Couchbase Sync Gateway at the backend.

Example:

![Alt text](https://github.com/tfalencar/HttpSmartCache/blob/master/integration.png)


This repository is divided in three parts:

### 1) CBCacheCategories

NSURLSession+CBCache : category that can be used to generate Couchbase cache documents.

UIImage+CBCache : Built on top of NSURLSession+CBCache category, this can be used to 'lazy-load' images using preloaded cache data as well as to record the respective cache documents.

### 2) cachePushDemoApp 

A working iOS sample project demonstrating the technique (click for video):

[http://ti.eng.br/wp-content/uploads/2015/03/performanceComparison.mp4](http://ti.eng.br/wp-content/uploads/2015/03/performanceComparison.mp4)


To use your own backend simply switch the demo server sync URL to your own.

Remember to run: 
`pod install`
Then open the project using its xcworkspace

When connected to the demo sync gateway, HTTP Requests that had their content cached are loaded instantly. Currently you can see such cached items pushed by the server in the first pages from category 'Price', order 'Descending'. 

However, if you want to see the caching effects without depending on the sync gateway's sync, simply switch:

```
//in MainTableViewController.m:

//from this: 
NSURLSessionDataTask *dataTask = [mySession dataTaskWithURL: ....
//to this: 
NSURLSessionDataTask *dataTask = [mySession cbcache_dataTaskWithURL: ....

//and @ ProductTableViewController.m:

//from: 
[customCell.imageView setImageWithURL: ...
//to this: 
[customCell.imageView cbcache_setImageWithURL: ...

```


### 3) ServerCode

Simple server-side script(s) to demonstrate how to create/update http cache documents. 



