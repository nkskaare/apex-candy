@isTest
public class TestFactory {

  public List<SObject> testData { get; private set; }
  public Schema.SObjectType sObjectType { get; private set; }
  public fflib_ISObjectUnitOfWork uow { get; private set; }
  public Boolean commitData { get; private set; }

  public TestFactory() {
    this.commitData = true;
    this.uow = Application.UnitOfWork.newInstance();
  }

  public TestFactory(Boolean commitData) {
    if (commitData) {
      this();
    } else {
      this.commitData = false;
    }
  }

  public TestFactory(fflib_ISObjectUnitOfWork uow) {
    this.commitData = true;
    this.uow = uow;
  }

  public class TestFactoryException extends Exception {
  }

  public class NullAnswer implements fflib_Answer {
    public NullAnswer() {
    }

    public Object answer(fflib_InvocationOnMock invocation) {
      return null;
    }
  }

  /**
   * Generic method for adding list of sObjects to testData property
   *
   * @param sObjects list of sObjects to add to testData
   * @return this
   */
  public TestFactory createSObjects(List<SObject> sObjects) {
    this.sObjectType = sObjects.getSObjectType();
    // Workaround otherwise testData.getSObjectType() will return null in runtime
    testData = (List<SObject>) Type.forName(
        'List<' +
        String.valueOf(sObjectType) +
        '>'
      )
      .newInstance();
    testData.addAll(sObjects);
    if (commitData)
      uow.registerNew(testData);
    return this;
  }

  /**
   * Utility method. Finds child relationships of passed SObject and checks
   * if test data SObjectType is a child. Returns relationship field name
   * on child. Takes into regard whether SObject is passed as dummy data or not.
   *
   * @param sObj the SObject to find child relationships for
   * @return relationship field name
   */
  private String getRelationshipName(SObject sObj) {
    for (
      Schema.ChildRelationship childRelationship : sObj.getSObjectType()
        .getDescribe()
        .getChildRelationships()
    ) {
      if (childRelationship.getChildSObject() == this.sObjectType) {
        String childField = String.valueOf(childRelationship.getField());

        if (commitData) {
          return childField;
        } else {
          if (childField.endsWith('__c')) {
            return childField.removeEnd('__c') + '__r';
          } else if (childField.endsWith('Id')) {
            return childField.removeEnd('Id');
          }
        }
      }
    }

    throw new TestFactoryException(
      sObj.getSObjectType() +
      ' is not a parent of ' +
      this.sObjectType
    );
  }

  /**
   * Adds SObject to testData records and registers to Unit of Work
   *
   * @param sObj SObject to add to test data records
   * @return this
   */
  public TestFactory addNewSObject(SObject sObj) {
    if (commitData)
      uow.registerNew(sObj);
    return this.addSObject(sObj);
  }

  /**
   * Adds SObject to testData records and registers to Unit of Work
   *
   * @param sObj SObject to add to test data records
   * @return this
   */
  public TestFactory addNewSObject(SObject sObj, String relationShipName) {
    if (commitData)
      uow.registerNew(sObj);
    return this.addSObject(sObj, relationShipName);
  }

  /**
   * Adds SObject to test data records either as dummy data or as registered
   * relationship through Unit of Work
   *
   * @param sObj SObject added to test data
   * @return this
   */
  public TestFactory addSObject(SObject sObj) {
    String relationshipName = this.getRelationshipName(sObj);
    this.addSObject(sObj, relationshipName);
    return this;
  }

  /**
   * Adds SObject to test data records either as dummy data or as registered
   * relationship through Unit of Work
   *
   * @param sObj SObject added to test data
   * @return this
   */
  public TestFactory addSObject(SObject sObj, String relationshipName) {

    if (testData.isEmpty()) {
      throw new TestFactoryException('Test data must be created before test data can be added');
    }

    for (SObject data : testData) {
      if (commitData) {
        uow.registerRelationship(
          data,
          sObjectType.getDescribe().fields.getMap().get(relationshipName),
          sObj
        );
      } else {
        data.putSObject(relationshipName, sObj);
      }
    }
    return this;
  }

  /**
   * @return Test data created
   */
  public List<SObject> getData() {
    return this.testData;
  }

