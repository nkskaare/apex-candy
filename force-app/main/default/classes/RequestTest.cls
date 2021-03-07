@IsTest
public class RequestTest {
    public static final Request.Url TEST_URL = new Request.Url(
        'https://test.api.com/'
    );

    public virtual class SendMock implements HttpCalloutMock {
        public String body;
        public Integer statusCode;
        public String status;

        public String assertMethod;
        public String assertEndpoint;
        public String assertBody;
        public Map<String, String> assertHeaders = new Map<String, String>();

        public SendMock() {
            this.body = '{"example":"test"}';
            this.statusCode = 200;
        }

        public SendMock(Boolean success) {
            if (success) {
                this();
            } else {
                this.statusCode = 400;
                this.status = 'Bad Request';
            }
        }

        public SendMock(String body) {
            this();
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            this.assert(req);
            return this.generateResponse();
        }

        public virtual HttpResponse generateResponse() {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.statusCode);
            if (this.body != null)
                res.setBody(this.body);
            if (this.status != null)
                res.setStatus(this.status);
            return res;
        }

        public virtual void assert(HttpRequest req) {
            if (this.assertMethod != null)
                System.assertEquals(this.assertMethod, req.getMethod());
            if (this.assertEndpoint != null)
                System.assertEquals(this.assertEndpoint, req.getEndpoint());
            if (this.assertBody != null)
                System.assertEquals(this.assertBody, req.getBody());
            if (this.assertHeaders != null) {
                for (String header : assertHeaders.keySet()) {
                    System.assertEquals(
                        assertHeaders.get(header),
                        req.getHeader(header)
                    );
                }
            }
        }
    }

    public class GetMock extends SendMock {
        public GetMock() {
            super();
            this.assertMethod = 'GET';
        }
    }

    public class PostMock extends SendMock {
        public PostMock() {
            super();
            this.assertMethod = 'POST';
        }

        public PostMock(String responseBody) {
            super();
            this.assertMethod = 'POST';
            this.body = responseBody;
        }
    }

    public class PutMock extends SendMock {
        public PutMock() {
            super();
            this.assertMethod = 'PUT';
        }
    }

    public class PatchMock extends SendMock {
        public PatchMock() {
            super();
            this.assertMethod = 'PATCH';
        }
    }

    public class DelMock extends SendMock {
        public DelMock() {
            super();
            this.assertMethod = 'DELETE';
        }
    }

    @IsTest
    static void testSetPath() {
        Request.Url url = new Request.Url(
            'https://localhost/'
        );
        String path = 'path';

        Test.startTest();
        url.setPath(path);
        System.assertEquals(url.path, path);
        Test.stopTest();
    }

    @IsTest
    static void testSetRemoveParameter() {
        Request.Url url = new Request.Url(
            'https://localhost/'
        );

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
        Request.Url url = new Request.Url(
            'https://localhost/',
            'path'
        );

        Test.startTest();
        url.setParameter('One', '1');
        String endpoint = url.getEndpoint();

        System.assertEquals('https://localhost/path?One=1', endpoint);
        Test.stopTest();
    }

    @IsTest
    static void testParameterQueryString() {
        Request.Url url = TEST_URL.clone();

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
    static void testSetParameters() {
        Request.Url url = TEST_URL.clone();

        Map<String, String> parameters = new Map<String, String>{
            'One' => '1',
            'Two' => '2',
            'Three' => '3'
        };

        Test.startTest();
        url.setParameters(parameters);

        System.assertEquals(parameters, url.parameters);
        Test.stopTest();
    }

    @IsTest
    static void testClearParameters() {
        Request.Url url = TEST_URL.clone();

        Map<String, String> parameters = new Map<String, String>{
            'One' => '1',
            'Two' => '2',
            'Three' => '3'
        };

        Test.startTest();
        url.setParameters(parameters);
        System.assertEquals(parameters, url.parameters);

        url.clearParameters();
        System.assert(url.parameters.isEmpty());
        Test.stopTest();
    }

    @IsTest
    static void testSetUrl() {
        Request connector = new Request();
        Request.Url url = TEST_URL.clone().setPath('endpoint/path');
        url.setParameter('param1', '1');
        url.setParameter('param2', '2');

        Test.startTest();
        HttpRequest req = new HttpRequest();

        connector.setUrl(url, req);
        System.assertEquals(
            'https://test.api.com/endpoint/path?param1=1&param2=2',
            req.getEndpoint()
        );
        Test.stopTest();
    }

    @IsTest
    static void testAsMap() {
        Request connector = new Request();

        HttpResponse res = new HttpResponse();
        res.setBody(new SendMock().body);

        Test.startTest();
        Map<String, Object> resMap = connector.getAsMap(res);
        System.assert(resMap.containsKey('example'));
        System.assertEquals('test', resMap.get('example'));
        Test.stopTest();
    }

    @IsTest
    static void testAsObject() {
        String jsonString = '{"testString":"test", "testInt" : 1, "testBool" : false}';

        HttpResponse res = new HttpResponse();
        res.setBody(jsonString);

        JsonObject expectedObj = (JsonObject) JSON.deserialize(
            jsonString,
            JsonObject.class
        );

        Request connector = new Request();

        Test.startTest();
        JsonObject resObj = (JsonObject) connector.getAsObject(
            JsonObject.class,
            res
        );

        System.assertEquals(expectedObj.testBool, resObj.testBool);
        System.assertEquals(expectedObj.testInt, resObj.testInt);
        System.assertEquals(expectedObj.testString, resObj.testString);
        Test.stopTest();
    }

    @IsTest
    static void testSetHeaders() {
        Test.startTest();
        Test.stopTest();
    }

    @IsTest
    static void testSendSuccess() {
        Request connector = new Request();

        HttpRequest req = new HttpRequest();
        connector.setUrl(TEST_URL, req);

        SendMock mock = new SendMock();
        mock.assertEndpoint = TEST_URL.hostname;

        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        HttpResponse res = connector.send(req);

        System.assertEquals(res.getHeader('Content-Type'), 'application/json');
        System.assertEquals(res.getBody(), '{"example":"test"}');
        Test.stopTest();
    }

    @IsTest
    static void testSendFailure() {
        Request connector = new Request();

        HttpRequest req = new HttpRequest();
        connector.setUrl(TEST_URL, req);

        SendMock mock = new SendMock(false);
        mock.assertEndpoint = TEST_URL.hostname;

        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        try {
            connector.send(req);
            System.assert(false);
        } catch (Request.SendException e) {
            System.assertEquals('400 : Bad Request', e.getMessage());
        }

        Test.stopTest();
    }

    @IsTest
    static void testGet() {
        Request connector = new Request();
        Request.Url url = TEST_URL.clone().setPath('get');

        HttpRequest req = new HttpRequest();
        connector.setUrl(url, req);

        GetMock mock = new GetMock();
        mock.assertEndpoint = 'https://test.api.com/get';
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        HttpResponse res = connector.get(req);
        System.assert(connector.isSuccess(res));
        Test.stopTest();
    }

    public class JsonObject {
        public String testString;
        public Integer testInt;
        public Boolean testBool;
    }

    @IsTest
    static void testPost() {
        Request connector = new Request();
        Request.Url url = TEST_URL.clone().setPath('post');

        HttpRequest req = new HttpRequest();
        connector.setUrl(url, req);

        String stringBody = 'Test string';
        req.setBody(stringBody);

        Test.startTest();

        PostMock mock = new PostMock();
        mock.assertEndpoint = 'https://test.api.com/post';
        mock.assertBody = stringBody;

        Test.setMock(HttpCalloutMock.class, mock);
        HttpResponse res = connector.post(req);
        System.assert(connector.isSuccess(res));

        Test.stopTest();
    }

    @IsTest
    static void testPut() {
        Request connector = new Request();
        Request.Url url = TEST_URL.clone().setPath('put');

        HttpRequest req = new HttpRequest();
        connector.setUrl(url, req);

        String stringBody = 'Test string';
        req.setBody(stringBody);

        Test.startTest();

        PutMock mock = new PutMock();
        mock.assertEndpoint = 'https://test.api.com/put';
        mock.assertBody = stringBody;

        Test.setMock(HttpCalloutMock.class, mock);
        HttpResponse res = connector.put(req);
        System.assert(connector.isSuccess(res));

        Test.stopTest();
    }

    @IsTest
    static void testPatch() {
        Request connector = new Request();
        Request.Url url = TEST_URL.clone().setPath('patch');

        HttpRequest req = new HttpRequest();
        connector.setUrl(url, req);

        String stringBody = 'Test string';
        req.setBody(stringBody);

        Test.startTest();

        PatchMock mock = new PatchMock();
        mock.assertEndpoint = 'https://test.api.com/patch';
        mock.assertBody = stringBody;

        Test.setMock(HttpCalloutMock.class, mock);
        HttpResponse res = connector.patch(req);
        System.assert(connector.isSuccess(res));

        Test.stopTest();
    }

    @IsTest
    static void testDel() {
        Request connector = new Request();
        Request.Url url = TEST_URL.clone().setPath('del');

        HttpRequest req = new HttpRequest();
        connector.setUrl(url, req);

        String stringBody = 'Test string';
        req.setBody(stringBody);

        Test.startTest();

        DelMock mock = new DelMock();
        mock.assertEndpoint = 'https://test.api.com/del';
        mock.assertBody = stringBody;

        Test.setMock(HttpCalloutMock.class, mock);
        HttpResponse res = connector.del(req);
        System.assert(connector.isSuccess(res));

        Test.stopTest();
    }

    @IsTest
    static void testNewJSONRequest() {
        Test.startTest();

        HttpRequest req = new Request()
            .newJSONRequest(
                new Map<String, Object>{ 'test' => 'example' },
                TEST_URL.clone()
            );

        System.assertEquals('{\n  "test" : "example"\n}', req.getBody());
        System.assertEquals(TEST_URL.getEndpoint(), req.getEndpoint());
        System.assertEquals('application/json', req.getHeader('Content-Type'));

        Test.stopTest();
    }

    @IsTest
    static void testMapToJSON() {
        Id testId = '0060E00000oMiz8QAC';

        Map<String, Object> testMap = new Map<String, Object>{
            'testString' => 'A string',
            'testInt' => 2,
            'testDecimal' => 2.2,
            'testBoolean' => true,
            'testId' => testId,
            'testDate' => Date.today(),
            'testNull' => null
        };

        Test.startTest();
        String jsonString = Request.mapToJSON(testMap);

        String expected =
            '{\n' +
            '  "testString" : "A string",\n' +
            '  "testInt" : 2,\n' +
            '  "testDecimal" : 2.2,\n' +
            '  "testBoolean" : true,\n' +
            '  "testId" : "' +
            testId +
            '",\n' +
            '  "testDate" : "' +
            String.valueOf(Date.today()) +
            'T00:00:00.000Z",\n' +
            '  "testNull" : null\n' +
            '}';

        System.assertEquals(expected, jsonString);
        Test.stopTest();
    }
}
