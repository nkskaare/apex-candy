@IsTest
public class ApplicationServiceTest {
  @TestSetup
  static void makeData() {
  }

  static Opportunity createTestOpportunity() {
    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opportunity';
    opp.OwnerId = fflib_IDGenerator.generate(User.SObjectType);
    return opp;
  }

  static Account createTestAccount() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    acc.Description = 'This is test account description';
    return acc;
  }

  @IsTest
  static void testWriteFromSObjectToSObject() {
    Opportunity opp = createTestOpportunity();
    Account acc = createTestAccount();
    Account acc2 = createTestAccount();

    Test.startTest();
    ApplicationService.writeFromSObjectToSObject(
      opp,
      acc,
      new Map<String, String>{
        'Name' => 'Name',
        'OwnerId' => 'OwnerId',
        'Description' => 'Description'
      }
    );

    ApplicationService.writeFromSObjectToSObject(
      opp,
      acc2,
      new Map<String, String>{
        'Name' => 'Name',
        'OwnerId' => 'OwnerId',
        'Description' => 'Description'
      },
      true
    );
    Test.stopTest();

    System.assertEquals(acc.Name, opp.Name);
    System.assertEquals(acc.OwnerId, opp.OwnerId);
    System.assertEquals(acc.Description, null);

    System.assertEquals(acc2.Name, opp.Name);
    System.assertEquals(acc2.OwnerId, opp.OwnerId);
    System.assertEquals(acc2.Description, 'This is test account description');
  }

  @IsTest
  static void testWriteFromSObjectToSObject2() {
    Opportunity opp = createTestOpportunity();
    Account acc = createTestAccount();
    Account acc2 = createTestAccount();

    Test.startTest();
    ApplicationService.writeFromSObjectToSObject(
      opp,
      acc,
      new Map<Schema.SObjectField, Schema.SObjectField>{
        Opportunity.Name => Account.Name,
        Opportunity.OwnerId => Account.OwnerId,
        Opportunity.Description => Account.Description
      }
    );

    ApplicationService.writeFromSObjectToSObject(
      opp,
      acc2,
      new Map<Schema.SObjectField, Schema.SObjectField>{
        Opportunity.Name => Account.Name,
        Opportunity.OwnerId => Account.OwnerId,
        Opportunity.Description => Account.Description
      },
      true
    );
    Test.stopTest();

    System.assertEquals(acc.Name, opp.Name);
    System.assertEquals(acc.OwnerId, opp.OwnerId);
    System.assertEquals(acc.Description, null);

    System.assertEquals(acc2.Name, opp.Name);
    System.assertEquals(acc2.OwnerId, opp.OwnerId);
    System.assertEquals(acc2.Description, 'This is test account description');
  }

  @IsTest
  static void testCreateEmpty() {
    Integer n = 10;

    Test.startTest();
    List<SObject> sObjects = ApplicationService.createEmpty(
      n,
      Account.SObjectType
    );
    Test.stopTest();

    System.assertEquals(n, sObjects.size());
    System.debug(sObjects.getSObjectType());
    System.assertEquals(Account.SObjectType, sObjects[0].getSObjectType());
  }

  @IsTest
  static void testGetSObjectsByFieldValue() {
    Integer n = 10;
    List<Opportunity> opps = new List<Opportunity>();
    List<String> names = new List<String>();

    for (Integer i = 0; i < n; i++) {
      Opportunity opp = new Opportunity();
      String name = 'Test Opportunity ' + i;
      opp.Name = name;
      opp.Id = fflib_IDGenerator.generate(Opportunity.SObjectType);
      opps.add(opp);
      names.add(name);
    }

    Test.startTest();
    Map<String, Opportunity> oppsByName = (Map<String, Opportunity>) ApplicationService.getSObjectsByField(
      opps,
      'Name'
    );

    Map<String, Opportunity> oppsByName2 = (Map<String, Opportunity>) ApplicationService.getSObjectsByField(
      opps,
      Opportunity.Name
    );
    Test.stopTest();

    System.assertEquals(n, oppsByName.size());
    System.assert(oppsByName.keySet().containsAll(names));
    System.assertEquals(
      Opportunity.SObjectType,
      oppsByName.values()[0].getSObjectType()
    );

    System.assertEquals(n, oppsByName2.size());
    System.assert(oppsByName2.keySet().containsAll(names));
    System.assertEquals(
      Opportunity.SObjectType,
      oppsByName2.values()[0].getSObjectType()
    );
  }

  @IsTest
  static void testGetFieldValues() {
    Integer n = 10;
    List<Opportunity> opps = new List<Opportunity>();
    List<String> names = new List<String>();
    List<Id> ids = new List<Id>();

    for (Integer i = 0; i < n; i++) {
      Opportunity opp = new Opportunity();
      String name = 'Test Opportunity ' + i;
      opp.Name = name;
      opp.Id = fflib_IDGenerator.generate(Opportunity.SObjectType);
      opps.add(opp);
      names.add(name);
      ids.add(opp.Id);
    }

    Test.startTest();
    List<String> extractedNames = (List<String>) ApplicationService.getFieldValues(
      opps,
      'Name'
    );
    List<String> extractedNames2 = (List<String>) ApplicationService.getFieldValues(
      opps,
      Opportunity.Name
    );
    List<Id> extractedIds = (List<Id>) ApplicationService.getFieldValues(
      opps,
      'Id'
    );
    Test.stopTest();

    System.assertEquals(extractedNames, names);
    System.assertEquals(extractedNames2, names);
    System.assertEquals(extractedIds, ids);
  }

  @IsTest
  static void testMapToJSON() {
    Id testId = fflib_IDGenerator.generate(Opportunity.SObjectType);

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
    String jsonString = ApplicationService.mapToJSON(testMap);

    String expected =
      '{\n' +
      '  "testString" : "A string",\n' +
      '  "testInt" : 2,\n' +
      '  "testDecimal" : 2.2,\n' +
      '  "testBoolean" : true,\n' +
      '  "testId" : "' + testId + '",\n' +
      '  "testDate" : "' + String.valueOf(Date.today()) + 'T00:00:00.000Z",\n' +
      '  "testNull" : null\n' +
      '}';

    System.assertEquals(expected, jsonString);
    Test.stopTest();
  }
}
