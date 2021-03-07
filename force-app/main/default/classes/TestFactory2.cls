/**
 * Test Factory with FFlib UnitOfWork support
 */
@isTest
public class TestFactory2 {
  public fflib_ISObjectUnitOfWork uow { get; private set; }

  private TestFactory2() {
  }

  private TestFactory2(fflib_ISObjectUnitOfWork uow) {
    this.uow = uow;
  }

  /**
   * Instantiator used when creating data which will be commited to database
   */
  public static TestFactory2 newInstance() {
    return new TestFactory2(Application.UnitOfWork.newInstance());
  }

  /**
   * Instantiator used when creating data which will be commited to database
   * Pass an already instance of UnitOfWork
   *
   * @param uow UnitOfWork
   */
  public static TestFactory2 newInstance(fflib_ISObjectUnitOfWork uow) {
    return new TestFactory2(uow);
  }

  /**
   * Instantiator used when creating data which will NOT be commited to database
   */
  public static TestFactory2 mock() {
    return new TestFactory2();
  }

  public class TestFactory2Exception extends Exception {
  }

  public class DataBuilderException extends Exception {
  }

  public class NullAnswer implements fflib_Answer {
    public NullAnswer() {
    }

    public Object answer(fflib_InvocationOnMock invocation) {
      return null;
    }
  }

  public class DataBuilder {
    Schema.SObjectType sObjectType;
    List<SObject> testData;
    fflib_ISObjectUnitOfWork worker;

    Boolean commitData;

    public DataBuilder(
      List<SObject> sObjects,
      Schema.SObjectType sObjectType,
      fflib_ISObjectUnitOfWork worker
    ) {
      if (worker != null) {
        this.worker = worker;
        this.commitData = true;
      } else {
        this.commitData = false;
      }

      // Workaround otherwise testData.getSObjectType() will return null in runtime
      this.sObjectType = sObjectType;
      this.testData = (List<SObject>) Type.forName(
          'List<' +
          String.valueOf(sObjectType) +
          '>'
        )
        .newInstance();
      this.testData.addAll(sObjects);
    }

    /**
     * Adds SObject to testData records and registers to Unit of Work
     *
     * @param sObj SObject to add to test data records
     * @return this
     */
    public TestFactory2.DataBuilder addNewSObject(SObject sObj) {
      if (commitData)
        worker.registerNew(sObj);
      return this.addSObject(sObj);
    }

    /**
     * Adds SObject to testData records and registers to Unit of Work
     *
     * @param sObj SObject to add to test data records
     * @return this
     */
    public TestFactory2.DataBuilder addNewSObject(
      SObject sObj,
      String relationShipName
    ) {
      if (commitData)
        worker.registerNew(sObj);
      return this.addSObject(sObj, relationShipName);
    }

