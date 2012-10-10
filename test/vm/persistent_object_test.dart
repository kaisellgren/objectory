library PersistenObjectTests;
import 'package:objectory/src/objectory_base.dart';
import 'package:objectory/src/objectory_direct_connection_impl.dart';
import 'package:objectory/src/persistent_object.dart';
import 'package:objectory/src/objectory_query_builder.dart';
import 'package:mongo_dart/bson.dart';
import 'package:mongo_dart/bson_vm.dart';
import 'package:unittest/unittest.dart';
import 'domain_model.dart';
testAuthorCreation(){
  var author = new Author();
  author.name = 'vadim';
  author.age = 99;
  author.email = 'sdf';
  author.
  expect((author.map.getKeys() as List)[0],"_id");
  expect(author.name,'VADIM', reason: 'converted to uppercase by custom  setter');
  author.address.cityName = 'Tyumen';
  author.address.streetName = 'Elm tree street';
  expect(author.map['address']['cityName'],'Tyumen');
  expect(author.map['address']['streetName'],'Elm tree street');
} 

testSetDirty(){
  var author = new Author();
  author.name = "Vadim";
  //expect(author.dirtyFields.length,1);
  expect(author.isDirty());  
}
testCompoundObject(){
  var person = new Person();  
  person.address.cityName = 'Tyumen';
  person.address.streetName = 'Elm';  
  person.firstName = 'Dick';  
  Map map = person.map;
  expect(map["address"]["streetName"],"Elm");
//  expect(person.address._parent,person);
//  expect(person.address.pathToMe,"address");
  expect(person.isDirty());
}
testFailOnSettingUnsavedLinkObject(){
  var son = new Person();  
  var father = new Person();  
  ;
  Expect.throws(()=>son.father = father,reason:"Link object must be saved (have ObjectId)");
}  
testFailOnAbsentProperty(){
  Dynamic author = new Author();
  Expect.throws(()=>author.sdfsdfsdfgdfgdf,reason:"Must fail on missing property getter");
}
testNewInstanceMethod(){
  Author author = objectory.newInstance('Author');
  expect(author is Author);       
}
testMap2ObjectMethod() {
  Map map = {
    "name": "Vadim",
    "age": 300,
    "email": "nobody@know.it"};
  Author author = objectory.map2Object("Author",map);
  //Not converted to upperCase because setter has not been invoked
  expect(author.name,"Vadim"); 
  expect(author.age,300);
  expect(author.email,"nobody@know.it");
  map = {
    "streetName": "333",
    "cityName": "44444"
      };
  Address address = objectory.map2Object("Address",map);  
  expect(address.cityName,"44444");
}
testObjectWithListOfInternalObjects2Map() {
  var customer = new Customer();
  customer.name = "Tequila corporation";
  var address = new Address();
  address.cityName = "Mexico";
  customer.addresses.add(address);
  address = new Address();
  address.cityName = "Moscow";
  customer.addresses.add(address);
  var map = customer.map;
  
  expect(map["name"],"Tequila corporation");  
  expect(map["addresses"].length,2);
  expect(map["addresses"][0] is! PersistentObject);
  expect(map["addresses"][0]["cityName"],"Mexico");
  expect(map["addresses"][1]["cityName"],"Moscow");  
}
testMap2ObjectWithListOfInternalObjects() {
  var map = {"_id": null, "name": "Tequila corporation", "addresses": [{"cityName": "Mexico"}, {"cityName": "Moscow"}]};
  Customer customer = objectory.map2Object($Customer.className, map);
  expect(customer.name,"Tequila corporation");
  expect(customer.addresses.length,2);
  expect(customer.addresses[1].cityName,"Moscow");
  expect(customer.addresses[0].cityName,"Mexico");
}
testObjectWithListtOfExternalRefs2Map() {
  Person father;
  Person son;
  Person daughter;
  Person sonFromObjectory;
  father = new Person();  
  father.firstName = 'Father';
  father.id = new ObjectId();
  father.map["_id"] = father.id;
  objectory.addToCache(father);
  son = new Person();  
  son.firstName = 'Son';
  son.father = father;
  son.id = new ObjectId();
  son.map["_id"] = son.id;
  objectory.addToCache(son);
  daughter = new Person();
  daughter.father = father;
  daughter.firstName = 'daughter';
  daughter.id = new ObjectId();
  daughter.map["_id"] = daughter.id;
  objectory.addToCache(daughter);
  father.children.add(son);  
  father.children.add(null);
  father.children[1] = daughter;
  expect(father.map["children"][0],son.dbRef);
  expect(father.map["children"][1],daughter.dbRef);  
}
testMap2ObjectWithListtOfInternalObjectsWithExternalRefs() {
  User user = new User();
  user.login = 'testLogin';
  user.name = 'TestUser';  
  user.id = new ObjectId();
  user.map["_id"] = user.id;
  objectory.addToCache(user);
  Map articleMap = {"title": "test article", "body": "sasdfasdfasdf", 
                    "comments": [{"body": "Excellent", "user": user.dbRef}]};               
  Article article = objectory.map2Object($Article.className,articleMap);  
  expect(article.map["comments"][0]["user"].id,user.dbRef.id);
  expect(article.comments[0].user,user);
}

main(){
  objectory = new ObjectoryDirectConnectionImpl();  
  initBsonPlatform();
  registerClasses();  
  group("PersistenObjectTests", ()  {
    test("testAuthorCreation",testAuthorCreation);
    test("testSetDirty",testSetDirty);
    test("testCompoundObject",testCompoundObject);
    test("testFailOnAbsentProperty",testFailOnAbsentProperty);
    test("testFailOnSettingUnsavedLinkObject",testFailOnSettingUnsavedLinkObject);
    test("testMap2ObjectMethod",testMap2ObjectMethod);
    test("testNewInstanceMethod",testNewInstanceMethod);
    test("testObjectWithListOfInternalObjects2Map",testObjectWithListOfInternalObjects2Map);
    test("testMap2ObjectWithListOfInternalObjects",testMap2ObjectWithListOfInternalObjects);
    test("testObjectWithListtOfExternalRefs2Map",testObjectWithListtOfExternalRefs2Map);
    test("testMap2ObjectWithListtOfInternalObjectsWithExternalRefs",testMap2ObjectWithListtOfInternalObjectsWithExternalRefs);    
  });
}