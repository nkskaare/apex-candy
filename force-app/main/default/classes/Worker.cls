/**
 * DML worker
 *
 * @author nkskaare
 */
public class Worker {
  Map<Schema.SObjectType, Register> registersByType;
  Map<Schema.SObjectType, Relationships> relationshipsByType;
  IDmlHandler dml;

  public Worker() {
    this(new SimpleDml());
  }

  public Worker(IDmlHandler dml) {
    this.dml = dml;
    this.registersByType = new Map<Schema.SObjectType, Register>();
    this.relationshipsByType = new Map<Schema.SObjectType, Relationships>();
  }

  /**
   * Static constructor which returns mock instance in test context
   */
  public static Worker newInstance() {
    if (Test.isRunningTest())
      return (Worker) Test.createStub(Worker.class, new WorkerMock());

    return new Worker();
  }

  public class RegisterException extends Exception {
  }

  /**
   * Record register. Used for records of same SObjectType.
   * Methods for adding multiple records at a time is implemented through Worker.
   */
  private virtual class Register {
    List<SObject> insertRecords = new List<SObject>();
    Map<Id, SObject> updateRecords = new Map<Id, SObject>();
    Map<Schema.SObjectField, List<SObject>> upsertRecords = new Map<Schema.SObjectField, List<SObject>>();
    Map<Id, SObject> deleteRecords = new Map<Id, SObject>();

    public Register() {
    }

    public void addInsert(SObject record) {
      if (record.Id != null)
        throw new RegisterException('Cannot register record with Id as new');

      this.insertRecords.add(record);
    }

    public List<SObject> getInserts() {
      return this.insertRecords;
    }

    public void addUpdate(SObject record) {
      if (record.Id == null)
        throw new RegisterException(
          'Cannot register record without Id as update'
        );

      this.updateRecords.put(record.Id, record);
    }

    public List<SObject> getUpdates() {
      return this.updateRecords.values();
    }

    public void addUpsert(SObject record, Schema.SObjectField field) {
      if (record.Id == null)
        throw new RegisterException(
          'Cannot register record without Id as upsert'
        );

      if (this.upsertRecords.containsKey(field)) {
        this.upsertRecords.get(field).add(record);
      } else {
        this.upsertRecords.put(field, new List<SObject>{ record });
      }
    }

    public Map<Schema.SObjectField, List<SObject>> getUpserts() {
      return this.upsertRecords;
    }

    public void addDelete(SObject record) {
      if (record.Id == null)
        throw new RegisterException(
          'Cannot register record without Id as delete'
        );

      this.deleteRecords.put(record.Id, record);
    }

    public List<SObject> getDeletes() {
      return this.deleteRecords.values();
    }
  }

  public interface IDmlHandler {
    void dmlInsert(List<SObject> records);

    void dmlUpdate(List<SObject> records);

    void dmlUpsert(Map<Schema.SObjectField, List<SObject>> recordsByField);

    void dmlDelete(List<SObject> records);
  }

  public virtual class SimpleDml implements IDmlHandler {
    public virtual void dmlInsert(List<SObject> records) {
      insert records;
    }

    public virtual void dmlUpdate(List<SObject> records) {
      update records;
    }

    public virtual void dmlUpsert(
      Map<Schema.SObjectField, List<SObject>> recordsByField
    ) {
      for (Schema.SObjectField field : recordsByField.keySet()) {
        Database.upsert(recordsByField.get(field), field);
      }
    }

    public virtual void dmlDelete(List<SObject> records) {
      delete records;
    }
  }

  public class LogDml implements IDmlHandler {
    Logger log;

    Boolean allOrNothing;
    Database.DMLOptions options;

    public LogDml() {
      this.log = new Logger();
    }

    public void dmlInsert(List<SObject> records) {
      List<Database.SaveResult> saveResults = Database.insert(records);

      log.handleSave(saveResults);
    }

    public void dmlUpdate(List<SObject> records) {
      List<Database.SaveResult> saveResults = Database.update(records);

      log.handleSave(saveResults);
    }

    public void dmlUpsert(
      Map<Schema.SObjectField, List<SObject>> recordsByField
    ) {
      List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();
      for (Schema.SObjectField field : recordsByField.keySet()) {
        upsertResults.addAll(Database.upsert(recordsByField.get(field), field));
      }

      log.handleUpsert(upsertResults);
    }

    public void dmlDelete(List<SObject> records) {
      List<Database.DeleteResult> deleteResults = Database.delete(records);

      log.handleDelete(deleteResults);
    }
  }

  public interface IRelationship {
    void resolve();
  }

  private class Relationship implements IRelationship {
    public SObject record;
    public Schema.SObjectField relationField;
    public SObject relatedTo;

