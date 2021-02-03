/**
 * Application general service class and utility methods
 */
public virtual class ApplicationService {
  public ApplicationService() {
  }

  public class ApplicationServiceException extends Exception {
  }

  /**
   * Mapping of field display types to Apex type
   */
  public static final Map<Schema.DisplayType, Type> typeByDisplayType = new Map<Schema.DisplayType, Type>{
    Schema.DisplayType.ADDRESS => String.class,
    Schema.DisplayType.ANYTYPE => String.class,
    Schema.DisplayType.BASE64 => String.class,
    Schema.DisplayType.BOOLEAN => Boolean.class,
    Schema.DisplayType.COMBOBOX => String.class,
    Schema.DisplayType.CURRENCY => Double.class,
    Schema.DisplayType.DATACATEGORYGROUPREFERENCE => String.class,
    Schema.DisplayType.DATE => Date.class,
    Schema.DisplayType.DATETIME => String.class,
    Schema.DisplayType.EMAIL => String.class,
    Schema.DisplayType.ENCRYPTEDSTRING => String.class,
    Schema.DisplayType.DOUBLE => Double.class,
    Schema.DisplayType.ID => Id.class,
    Schema.DisplayType.INTEGER => Integer.class,
    Schema.DisplayType.LONG => Long.class,
    Schema.DisplayType.MULTIPICKLIST => String.class,
    Schema.DisplayType.PERCENT => Double.class,
    Schema.DisplayType.PHONE => String.class,
    Schema.DisplayType.PICKLIST => String.class,
    Schema.DisplayType.REFERENCE => Id.class,
    Schema.DisplayType.STRING => String.class,
    Schema.DisplayType.TEXTAREA => String.class,
    Schema.DisplayType.TIME => String.class,
    Schema.DisplayType.URL => String.class
  };

  public static Map<String, Schema.RecordTypeInfo> getRecordTypeInfos(
    Schema.SObjectType sObjectType
  ) {
    return sObjectType.getDescribe().getRecordTypeInfosByName();
  }

  public static Id getRecordTypeId(
    String recordTypeName,
    Schema.SObjectType sObjectType
  ) {
    try {
      return getRecordTypeInfos(sObjectType)
        .get(recordTypeName)
        .getRecordTypeId();
    } catch (NullPointerException e) {
      throw new ApplicationServiceException(
        'Invalid record type name or sObjectType'
      );
    }
  }

  public static List<SObject> createEmpty(
    Integer n,
    Schema.SObjectType sObjectType
  ) {
    List<SObject> sObjects = (List<SObject>) Type.forName(
        'List<' +
        sObjectType +
        '>'
      )
      .newInstance();
    for (Integer i = 0; i < n; i++) {
      sObjects.add(sObjectType.newSObject());
    }
    return sObjects;
  }

  /**
   * Gets a map with field value as key and sObject as value
   *
   * @param sObjects List of sObjects
   * @param field the field to get field value from
   *
   * @return field value => sObject map
   */
  public static Map<String, SObject> getSObjectsByField(
    List<SObject> sObjects,
    String field
  ) {
    Map<String, SObject> sObjectMap = (Map<String, SObject>) Type.forName(
        'Map<String,' +
        sObjects.getSObjectType() +
        '>'
      )
      .newInstance();
    for (SObject sObj : sObjects) {
      if (sObj.isSet(field)) {
        sObjectMap.put(String.valueOf(sObj.get(field)), sObj);
      }
    }
    return sObjectMap;
  }

  public static Map<String, SObject> getSObjectsByField(
    List<SObject> sObjects,
    Schema.SObjectField field
  ) {
    return getSObjectsByField(sObjects, String.valueOf(field));
  }

  /**
   * Extracts a list of field values form a list of sObjects
   *
   * @param sObjects List of sObjects to extract field values from
   * @param fields field to extract
   *
   * @return list of field values
   */
  public static List<Object> getFieldValues(
    List<SObject> sObjects,
    String field
  ) {
    Schema.DisplayType displayType = sObjects.getSObjectType()
      .getDescribe()
      .fields.getMap()
      .get(field)
      .getDescribe()
      .getType();

    Type fieldType = typeByDisplayType.get(displayType);
    Type listType = Type.forName('List<' + fieldType.getName() + '>');

    List<Object> fieldValues = (List<Object>) listType.newInstance();

    for (SObject sObj : sObjects) {
      if (sObj.isSet(field)) {
        fieldValues.add(sObj.get(field));
      }
    }
    return fieldValues;
  }

  public static List<Object> getFieldValues(
    List<SObject> sObjects,
    Schema.SObjectField field
  ) {
    return getFieldValues(sObjects, String.valueOf(field));
  }

  /**
   * Writes data from one SObject to another according to field mapping
   *
   * @param fromSObject the SObject to write data from
   * @param toSObject the SObject to write data to
   * @param fieldMapping mapping fromSObject.Field => toSObject.Field
   * @param nullCheck true -> not overwrite toSObject.Field with null values
   */
  public static void writeFromSObjectToSObject(
    SObject fromSObject,
    SObject toSObject,
    Map<String, String> fieldMapping,
    Boolean nullCheck
  ) {
    for (String fromField : fieldMapping.keySet()) {
      String toField = fieldMapping.get(fromField);
      Object fieldValue = fromSObject.get(fromField);
      if (!(nullCheck && fieldValue == null)) {
        toSObject.put(toField, fieldValue);
      }
    }
  }
  public static void writeFromSObjectToSObject(
    SObject fromSObject,
    SObject toSObject,
    Map<String, String> fieldMapping
  ) {
    writeFromSObjectToSObject(fromSObject, toSObject, fieldMapping, false);
  }

  /**
   * Writes data from one SObject to another accordin to field mapping
   *
   * @param fromSObject the SObject to write data from
   * @param toSObject the SObject to write data to
   * @param fieldMapping mapping fromSObject.Field => toSObject.Field
   */
  public static void writeFromSObjectToSObject(
    SObject fromSObject,
    SObject toSObject,
    Map<Schema.SObjectField, Schema.SObjectField> fieldMapping,
    Boolean nullCheck
  ) {
    for (Schema.SObjectField fromField : fieldMapping.keySet()) {
      Schema.SObjectField toField = fieldMapping.get(fromField);
      Object fieldValue = fromSObject.get(fromField);
      if (!(nullCheck && fieldValue == null)) {
        toSObject.put(toField, fieldValue);
      }
    }
  }
  public static void writeFromSObjectToSObject(
    SObject fromSObject,
    SObject toSObject,
    Map<Schema.SObjectField, Schema.SObjectField> fieldMapping
  ) {
    writeFromSObjectToSObject(fromSObject, toSObject, fieldMapping, false);
  }

  /**
   * Writes data from one SObject to another accordin to field mapping
   *
   * @param fromSObject the SObject to write data from
   * @param toSObject the SObject to write data to
   * @param fieldMapping mapping fromSObject.Field => toSObject.Field
   */
  public static void writeFromSObjectTypeToSObjectType(
    SObject fromSObject,
    SObject toSObject,
    Map<String, String> fieldMapping
  ) {
    for (String fromField : fieldMapping.keySet()) {
      String toField = fieldMapping.get(fromField);
      toSObject.putSObject(toField, fromSObject.getSObject(fromField));
    }
  }

  /**
   * Converts a map of different datatypes, but depth of 1, to a JSON string
   *
   * @param dataMap
   */
  public static String mapToJSON(Map<String, Object> dataMap) {
    JSONGenerator generator = JSON.createGenerator(true);

    generator.writeStartObject();
    for (String field : dataMap.keySet()) {
      Object value = dataMap.get(field);

      if (value instanceof String) {
        generator.writeStringField(field, (String) value);
      } else if (value instanceof Integer) {
        generator.writeNumberField(field, (Integer) value);
      } else if (value instanceof Decimal) {
        generator.writeNumberField(field, (Decimal) value);
      } else if (value instanceof Long) {
        generator.writeNumberField(field, (Long) value);
      } else if (value instanceof Id) {
        generator.writeIdField(field, (Id) value);
      } else if (value instanceof Boolean) {
        generator.writeBooleanField(field, (Boolean) value);
      } else if (value instanceof Datetime) {
        generator.writeDateTimeField(field, (Datetime) value);
      } else if (value instanceof Date) {
        generator.writeDateField(field, (Date) value);
      } else if (value != null) {
        generator.writeObjectField(field, value);
      } else {
        generator.writeNullField(field);
      }
    }
    generator.writeEndObject();

    generator.close();
    return generator.getAsString();
  }
}
