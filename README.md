##Objectory - object document mapper for server-side and client side Dart applications

Objectory provides typed, checked environment to model, save and query data persisted on MongoDb.

Objectory provides identical API for server side and browser applications (both Dartium and dart2js supported).

###Getting started

- Clone Objectory from [github repository](https://github.com/vadimtsushko/objectory)
- Run **pub install** in the root of Objectory.

Now you may run server-side blog example: */example/vm/blog.dart*. This example uses connection to free MongoLab account 

- Install MongoDb locally. Ensure that MongoDB is running  with default parameters (host 127.0.0.7, port 27017, authentication disabled)

Now you may run server side objectory tests: *test/base_objectory_tests.dart* and *test/vm_implementation_tests.dart*

- While running local MongoDB process, start websocket objectory server: *bin/objectory_server.dart*
 
- Configure Dartium launches for *test/objectory_test.html* and */example/blog.html* In group Dartium settings uncheck *Run in checked mode* and *Enable debugging*.  

Now you may run browser tests and blog example (port of server-side example to browser) both in Dartium and as JavaScript. JavaScript launches do not require any special setup.

See also clone of Dart WebComponents [TodoMVC sample application with added by Objectory persistency](https://github.com/vadimtsushko/todomvc_objectory_indexeddb)  

See [Quick tour](https://github.com/vadimtsushko/objectory/blob/master/doc/quick_tour.md) for futher information