    public void resolve() {
      this.record.put(this.relationField, this.relatedTo);
    }
  }

  private class Relationships {
    List<IRelationship> relations;

    public Relationships() {
      this.relations = new List<IRelationship>();
    }

    public void resolve() {
      for (IRelationship relation : this.relations) {
        relation.resolve();
      }
    }

    public void add(
      SObject record,
      Schema.SObjectField relationField,
      SObject relatedTo
    ) {
      Relationship relation = new Relationship();
      relation.record = record;
      relation.relationField = relationField;
      relation.relatedTo = relatedTo;
      this.relations.add(relation);
    }
  }

  /**
   * Return register for SObjectType
   */
  private Register getRegister(Schema.SObjectType sObjType) {
    if (this.registersByType.containsKey(sObjType)) {
      return this.registersByType.get(sObjType);
    } else {
      Register reg = new Register();
      this.registersByType.put(sObjType, reg);
      return reg;
    }
  }

  private Relationships getRelationships(Schema.SObjectType sObjType) {
    if (this.relationshipsByType.containsKey(sObjType)) {
      return this.relationshipsByType.get(sObjType);
    } else {
      Relationships relations = new Relationships();
      this.relationshipsByType.put(sObjType, relations);
      return relations;
    }
  }

  /**
   * Add new records to Register
   */
  public void registerInserts(List<SObject> records) {
    Register reg = this.getRegister(records.getSObjectType());
    for (SObject record : records) {
      reg.addInsert(record);
    }
  }

  /**
   * Add new records to Register
   */
  public void registerInsert(SObject record) {
    Register reg = this.getRegister(record.getSObjectType());
    reg.addInsert(record);
  }

  public void registerUpdates(List<SObject> records) {
    Register reg = this.getRegister(records.getSObjectType());
    for (SObject record : records) {
      reg.addUpdate(record);
    }
  }

  public void registerUpdate(SObject record) {
    Register reg = this.getRegister(record.getSObjectType());
    reg.addUpdate(record);
  }

  public void registerUpserts(List<SObject> records) {
    this.registerUpserts(
      records,
      records.getSObjectType().getDescribe().fields.getMap().get('Id')
    );
  }

  public void registerUpserts(
    List<SObject> records,
    Schema.SObjectField field
  ) {
    Register reg = this.getRegister(records.getSObjectType());
    for (SObject record : records) {
      reg.addUpsert(record, field);
    }
  }

  public void registerUpsert(SObject record) {
    this.registerUpsert(
      record,
      record.getSObjectType().getDescribe().fields.getMap().get('Id')
    );
  }

  public void registerUpsert(SObject record, Schema.SObjectField field) {
    Register reg = this.getRegister(record.getSObjectType());
    reg.addUpsert(record, field);
  }

  public void registerDelete(List<SObject> records) {
    Register reg = this.getRegister(records.getSObjectType());
    for (SObject record : records) {
      reg.addDelete(record);
    }
  }

  public void registerDelete(SObject record) {
    Register reg = this.getRegister(record.getSObjectType());
    reg.addDelete(record);
  }

  public void registerRelationship(
    SObject record,
    Schema.SObjectField relationField,
    SObject relatedTo
  ) {
    Relationships relations = this.getRelationships(record.getSObjectType());
    relations.add(record, relationField, relatedTo);
  }

  public void commitWork() {
    Savepoint sp = Database.setSavepoint();
    try {
      doInsert();
      doUpsert();
      doUpdate();
      doDelete();
    } catch (Exception e) {
      Database.rollback(sp);
      throw e;
    }
  }

  private void doInsert() {
    for (Schema.SObjectType sObjType : this.registersByType.keySet()) {
      Register reg = this.registersByType.get(sObjType);
      Relationships relations = this.relationshipsByType.get(sObjType);

      relations.resolve();

      this.dml.dmlInsert(reg.getInserts());
    }
  }

  private void doUpsert() {
    for (Register reg : this.registersByType.values()) {
      this.dml.dmlUpsert(reg.getUpserts());
    }
  }

  private void doUpdate() {
    for (Register reg : this.registersByType.values()) {
      this.dml.dmlUpdate(reg.getUpdates());
    }
  }

  private void doDelete() {
    for (Register reg : this.registersByType.values()) {
      this.dml.dmlDelete(reg.getDeletes());
    }
  }

  public class WorkerMock implements System.StubProvider {
    public Object handleMethodCall(
      Object stubbedObject,
      String stubbedMethodName,
      Type returnType,
      List<Type> listOfParamTypes,
      List<String> listOfParamNames,
      List<Object> listOfArgs
    ) {
      return null;
    }
  }
}
