![](Codey.png)

# Apex Candy

This repository contains some useful methods to make the life of an Apex Developer easier. Classes which can be extended and methods which can be tweaked to meet your specific demands.

## Get started

Clone this repo and deploy the classes to your org. 

> Note that some of the classes are dependent on [FFlib](https://github.com/apex-enterprise-patterns/fflib-apex-mocks)

> Update: This dependency has been removed, and classes now aim to not be dependent on other classes. This makes it possible to cherry-pick the classes you want to use. 

## Examples

### Request

Usage example of Request class and how to make a simple GET request against an API with the full url `https://hostname.com/end/point?param=1`, and get the returned JSON parsed into a Map.

```
  Request request = new Request();

  Request.Url url = new Url('https://hostname.com/')
    .setParameter('param', '1');
    .setPath('end/point');

  HttpRequest req = request.newRequest(url);
  HttpResponse res = request.get(req);

  Map<String, Object> res = request.getAsMap(res);

```

The real power of the request class is that it can be extended to easily build a simple client.

```
  class ExampleClient extends Request {

    Request.Url baseUrl;

    public ExampleClient() {
      this.baseUrl = new Url('https://example.api.com/');
    }
    
    public HttpResponse getUsers(Integer numberOfUsers) {
      Url usersUrl = this.baseUrl.clone()
        .setPath('users')
        .setParameter('n', String.valueOf(numberOfUsers));

      HttpRequest req = this.newRequest(usersUrl);

      return this.get(req);
    }

  }

```

A GET call to `https://example.api.com/users?n=5` would then simply be done by

```
  ExampleClient client = new ExampleClient();
  HttpResponse res = client.getUsers(5);
  
  Map<String, Object> resMap = client.getAsMap(res); 
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

### Filter

The filter class filters a list of SObjects based on the criteria you specify.

```

List<Account> dunderMifflins = (List<Account>) new Filter(accounts)
  .byField('Name')
  .equals('Dunder Mifflin')
  .run();

```
