![](Codey.png)

# Apex Candy

This repository contains some useful methods to make the life of an Apex Developer easier. Classes which can be extended and methods which can be tweaked to meet your specific demands.

## Get started

Clone this repo and deploy the classes to your org. 

> Note that some of the classes are dependent on [FFlib](https://github.com/apex-enterprise-patterns/fflib-apex-mocks)

## Examples

### Request

Usage example of Request class and how to make a simple GET request against an API with the full url `https://hostname.com/end/point?param=1`, and get the returned JSON parsed into a Map.

```
  Request req = new Request('https://hostname.com/');
  req.setParameter('param', '1');
  req.get('end/point');

  Map<String, Object> res = ((Request.Response) req.response).asMap()

```

The real power of the request class is that it can be extended to easily build a simple client.

```
  class ExampleClient extends Request {

    public ExampleClient() {
      super('https://example.api.com/');
    }
    
    public void getUsers(Integer numberOfUsers) {
      this.setParameter('n', String.valueOf(numberOfUsers));
      this.get('users');
    }

  }

```

A GET call to `https://example.api.com/users?n=5` would then simply be done by

```
  ExampleClient client = new ExampleClient();
  client.getUsers(5);
  
  Map<String, Object> res = ((Request.Response) client.response).asMap();
```

### TestFactory

Simple example of how to create 5 Opportunities with an Account record on the Opportunity.Account field. When using the `mock()` method on TestFactory the created data will not be possible to commit to the database. Related objects will be added directly on the object as if retrieved through a relationship query.

```
  List<Opportunity> opps = TestFactory.mock()
    .createOpportunities(5)
    .addAccount()
    .getData();
```

If the test data should be commited to the database, the TestFactory could be instantiated by the `newInstance()` method. The same data can then be created and commited as following. 

```
  List<Opportunity> opps = TestFactory.newInstance()
    .createOpportunities(5)
    .addAccount()
    .commitWork()
    .getData();
```

### Logger

The logger class encapsulates debug messages. By using this class, resulting code is cleaner and debugging is simplified. 

```
  List<Database.Saveresults> sr = Database.insert(accounts, false);
  
  Logger log = new Logger(System.LoggingLevel.INFO);
  log.handleSave(sr);
  
```
