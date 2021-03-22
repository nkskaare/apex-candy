public class ApplicationDomain {
  List<SObject> records;

  public ApplicationDomain(List<SObject> records) {
    this.records = records;
  }

  // If any of the fields are changed
  public List<SObject> hasChangedField(
    String fieldNames,
    Map<Id, SObject> oldMap,
    IChanged isChanged
  ) {
    List<SObject> changedRecords = new List<SObject>();
    if (oldMap.values().size() != this.records.size()) {
      throw new DiffSizeMyException(
        'Length of old records not equal to new records.'
      );
    }
    for (SObject record : this.records) {
        if (isChanged.check(record, oldMap, fieldName)) {
          changedRecords.add(record);
          break;
        }
    }
    return changedRecords;
  }





  // If any of the fields are changed and neither new or old value == null
  public Map<SObject, List<String>> hasUpdatedFields(
    List<String> fieldNames,
    Map<Id, SObject> oldMap
  ) {
    return hasChangedFields(fieldNames, oldMap, new IsUpdated());
  }




  // If any of the fields are removed, return them
  public Map<SObject, List<String>> hasRemovedFields(
    List<String> fieldNames,
    Map<Id, SObject> oldMap
  ) {
    return hasChangedFields(fieldNames, oldMap, new IsRemoved());
  }




  // If old value was null, and new value is not null
  public Map<SObject, List<String>> hasNewFields(
    List<String> fieldNames,
    Map<Id, SObject> oldMap
  ) {
    return hasChangedFields(fieldNames, oldMap, new IsNew());
  }


  public Map<SObject, List<String>> hasChangedFields(
    List<String> fieldNames,
    Map<Id, SObject> oldMap
  ) {
    return hasChangedFields(fieldNames, oldMap, new IsChanged());
  }
  

    // If old value was null, and new value is not null
    public Map<SObject, List<String>> hasChangedFields(
      List<String> fieldNames,
      Map<Id, SObject> oldMap,
      IChanged isChanged
    ) {
      Map<SObject, List<String>> newFieldsByRecords = new Map<SObject, List<String>>();

      for (String fieldName : fieldNames) {
        List<SObject> changedRecords = this.hasChangedField(fieldName, oldMap, isChanged);

        
        if (newFieldsByRecords.containsKey(arg0))

      }
    }


    public interface IChanged {
      Boolean check(SObject record, Map<Id, SObject> oldMap, String fieldName);
    }

    public class IsNew implements IChanged {
      
      public Boolean check(SObject record, Map<Id, SObject> oldMap, String fieldName) {
        return record.get(fieldName) != null &&
        oldMap.get(record.Id).get(fieldName) == null;
      }
    }

    public class IsUpdated implements IChanged {
      public Boolean check(SObject record, Map<Id, SObject> oldMap, String fieldName) {
        return record.get(fieldName) != oldMap.get(record.Id).get(fieldName) &&
        record.get(fieldName) != null &&
        oldMap.get(record.Id).get(fieldName) != null;
      }
    }

    public class IsRemoved implements IChanged {
      public Boolean check(SObject record, Map<Id, SObject> oldMap, String fieldName) {
        return record.get(fieldName) == null &&
        oldMap.get(record.Id).get(fieldName) != null;
      }
    }

}
