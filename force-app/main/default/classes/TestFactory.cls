@isTest
public class TestFactory {
  static Integer mockIdCount = 0;
  static final String ID_PATTERN = '000000000000';

  Boolean commitData;
  private TestFactory(Boolean commitData) {
    this.commitData = commitData;
  }

  public static TestFactory newInstance() {
    return new TestFactory(true);
  }

  /**
   * Instantiator used when creating data which will NOT be commited to database
   */
  public static TestFactory mock() {
    return new TestFactory(false);
  }

  public class TestFactoryException extends Exception {
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

    Boolean commitData;
    IDGenerator idGenerator;

    public DataBuilder(
      List<SObject> sObjects,
      Schema.SObjectType sObjectType,
      Boolean commitData
    ) {
      this.commitData = commitData;

      this.sObjectType = sObjectType;
      this.testData = sObjects;
    }

    /**
     * Adds SObject to test data records either as dummy data or as registered
     * relationship through Unit of Work
     *
     * @param sObj SObject added to test data
     * @return this
     */
    public TestFactory.DataBuilder addSObject(SObject sObj) {
      String relationshipName = TestFactory.getRelationshipName(
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
    public TestFactory.DataBuilder addSObject(
      SObject sObj,
      String relationshipName
    ) {
      for (SObject data : this.testData) {
        if (this.commitData) {
          if (sObj.Id == null)
            throw new TestFactory.DataBuilderException(
              'SObject added must have a valid Id when committing data'
            );
          data.put(relationShipName, sObj.Id);
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
    public TestFactory.DataBuilder addMockId() {
      if (this.commitData) {
        throw new TestFactory.DataBuilderException(
          'Cannot add mock Id when committing data'
        );
      }
      for (SObject data : this.testData) {
        data.Id = TestFactory.generateMockId(this.sObjectType);
      }
      return this;
    }

    public TestFactory.DataBuilder addRecordType(String recordTypeName) {
      Id recordTypeId = ApplicationService.getRecordTypeId(
        recordTypeName,
        this.sObjectType
      );
      return this.addFieldValue('RecordTypeId', recordTypeId);
    }

    /**
     * Adds field value to all test data records
     */
    public TestFactory.DataBuilder addFieldValue(
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
    public TestFactory.DataBuilder addFieldValue(
      Schema.SObjectField fieldName,
      Object fieldValue
    ) {
      return this.addFieldValue(String.valueOf(fieldName), fieldValue);
    }

    /**
     * Adds field value from field values list to test data records
     */
    public TestFactory.DataBuilder addFieldValue(
      String fieldName,
      List<Object> fieldValues
    ) {
      if (this.testData.size() == fieldValues.size()) {
        for (Integer i = 0; i < this.testData.size(); i++) {
          this.testData[i].put(fieldName, fieldValues[i]);
        }
        return this;
      } else {
        throw new TestFactory.DataBuilderException(
          'Input list size unequal to DataBuilder record list size'
        );
      }
    }

    /**
     * Apply default values to field on testData
     */
    public TestFactory.DataBuilder applyDefault(Schema.SObjectField field) {
      Object defaultValue = field.getDescribe().getDefaultValue();
      for (SObject record : this.testData) {
        record.put(field, defaultValue);
      }
      return this;
    }

    /**
     * Apply defult values to all fields which are not set
     */
    public TestFactory.DataBuilder applyDefaults() {
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
    public TestFactory.DataBuilder addAccount() {
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
     * @throws TestFactoryException
     */
    public List<SObject> commitData() {
      if (commitData) {
        insert this.testData;
        return this.testData;
      } else {
        throw new TestFactory.DataBuilderException(
          'Cannot commit data when creating mock data'
        );
      }
    }
  }

  /**
   * Generate a mock Id for the given SObjectType
   *
   * @param sObjectType
   */
  public static Id generateMockId(Schema.SObjectType sObjectType) {
    String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
    mockIdCount++;

    String mockIdPrefix = ID_PATTERN.substring(
      0,
      12 - String.valueOf(mockIdCount).length()
    );

    return Id.valueOf(keyPrefix + mockIdPrefix + mockIdCount);
  }

  /**
   * Generic method for adding list of sObjects to testData property
   *
   * @param sObjects list of sObjects to add to testData
   * @return this
   */
  public TestFactory.DataBuilder createSObjects(List<SObject> sObjects) {
    return new TestFactory.DataBuilder(
      sObjects,
      sObjects.getSObjectType(),
      this.commitData
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

    throw new TestFactoryException(
      sObj.getSObjectType() +
      ' is not a parent of ' +
      sObjectType
    );
  }

  /**
   * Create Accounts
   * @param numberOfRecords the number of records to create
   */
  public TestFactory.DataBuilder createAccounts(Integer numberOfRecords) {
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
  public TestFactory.DataBuilder createOpportunities(Integer numberOfRecords) {
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
  public TestFactory.DataBuilder createContacts(Integer numberOfRecords) {
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
  public TestFactory.DataBuilder createProducts(Integer numberOfRecords) {
    List<Product2> productList = new List<Product2>();
    for (Integer i = 0; i < numberOfRecords; i++) {
      Product2 product = new Product2();
      product.Description = 'Test product ' + i;
      productList.add(product);
    }

    return this.createSObjects(productList);
  }

  public TestFactory.DataBuilder createUsers(Integer numberOfRecords) {
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
