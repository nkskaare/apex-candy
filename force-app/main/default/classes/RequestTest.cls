@IsTest
public class RequestTest {
  @IsTest
  static void testSetPath() {
    Request.Url url = new Request.Url('https://localhost/');
    String path = 'path';

    Test.startTest();
    url.setPath(path);
    System.assertEquals(url.path, path);
    Test.stopTest();
  }

  @IsTest
  static void testSetRemoveParameter() {
    Request.Url url = new Request.Url('https://localhost/');

    Test.startTest();
    url.setParameter('One', '1');
    System.assert(url.parameters.containsKey('One'));
    System.assertEquals(url.parameters.get('One'), '1');

    url.removeParameter('One');
    System.assert(!url.parameters.containsKey('One'));
    System.assertEquals(url.parameters.get('One'), null);
    Test.stopTest();
  }

  @IsTest
  static void testGetEndpoint() {
    Request.Url url = new Request.Url('https://localhost/', 'path');

    Test.startTest();
    url.setParameter('One', '1');
    String endpoint = url.getEndpoint();

    System.assertEquals('https://localhost/path?One=1', endpoint);
    Test.stopTest();
  }

  @IsTest
  static void testParameterQueryString() {
    Request.Url url = new Request.Url('https://localhost/');

    Test.startTest();
    url.setParameter('One', '1');
    url.setParameter('Two', '2');
    url.setParameter('Three', '3');

    String queryString = url.getQueryString();
    String expected = 'One=1&Two=2&Three=3';
    System.assertEquals(expected, queryString);
    Test.stopTest();
  }

  @IsTest
  static void testSetHostname(){

    String hostname = 'https://localhost/';

    Request req = new Request();
    
    Test.startTest();
    req.setHostname(hostname);
    System.assertEquals(hostname, req.url.hostname);
    Test.stopTest();
  }

  @IsTest
  static void testIsAuthorized(){
    Request res = new Request();
    
    Test.startTest();
    System.assert(res.isAuthorized());
    Test.stopTest();
  }


  @IsTest
  static void testAsMap(){

    HttpResponse httpRes = new HttpResponse();
    httpRes.setBody('{"example":"test"}');
    
    Request.Response res = new Request.Response(httpRes);
    
    Test.startTest();
    Map<String, Object> resMap = res.asMap();
    System.assert(resMap.containsKey('example'));
    System.assertEquals('test', resMap.get('example'));
    Test.stopTest();
  }

  @IsTest
  static void testAsString(){
    String body = '{"example":"test"}';
    HttpResponse httpRes = new HttpResponse();
    httpRes.setBody(body);
    
    Request.Response res = new Request.Response(httpRes);
    
    Test.startTest();
    System.assertEquals(body, res.asString());
    Test.stopTest();
  }

  @IsTest
  static void testResponseRaw(){
    
    HttpResponse httpRes = new HttpResponse();
    httpRes.setBody('{"example":"test"}');
    
    Request.Response res = new Request.Response(httpRes);
    
    Test.startTest();
    System.assertEquals(httpRes, res.raw());
    Test.stopTest();
  }

  @IsTest
  static void testAsObject(){

    String jsonString = '{"testString":"test", "testInt" : 1, "testBool" : false}';
    
    HttpResponse httpRes = new HttpResponse();
    httpRes.setBody(jsonString);
    
    JsonObject expectedObj = (JsonObject) JSON.deserialize(jsonString, JsonObject.class);
    
    Test.startTest();
    Request.Response res = new Request.Response(httpRes);
    JsonObject resObj = (JsonObject) res.asObject(JsonObject.class);

    System.assertEquals(expectedObj.testBool, resObj.testBool);
    System.assertEquals(expectedObj.testInt, resObj.testInt);
    System.assertEquals(expectedObj.testString, resObj.testString);
    Test.stopTest();
    
  }