  /**
   * Commits data created to database
   *
   * @return this
   * @throws TestFactoryException
   */
  public TestFactory commitWork() {
    if (commitData) {
      uow.commitWork();
      return this;
    } else {
      throw new TestFactoryException(
        'Test Factory not initalized with commitData option'
      );
    }
  }

  /**
   * Adds mock ids to test data records
   * @return this
   */
  public TestFactory addMockId() {
    for (SObject data : testData) {
      data.put('Id', fflib_IDGenerator.generate(sObjectType));
    }
    return this;
  }

  public TestFactory addRecordType(String recordTypeName) {
    Id recordTypeId = ApplicationService.getRecordTypeId(
      recordTypeName,
      sObjectType
    );
    return this.addFieldValue('RecordTypeId', recordTypeId);
  }

  /**
   * Adds field value to all test data records
   */
  public TestFactory addFieldValue(String fieldName, Object fieldValue) {
    for (SObject record : testData) {
      record.put(fieldName, fieldValue);
    }
    return this;
  }

  /**
   * Adds field value from field values list to test data records
   */
  public TestFactory addFieldValue(String fieldName, List<Object> fieldValues) {
    if (this.testData.size() == fieldValues.size()) {
      for (Integer i = 0; i < this.testData.size(); i++) {
        this.testData[i].put(fieldName, fieldValues[i]);
      }
      return this;
    } else {
      throw new TestFactoryException(
        'Input list size unequal to TestFactory record list size'
      );
    }
  }


  /**
   * Create Accounts
   * @param numberOfRecords the number of records to create
   */
  public TestFactory createAccounts(Integer numberOfRecords) {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < numberOfRecords; i++) {
      Account acc = new Account();
      acc.Name = 'Test Account ' + i;
      accounts.add(acc);
    }
    return this.createSObjects(accounts);
  }

  /**
   * Add an account to testdata
   */
  public TestFactory addAccount() {
    Account a = new Account();
    a.Name = 'Related Account';
    return this.addSObject(a);
  }

  /**
   * Create Opportunities
   * @param numberOfRecords the number of records to create
   */
  public TestFactory createOpportunities(Integer numberOfRecords) {
    List<Opportunity> opportunityList = new List<Opportunity>();
    for (Integer i = 0; i < numberOfRecords; i++) {
      Opportunity opp = new Opportunity();
      opp.Name = 'Test Opportunity';
      opp.CloseDate = Date.today().addDays(30);
      opportunityList.add(opp);
    }
    return this.createSObjects(opportunityList);
  }


  /**
   * Create Contacts
   * @param numberOfRecords the number of records to create
   */
  public TestFactory createContacts(Integer numberOfRecords) {
    List<Contact> contactList = new List<Contact>();
    for (Integer i = 0; i < numberOfRecords; i++) {
      Contact con = new Contact();
      con.FirstName = 'Michael';
      con.LastName = 'Scott ' + i;
      con.Email = 'michael.scott.' + i + '@dundermifflin.com';
      contactList.add(con);
    }
    return this.createSObjects(contactList);
  }


  /**
   * Create Products
   * @param numberOfRecords the number of records to create
   */
  public TestFactory createProducts(Integer numberOfRecords) {
    List<Product2> productList = new List<Product2>();
    for (Integer i = 0; i < numberOfRecords; i++) {
      Product2 product = new Product2();
      product.Description = 'Test product ' + i;
      productList.add(product);
    }

    return this.createSObjects(productList);
  }


  public TestFactory createUsers(Integer numberOfRecords) {
    List<User> testUsers = new List<User>();
    for (Integer i = 0; i < numberOfRecords; i++) {
      User u = new User();
      u.Username = 'username@test.com.user' + i;
      u.Email = 'username' + i + '@test.com';
      u.LastName = 'Test';
      u.Alias = 'alias' + i;
      u.EmailEncodingKey = 'UTF-8';
      u.TimeZoneSidKey = 'America/Los_Angeles';
      u.LocaleSidKey = 'en_US';
      u.LanguageLocaleKey = 'en_US';
      testUsers.add(u);
    }
    return createSObjects(testUsers);
  }

}