    /**
     * Adds SObject to test data records either as dummy data or as registered
     * relationship through Unit of Work
     *
     * @param sObj SObject added to test data
     * @return this
     */
    public TestFactory2.DataBuilder addSObject(SObject sObj) {
      String relationshipName = TestFactory2.getRelationshipName(
        sObj,
        this.commitData
      );
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
    public TestFactory2.DataBuilder addSObject(
      SObject sObj,
      String relationshipName
    ) {
      for (SObject data : this.testData) {
        if (this.commitData) {
          worker.registerRelationship(
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
     * Adds mock ids to test data records
     * @return this
     */
    public TestFactory2.DataBuilder addMockId() {
      if (this.commitData) {
        throw new TestFactory2.DataBuilderException(
          'Cannot add mock Id when committing data'
        );
      }
      for (SObject data : this.testData) {
        data.put('Id', fflib_IDGenerator.generate(this.sObjectType));
      }
      return this;
    }

    public TestFactory2.DataBuilder addRecordType(String recordTypeName) {
      Id recordTypeId = ApplicationService.getRecordTypeId(
        recordTypeName,
        this.sObjectType
      );
      return this.addFieldValue('RecordTypeId', recordTypeId);
    }

    /**
     * Adds field value to all test data records
     */
    public TestFactory2.DataBuilder addFieldValue(
      String fieldName,
      Object fieldValue
    ) {
      for (SObject record : this.testData) {
        record.put(fieldName, fieldValue);
      }
      return this;
    }

    /**
     * Adds field value to all test data records
     */
    public TestFactory2.DataBuilder addFieldValue(
      Schema.SObjectField fieldName,
      Object fieldValue
    ) {
      return this.addFieldValue(String.valueOf(fieldName), fieldValue);
    }

    /**
     * Adds field value from field values list to test data records
     */
    public TestFactory2.DataBuilder addFieldValue(
      String fieldName,
      List<Object> fieldValues
    ) {
      if (this.testData.size() == fieldValues.size()) {
        for (Integer i = 0; i < this.testData.size(); i++) {
          this.testData[i].put(fieldName, fieldValues[i]);
        }
        return this;
      } else {
        throw new TestFactory2.DataBuilderException(
          'Input list size unequal to DataBuilder record list size'
        );
      }
    }

    /**
     * Apply default values to field on testData
     */
    public TestFactory2.DataBuilder applyDefault(Schema.SObjectField field) {
      Object defaultValue = field.getDescribe().getDefaultValue();
      for (SObject record : this.testData) {
        record.put(field, defaultValue);
      }
      return this;
    }

    /**
     * Apply defult values to all fields which are not set
     */
    public TestFactory2.DataBuilder applyDefaults() {
      for (SObject record : this.testData) {
        for (
          Schema.SObjectField field : this.sObjectType.getDescribe()
            .fields.getMap()
            .values()
        ) {
          Object defaultValue = field.getDescribe().getDefaultValue();

          if (!record.isSet(field)) {
            record.put(field, defaultValue);
          }
        }
      }
      return this;
    }

    /**
     * Add an account to testdata
     */
    public TestFactory2.DataBuilder addAccount() {
      Account a = new Account();
      a.Name = 'Related Account';
      return this.addSObject(a);
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
     * @throws TestFactory2Exception
     */
    public List<SObject> commitWork() {
      if (commitData) {
        worker.commitWork();
        return this.testData;
      } else {
        throw new TestFactory2.DataBuilderException(
          'Cannot commit data when creating mock data'
        );
      }
    }
  }

  /**
   * Generic method for adding list of sObjects to testData property
   *
   * @param sObjects list of sObjects to add to testData
   * @return this
   */
  public TestFactory2.DataBuilder createSObjects(List<SObject> sObjects) {
    return new TestFactory2.DataBuilder(
      sObjects,
      sObjects.getSObjectType(),
      this.uow
    );
  }

  /**
   * Utility method. Finds child relationships of passed SObject and checks
   * if test data SObjectType is a child. Returns relationship field name
   * on child. Takes into regard whether SObject is passed as dummy data or not.
   *
   * @param sObj the SObject to find child relationships for
   * @return relationship field name
   */
  public static String getRelationshipName(SObject sObj, Boolean commitData) {
    Schema.SObjectType sObjectType = sObj.getSObjectType();
    for (
      Schema.ChildRelationship childRelationship : sObjectType
        .getDescribe()
        .getChildRelationships()
    ) {
      if (childRelationship.getChildSObject() == sObjectType) {
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

    throw new TestFactory2Exception(
      sObj.getSObjectType() +
      ' is not a parent of ' +
      sObjectType
    );
  }

  /**
   * Create Accounts
   * @param numberOfRecords the number of records to create
   */
  public TestFactory2.DataBuilder createAccounts(Integer numberOfRecords) {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < numberOfRecords; i++) {
      Account acc = new Account();
      acc.Name = 'Test Account ' + i;
      accounts.add(acc);
    }
    return this.createSObjects(accounts);
  }

  /**
   * Create Opportunities
   * @param numberOfRecords the number of records to create
   */
  public TestFactory2.DataBuilder createOpportunities(Integer numberOfRecords) {
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
  public TestFactory2.DataBuilder createContacts(Integer numberOfRecords) {
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
  public TestFactory2.DataBuilder createProducts(Integer numberOfRecords) {
    List<Product2> productList = new List<Product2>();
    for (Integer i = 0; i < numberOfRecords; i++) {
      Product2 product = new Product2();
      product.Description = 'Test product ' + i;
      productList.add(product);
    }

    return this.createSObjects(productList);
  }

  public TestFactory2.DataBuilder createUsers(Integer numberOfRecords) {
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
