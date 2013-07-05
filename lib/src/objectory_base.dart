library objectory_base;
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'dart:collection';
import 'dart:async';
import 'package:bson/bson.dart';



Objectory get objectory => Objectory.objectoryImpl;
set objectory(Objectory impl) => Objectory.objectoryImpl = impl;

class ObjectoryCollection {
  String collectionName;
  Type classType;
  Future<PersistentObject> findOne([ObjectoryQueryBuilder selector]) { throw new Exception('method findOne must be implemented'); }
  Future<int> count([ObjectoryQueryBuilder selector]) { throw new Exception('method count must be implemented'); }  
  Future<List<PersistentObject>> find([ObjectoryQueryBuilder selector]) { throw new Exception('method find must be implemented'); }
}

typedef Object FactoryMethod();

class Objectory{

  static Objectory objectoryImpl;
  String uri;
  Function registerClassesCallback;
  bool dropCollectionsOnStartup;
  final Map<String,BasePersistentObject> cache = new  Map<String,BasePersistentObject>();
  final Map<Type,FactoryMethod> _factories = new Map<Type,FactoryMethod>();
  final Map<Type,FactoryMethod> _listFactories = new Map<Type,FactoryMethod>();
  final Map<Type,ObjectoryCollection> _collections = new Map<Type,ObjectoryCollection>();
  final Map<String,Type> _collectionNameToTypeMap = new Map<String,Type>();

  Objectory(this.uri,this.registerClassesCallback,this.dropCollectionsOnStartup);

  void addToCache(PersistentObject obj) {
    cache[obj.id.toString()] = obj;
  }
  Type getClassTypeByCollection(String collectionName) => _collectionNameToTypeMap[collectionName];
  PersistentObject findInCache(var id) {
    if (id == null) {
      return null;
    }
    return cache[id.toString()];
  }
  PersistentObject findInCacheOrGetProxy(var id, Type classType) {
    if (id == null) {
      return null;
    }
    PersistentObject result = findInCache(id);
    if (result == null) {
      result = objectory.newInstance(classType);
      result.id = id;
      result.notFetched = true;
    }
    return result;
  }
  BasePersistentObject newInstance(Type classType){
    if (_factories.containsKey(classType)){
      return _factories[classType]();
    }
    throw new Exception('Class $classType have not been registered in Objectory');
  }
  PersistentObject dbRef2Object(DbRef dbRef) {
    return findInCacheOrGetProxy(dbRef.id, objectory.getClassTypeByCollection(dbRef.collection));
  }
  BasePersistentObject map2Object(Type classType, Map map){
    if (map == null) {
      map = new LinkedHashMap();
    }
    var result = newInstance(classType);
    result.map = map;
    if (result is PersistentObject){
      result.id = map["_id"];
    }
    if (result is PersistentObject) {
      if (result.id != null) {
        objectory.addToCache(result);
      }
    }
    return result;
  }
  List createTypedList(Type classType) {
    return _listFactories[classType]();
  }

  List<String> getCollections() => _collections.values.map((ObjectoryCollection oc) => oc.collectionName).toList();
  /**
   * Returns the collection name for the given model instance.
   */
  String getCollectionByModel(PersistentObject model) {
    var collection;

    _factories.forEach((key, value) {
      if (value().runtimeType == model.runtimeType) collection = key;
    });

    return collection;
  }

  Future save(PersistentObject persistentObject){
    if (persistentObject.id != null){
      return update(persistentObject);
    }
    else{
      persistentObject.id = generateId();
      persistentObject.map["_id"] = persistentObject.id;
      objectory.addToCache(persistentObject);
      return insert(persistentObject);
    }
  }

  ObjectId generateId() => new ObjectId();

  void registerClass(Type classType,FactoryMethod factory,[FactoryMethod listFactory]){
    _factories[classType] = factory;
    _listFactories[classType] = (listFactory==null ? ()=>new List<PersistentObject>() : listFactory);
    BasePersistentObject obj = factory();
    if (obj is PersistentObject) {
      var collectionName = obj.dbType;
      _collectionNameToTypeMap[collectionName] = classType;
      _collections[classType] = createObjectoryCollection(classType,collectionName);
    }
  }
  Future dropCollections() { throw new Exception('Must be implemented'); }

  Future open() { throw new Exception('Must be implemented'); }

  ObjectoryCollection createObjectoryCollection(Type classType, String collectionName){
    return new ObjectoryCollection()
      ..classType = classType
      ..collectionName = collectionName;
  }
  Future insert(PersistentObject persistentObject) { throw new Exception('Must be implemented'); }
  Future update(PersistentObject persistentObject) { throw new Exception('Must be implemented'); }
  Future remove(BasePersistentObject persistentObject) { throw new Exception('Must be implemented'); }
  Future<Map> dropDb() { throw new Exception('Must be implemented'); }
  Future<Map> wait() { throw new Exception('Must be implemented'); }
  void close() { throw new Exception('Must be implemented'); }
  Future<bool> initDomainModel() {
    registerClassesCallback();
    return open().then((_){
      if (dropCollectionsOnStartup) {
        return objectory.dropCollections();
      }
    });
  }

  completeFindOne(Map map,Completer completer,ObjectoryQueryBuilder selector,Type classType) {
    var obj;
    if (map == null) {
      completer.complete(null);
    }
    else {
      obj = objectory.map2Object(classType,map);
      addToCache(obj);
      if ((selector == null) ||  !selector.paramFetchLinks) {
        completer.complete(obj);
      } else {
        obj.fetchLinks().then((_) {
          completer.complete(obj);
        });  
      }
    }
  }
  
  ObjectoryCollection operator[](Type classType) => _collections[classType];
}