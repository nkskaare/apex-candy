![alt text](https://www.salesforce.com/news/wp-content/uploads/sites/3/2020/08/Codey.png)

# Apex Candy

This repository contains some useful methods to make the life of an Apex Developer easier. Classes which can be extended and methods which can be tweaked to meet your specific demands.

### Get started

Clone this repo and deploy the classes to your org. 

> Note that some of the classes are dependent on ![FFlib](https://github.com/apex-enterprise-patterns/fflib-apex-mocks)

### Examples

#### Request

Usage example of Request class and how to make a simple GET request against an API with the full url 'https://hostname.com/end/point?param=1', and get the returned JSON parsed into a Map.

```
  Request req = new Request('https://hostname.com/');
  req.setParameter('param', '1');
  req.get('end/point');

  Map<String, Object> res = ((Request.Response) req.response).asMap()

```

The real power of the request class is that it can be extended to easily build a simple client.

```
  class TestClient extends Request {

    public TestClient() {
      super('https://test.api.com/');
    }
    
    public void getUsers(Integer numberOfUsers) {
      this.setParameter('n', String.valueOf(numberOfUsers));
      this.get('users');
    }

  }

```

A http call equivalent to 'https://test.api.com/users?n=5' would then simply be done by

```
  TestClient client = new TestClient();
  client.getUsers();
  
  Map<String, Object> res = ((Request.Response) client.response).asMap();
```

#### TestFactory

Simple example of how to create 5 Opportunities with an Account record on the Opportunity.Account field.

```
  List<Opportunity> opps = TestFactory.mock()
    .createOpportunities(5)
    .addAccount()
    .getData();
```
