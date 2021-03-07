/**
 * Test data factory
 * 
 * @author nkskaare
 */
@isTest
public class TestFactory {
  static Integer mockIdCount = 0;
  static final String ID_PATTERN = '000000000000';

  Boolean commitData;
  private TestFactory(Boolean commitData) {
    this.commitData = commitData;
  }

  /**
   * Instantiator used when creating data which will be commited to database
   */
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

  /**
   * Represents a relationship between two records
   */
  private class Relationship {

    public SObject record;
    public String relatedToField;
    public SObject relatedTo;

    public Relationship(
      SObject record,
      String relatedToField,
      SObject relatedTo
    ) {
      this.record = record;
      this.relatedToField = relatedToField;
      this.relatedTo = relatedTo;
    }

    /**
     * Resolve to relationship, add parent record to record
     */
    public void resolve() {
      this.record.put(relatedToField, relatedTo.Id);
    }
  }

  /**
   * Class to register resolve relationships and orchestrate data inserting when using addSObject method with commitData
   */
  private class Relationships {
    Map<Schema.SObjectType, List<Relationship>> relations = new Map<Schema.SObjectType, List<Relationship>>();

    /**
     * Add a new relationship to the register
     * 
     * @param record the record to add relationship to
     * @param relatedToField relationship field on record
     * @param relatedTo the parent record to relate to
     */
    public void add(
      SObject record,
      String relatedToField,
      SObject relatedTo
    ) {
      Schema.SObjectType relationType = relatedTo.getSObjectType();

      Relationship rel = new Relationship(
        record,
        relatedToField,
        relatedTo
      );

      if (this.relations.containsKey(relationType)) {
        this.relations.get(relationType).add(
          rel
        );
      } else {
        this.relations.put(relationType, new List<Relationship> {rel});
      }
    }

    /**
     * Get parent records of a specific SObjectType to be 
     * inserted before resolving relationship
     * 
     * @param sObjectType
     */
    private List<SObject> getRelatedRecords(Schema.SObjectType sObjectType) {
      List<SObject> relatedRecords = new List<SObject>();
      for (Relationship rel : this.relations.get(sObjectType)) {
        relatedRecords.add(rel.relatedTo);
      }
      return relatedRecords;
    }

    /**
     * Insert registered relationship records and add the Id to test data records
     */
    public void resolve() {
      for (Schema.SObjectType sObjType : this.relations.keySet()) {
        insert getRelatedRecords(sObjType);

        for (Relationship relation : this.relations.get(sObjType)) {
          relation.resolve();
        }
      }
    }
  }



  public class DataBuilder {
    Schema.SObjectType sObjectType;
    List<SObject> testData;
    Relationships relations;

    Boolean commitData;

    public DataBuilder(
      List<SObject> sObjects,
      Schema.SObjectType sObjectType,
      Boolean commitData
    ) {
      this.commitData = commitData;
      if (commitData)
        this.relations = new Relationships();

      this.sObjectType = sObjectType;
      this.testData = sObjects;
    }

    /**
     * Adds SObject to test data records either as dummy data or as registered
     * relationship through Unit of Work. Automatically chooses first relationship
     * name returned.
     *
     * @param sObj SObject added to test data
     * @return this
     */
    public TestFactory.DataBuilder addSObject(SObject sObj) {
      String relationshipName = TestFactory.getRelationshipNames(
          sObj.getSObjectType(),
          this.sObjectType,
          this.commitData
        )
        .get(0);
      return this.addSObject(sObj, relationshipName);
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
          if (sObj.Id == null) {
            this.relations.add(data, relationshipName, sObj);
          } else {
            data.put(relationshipName, sObj);
          }
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

    /**
     * Add record type Id to test data
     *
     * @param recordType record type name
     */
    public TestFactory.DataBuilder addRecordType(String recordTypeName) {
      Id recordTypeId = this.sObjectType.getDescribe()
        .getRecordTypeInfosByName()
        .get(recordTypeName)
        .getRecordTypeId();
      return this.addFieldValue('RecordTypeId', recordTypeId);
    }

    /**
     * Adds field value to all test data records
     *
     * @param fieldName name of field
     * @param fieldValue value to put in field
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
     *
     * @param fieldName name of field
     * @param fieldValue value to put in field
     */
    public TestFactory.DataBuilder addFieldValue(
      Schema.SObjectField fieldName,
      Object fieldValue
    ) {
      return this.addFieldValue(String.valueOf(fieldName), fieldValue);
    }

    /**
     * Adds field value from field values list to test data records
     * Input list size must be equal to test data list size
     *
     * @param fieldName name of field
     * @param fieldValues values to put in field
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
     * Apply default values to field on test data
     *
     * @param fieldName name of field to apply default values
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
     * Example use to add Account to test data
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
     * @return test data
     * @throws TestFactoryException
     */
    public List<SObject> commitData() {
      if (commitData) {
        this.relations.resolve();
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
   * Utility method. Generate a mock Id for the given SObjectType.
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
   * Utility method. Finds child relationships of passed SObject and checks
   * if test data SObjectType is a child. Returns relationship field name
   * on child. Takes into regard whether SObject is passed as dummy data or not.
   *
   * @param parentType the SObjectType to find child relationships for
   * @param childType the SObjectType to find field name for
   * @param commitData
   * @return relationship field name
   */
  public static List<String> getRelationshipNames(
    Schema.SObjectType parentType,
    Schema.SObjectType childType,
    Boolean commitData
  ) {
    List<String> childFields = new List<String>();
    for (
      Schema.ChildRelationship childRelationship : parentType
        .getDescribe()
        .getChildRelationships()
    ) {
      if (childRelationship.getChildSObject() == childType) {
        String childField = String.valueOf(childRelationship.getField());

        if (!commitData) {
          if (childField.endsWith('__c')) {
            childField = childField.removeEnd('__c') + '__r';
          } else if (childField.endsWith('Id')) {
            childField = childField.removeEnd('Id');
          }
        }

        childFields.add(childField);
      }
    }

    if (childFields.isEmpty()) {
      throw new TestFactoryException(
        parentType +
        ' is not a parent of ' +
        childType
      );
    }

    return childFields;
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
