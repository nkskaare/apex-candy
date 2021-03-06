/**
 * DML worker
 */
public class Worker {
  Map<Schema.SObjectType, Register> registersByType;
  IDmlHandler dml;

  public Worker() {
    this(new SimpleDml());
  }

  public Worker(IDmlHandler dml) {
    this.dml = dml;
    this.registersByType = new Map<Schema.SObjectType, Register>();
  }

  public class RegisterException extends Exception {
  }

  private class Register {
    List<SObject> newRecords = new List<SObject>();
    Map<Id, SObject> updateRecords = new Map<Id, SObject>();
    Map<Schema.SObjectField, List<SObject>> upsertRecords = new Map<Schema.SObjectField, List<SObject>>();
    Map<Id, SObject> deleteRecords = new Map<Id, SObject>();

    public Register() {
    }

    public void addNew(SObject record) {
      if (record.Id != null)
        throw new RegisterException('Cannot register record with Id as new');

      this.newRecords.add(record);
    }

    // public void addNew(List<SObject> records) {
    //   for (SObject record : records) {
    //     this.addNew(record);
    //   }
    // }

    public List<SObject> getNews() {
      return this.newRecords;
    }

    public void addUpdate(SObject record) {
      if (record.Id == null)
        throw new RegisterException(
          'Cannot register record without Id as update'
        );

      this.updateRecords.put(record.Id, record);
    }

    public void addUpdate(List<SObject> records) {
      for (SObject record : records) {
        this.addUpdate(record);
      }
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

    public void addUpsert(List<SObject> records, Schema.SObjectField field) {
      for (SObject record : records) {
        this.addUpsert(record, field);
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

    public void addDelete(List<SObject> records) {
      for (SObject record : records) {
        this.addDelete(record);
      }
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

  /**
   * Add new records to Register
   */
  public void registerNew(List<SObject> records) {
    Register reg = this.getRegister(records.getSObjectType());
    for (SObject record : records) {
      reg.addNew(record);
    }
  }

  /**
   * Add new records to Register
   */
  public void registerNew(SObject record) {
    Register reg = this.getRegister(record.getSObjectType());
    reg.addNew(record);
  }

  public void registerUpdate(List<SObject> records) {
    Register reg = this.getRegister(records.getSObjectType());
    for (SObject record : records) {
      reg.addUpdate(record);
    }
  }

  public void registerUpdate(SObject record) {
    Register reg = this.getRegister(record.getSObjectType());
    reg.addUpdate(record);
  }

  public void registerUpdate(List<SObject> records) {
    Register reg = this.getRegister(records.getSObjectType());
    for (SObject record : records) {
      reg.addUpdate(record);
    }
  }

  public void registerUpdate(SObject record) {
    Register reg = this.getRegister(record.getSObjectType());
    reg.addUpdate(record);
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

  public void commitWork() {
    dmlInsert();
    dmlUpsert();
    dmlUpdate();
    dmlDelete();
  }

  private void dmlInsert() {
    for (Register reg : this.registersByType.values()) {
      this.dml.dmlInsert(reg.getNews());
    }
  }

  private void dmlUpsert() {
    for (Register reg : this.registersByType.values()) {
      this.dml.dmlUpsert(reg.getUpserts());
    }
  }

  private void dmlUpdate() {
    for (Register reg : this.registersByType.values()) {
      this.dml.dmlUpdate(reg.getUpdates());
    }
  }

  private void dmlDelete() {
    for (Register reg : this.registersByType.values()) {
      this.dml.dmlDelete(reg.getDeletes());
    }
  }
}
