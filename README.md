
> ###[WORK IN PROGRESS:]###
>
> I'm still working on this project, when it's done this notice will be removed. Come back soon.


HttpSmartCache
================

![Alt text](https://github.com/tfalencar/HttpSmartCache/blob/master/AirplaneCouchRest.png)

Technique and helper classes to boost the performance of your HTTP/1.1 requests.

More details about the it can be found at: http://ti.eng.br/?p=1023

The implementation requires Couchbase Lite at the mobile side, and Couchbase Sync Gateway at the backend.

This repository is divided in three parts:

### 1) CBCacheCategories

NSURLSession+CBCache : category that can be used to generate Couchbase cache documents.

UIImage+CBCache : Built on top of NSURLSession+CBCache category, this can be used to 'lazy-load' images using preloaded cache data as well as to record the respective cache documents.

### 2) cachePushDemoApp 

A working iOS sample project demonstrating the technique (click for video):

[![Click to open video](https://github.com/tfalencar/HttpSmartCache/blob/master/loading.png)](http://ti.eng.br/?p=1273)


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