  public virtual class SendMockSuccess implements HttpCalloutMock {

    public String assertMethod;
    public String assertEndpoint;
    public String assertBody = '';
    public Map<String, String> assertHeaders = new Map<String, String>();

    public HttpResponse respond(HttpRequest req) {

      System.assertEquals(this.assertMethod, req.getMethod());
      System.assertEquals(this.assertEndpoint, req.getEndpoint());
      System.assertEquals(this.assertBody, req.getBody());
      for (String header : assertHeaders.keySet()) {
        System.assertEquals(assertHeaders.get(header), req.getHeader(header)); 
      }

      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"example":"test"}');
      res.setStatusCode(200);
      return res;
    }
  }

  public class GetMock extends SendMockSuccess {
    public GetMock() {
      super();
      this.assertMethod = 'GET';
    }
  }

  public class PostMock extends SendMockSuccess {
    public PostMock() {
      super();
      this.assertMethod = 'POST';
    }
  }

  public class PutMock extends SendMockSuccess {
    public PutMock() {
      super();
      this.assertMethod = 'PUT';
    }
  }

  public class PatchMock extends SendMockSuccess {
    public PatchMock() {
      super();
      this.assertMethod = 'PATCH';
    }
  }

  public class DelMock extends SendMockSuccess {
    public DelMock() {
      super();
      this.assertMethod = 'DELETE';
    }
  }

  @IsTest
  static void testSendSuccess() {
    Request req = new Request('https://localhost/');

    req.httpRequest.setMethod('GET');

    GetMock mock = new GetMock();
    mock.assertEndpoint = 'https://localhost/';

    Test.setMock(HttpCalloutMock.class, mock);
    Test.startTest();
    req.send();

    System.assertEquals(
      req.response.httpResponse.getHeader('Content-Type'),
      'application/json'
    );
    System.assertEquals(
      req.response.httpResponse.getBody(),
      '{"example":"test"}'
    );
    Test.stopTest();
  }

  public class SendMockFailure implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(400);
      res.setStatus('Bad Request');
      return res;
    }
  }

  @IsTest
  static void testSendFailure() {
    Request req = new Request('https://localhost/');

    req.httpRequest.setMethod('GET');

    Test.setMock(HttpCalloutMock.class, new SendMockFailure());
    Test.startTest();
    try {
      req.send();
      System.assert(false);
    } catch (Request.RequestException e) {
      System.assertEquals('https://localhost/', req.httpRequest.getEndpoint());
      System.assertEquals('GET', req.httpRequest.getMethod());
      System.assertEquals('400 : Bad Request', e.getMessage());
    }

    Test.stopTest();
  }

  @IsTest
  static void testGet(){
    Request req = new Request('https://localhost/');

    GetMock mock = new GetMock();
    mock.assertEndpoint = 'https://localhost/get';
    Test.setMock(HttpCalloutMock.class, mock);
    
    Test.startTest();
    req.get('get');
    System.assert(req.response.isSuccess());
    Test.stopTest();
  }

  public class JsonObject {
    public String testString;
    public Integer testInt;
    public Boolean testBool;
  }

  @IsTest
  static void testPost() {
    Request req = new Request('https://localhost/');

    String stringBody = 'Test string';
    Map<String, Object> mapBody = new Map<String, Object>{
      'foo' => 1,
      'bar' => 'baz'
    };
    JsonObject objectBody = new JsonObject();
    objectBody.testString = 'foo';
    objectBody.testInt = 1;
    objectBody.testBool = false;

    Test.startTest();

    PostMock mock = new PostMock();
    mock.assertEndpoint = 'https://localhost/string';
    mock.assertBody = stringBody;

    Test.setMock(HttpCalloutMock.class, mock);
    req.post(stringBody, 'string');
    System.assert(req.response.isSuccess());

    mock.assertEndpoint = 'https://localhost/map';
    mock.assertHeaders = new Map<String, String> {'Content-Type' => 'application/json'};
    mock.assertBody = ApplicationService.mapToJSON(mapBody);

    Test.setMock(HttpCalloutMock.class, mock);
    req.post(mapBody, 'map');
    System.assert(req.response.isSuccess());

    mock.assertEndpoint = 'https://localhost/object';
    mock.assertBody = JSON.serialize(objectBody, true);

    Test.setMock(HttpCalloutMock.class, mock);
    req.post(objectBody, 'object');
    System.assert(req.response.isSuccess());

    Test.stopTest();
  }

  @IsTest
  static void testPut() {
    Request req = new Request('https://localhost/');

    String stringBody = 'Test string';
    Map<String, Object> mapBody = new Map<String, Object>{
      'foo' => 1,
      'bar' => 'baz'
    };
    JsonObject objectBody = new JsonObject();
    objectBody.testString = 'foo';
    objectBody.testInt = 1;
    objectBody.testBool = false;

    Test.startTest();

    PutMock mock = new PutMock();
    mock.assertEndpoint = 'https://localhost/string';
    mock.assertBody = stringBody;

    Test.setMock(HttpCalloutMock.class, mock);
    req.put(stringBody, 'string');
    System.assert(req.response.isSuccess());

    mock.assertEndpoint = 'https://localhost/map';
    mock.assertHeaders = new Map<String, String> {'Content-Type' => 'application/json'};
    mock.assertBody = ApplicationService.mapToJSON(mapBody);

    Test.setMock(HttpCalloutMock.class, mock);
    req.put(mapBody, 'map');
    System.assert(req.response.isSuccess());

    mock.assertEndpoint = 'https://localhost/object';
    mock.assertBody = JSON.serialize(objectBody, true);

    Test.setMock(HttpCalloutMock.class, mock);
    req.put(objectBody, 'object');
    System.assert(req.response.isSuccess());

    Test.stopTest();
  }
  
  @IsTest
  static void testPatch() {
    Request req = new Request('https://localhost/');

    String stringBody = 'Test string';
    Map<String, Object> mapBody = new Map<String, Object>{
      'foo' => 1,
      'bar' => 'baz'
    };
    JsonObject objectBody = new JsonObject();
    objectBody.testString = 'foo';
    objectBody.testInt = 1;
    objectBody.testBool = false;

    Test.startTest();

    PatchMock mock = new PatchMock();
    mock.assertEndpoint = 'https://localhost/string';
    mock.assertBody = stringBody;

    Test.setMock(HttpCalloutMock.class, mock);
    req.patch(stringBody, 'string');
    System.assert(req.response.isSuccess());

    mock.assertEndpoint = 'https://localhost/map';
    mock.assertHeaders = new Map<String, String> {'Content-Type' => 'application/json'};
    mock.assertBody = ApplicationService.mapToJSON(mapBody);

    Test.setMock(HttpCalloutMock.class, mock);
    req.patch(mapBody, 'map');
    System.assert(req.response.isSuccess());

    mock.assertEndpoint = 'https://localhost/object';
    mock.assertBody = JSON.serialize(objectBody, true);

    Test.setMock(HttpCalloutMock.class, mock);
    req.patch(objectBody, 'object');
    System.assert(req.response.isSuccess());

    Test.stopTest();
  }

  @IsTest
  static void testDel() {
    Request req = new Request('https://localhost/');

    String stringBody = 'Test string';
    Map<String, Object> mapBody = new Map<String, Object>{
      'foo' => 1,
      'bar' => 'baz'
    };

    JsonObject objectBody = new JsonObject();
    objectBody.testString = 'foo';
    objectBody.testInt = 1;
    objectBody.testBool = false;

    Test.startTest();

    DelMock mock = new DelMock();
    mock.assertEndpoint = 'https://localhost/string';
    mock.assertBody = stringBody;

    Test.setMock(HttpCalloutMock.class, mock);
    req.del(stringBody, 'string');
    System.assert(req.response.isSuccess());

    mock.assertEndpoint = 'https://localhost/map';
    mock.assertHeaders = new Map<String, String> {'Content-Type' => 'application/json'};
    mock.assertBody = ApplicationService.mapToJSON(mapBody);

    Test.setMock(HttpCalloutMock.class, mock);
    req.del(mapBody, 'map');
    System.assert(req.response.isSuccess());

    mock.assertEndpoint = 'https://localhost/object';
    mock.assertBody = JSON.serialize(objectBody, true);

    Test.setMock(HttpCalloutMock.class, mock);
    req.del(objectBody, 'object');
    System.assert(req.response.isSuccess());

    Test.stopTest();
  }
}
