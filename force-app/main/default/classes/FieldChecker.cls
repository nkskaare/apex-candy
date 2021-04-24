/**
 * Class for checking if fields is changed on a list of records
 */
public class FieldChecker {
    public List<SObject> records;
    public List<String> fields;
    public Boolean all = false;
    public ICheck checker;

    /**
     * @param records Records to check values on
     */
    public FieldChecker(List<SObject> records) {
        this.records = records;
    }

    /**
     * @param records Records to check values on
     * @param fields Fields to check values of
     */
    public FieldChecker(List<SObject> records, List<String> fields) {
        this(records);
        this.fields = fields;
    }

    /**
     * @param fields Fields to check values of
     */
    public void setFields(List<String> fields) {
        this.fields = fields;
    }

    public List<String> getFields() {
        return this.fields;
    }

    /**
     * Set the 'all' parameter to true. This determines whether all input
     * fields must fulfill the check condition to be a valid result.
     */
    public void setAll() {
        this.all = true;
    }

    public void setChecker(ICheck checker) {
        this.checker = checker;
    }

    public ICheck getChecker() {
        return this.checker;
    }

    public List<SObject> getRecords() {
        return this.records;
    }

    /**
     * Check fields on records against oldMap for any changed values or null values
     * defined by checker
     *
     * @param fieldChecker a FieldChecker instance containing checking configuration
     */
    public static FieldChecker.Results check(FieldChecker checkerConfig) {
        Results checkResults = new Results();

        for (SObject record : checkerConfig.getRecords()) {
            Result checkResult = new Result();

            Boolean result = checkerConfig.all;
            for (String field : checkerConfig.getFields()) {
                Boolean valid = checkerConfig.getChecker().check(record, field);

                if (valid) {
                    checkResult.addField(field);
                }

                if (checkerConfig.all) {
                    result = result && valid;
                } else {
                    result = result || valid;
                }
            }

            if (result) {
                checkResult.setSObject(record);
                checkResults.addResult(checkResult);
            }
        }

        return checkResults;
    }

    /**
     * A check result, the SObject checked and fields fulfilling check
     */
    public class Result {
        public SObject record;
        public List<String> checkedFields = new List<String>();

        public void setSObject(SObject record) {
            this.record = record;
        }

        public void addField(String field) {
            this.checkedFields.add(field);
        }
    }

    /**
     * Wrapper class for List of result and SObjects
     */
    public class Results {
        List<Result> checkResults = new List<Result>();
        List<SObject> records = new List<SObject>();

        public List<SObject> getRecords() {
            return this.records;
        }

        public List<Result> getResults() {
            return this.checkResults;
        }

        public void addResult(Result checkResult) {
            this.checkResults.add(checkResult);
            this.records.add(checkResult.record);
        }
    }

    /**
     * ICheck interface
     */
    public interface ICheck {
        Boolean check(SObject record, String field);
    }

    /**
     * Check if fields are new compared to oldMap
     */
    public class IsNew implements ICheck {
        Map<Id, SObject> oldMap;

        public IsNew(Map<Id, SObject> oldMap) {
            this.oldMap = oldMap;
        }

        public Boolean check(SObject record, String field) {
            SObject oldRecord = this.oldMap.get(record.Id);
            if (oldRecord == null)
                throw new ApplicationDomain.DomainException(
                    'Unable to perform IsNew check. No old record available'
                );
            return record.get(field) != null && oldRecord.get(field) == null;
        }
    }

    /**
     * Check if fields are updated compared to oldMap
     */
    public class IsUpdated implements ICheck {
        Map<Id, SObject> oldMap;

        public IsUpdated(Map<Id, SObject> oldMap) {
            this.oldMap = oldMap;
        }

        public Boolean check(SObject record, String field) {
            SObject oldRecord = this.oldMap.get(record.Id);
            if (oldRecord == null)
                throw new ApplicationDomain.DomainException(
                    'Unable to perform IsUpdated check. No old record available'
                );
            return record.get(field) != oldRecord.get(field) &&
                record.get(field) != null &&
                oldRecord.get(field) != null;
        }
    }

    /**
     * Check if fields are deleted compared to oldMap
     */
    public class IsDeleted implements ICheck {
        Map<Id, SObject> oldMap;

        public IsDeleted(Map<Id, SObject> oldMap) {
            this.oldMap = oldMap;
        }

        public Boolean check(SObject record, String field) {
            SObject oldRecord = this.oldMap.get(record.Id);
            if (oldRecord == null)
                throw new ApplicationDomain.DomainException(
                    'Unable to perform IsDeleted check. No old record available'
                );
            return record.get(field) == null && oldRecord.get(field) != null;
        }
    }

    /**
     * Check if fields are changed compared to oldMap
     */
    public class IsChanged implements ICheck {
        Map<Id, SObject> oldMap;

        public IsChanged(Map<Id, SObject> oldMap) {
            this.oldMap = oldMap;
        }

        public Boolean check(SObject record, String field) {
            SObject oldRecord = this.oldMap.get(record.Id);
            if (oldRecord == null)
                throw new ApplicationDomain.DomainException(
                    'Unable to perform IsChanged check. No old record available'
                );
            return record.get(field) != oldRecord.get(field);
        }
    }

    /**
     * Check if fields are not changed compared to oldMap
     */
    public class NotChanged implements ICheck {
        Map<Id, SObject> oldMap;

        public NotChanged(Map<Id, SObject> oldMap) {
            this.oldMap = oldMap;
        }

        public Boolean check(SObject record, String field) {
            SObject oldRecord = this.oldMap.get(record.Id);
            if (oldRecord == null)
                throw new ApplicationDomain.DomainException(
                    'Unable to perform NotChanged check. No old record available'
                );
            return record.get(field) == oldRecord.get(field);
        }
    }

    /**
     * Check if fields are set
     */
    public class IsSet implements ICheck {
        public Boolean check(SObject record, String field) {
            return record.isSet(field);
        }
    }

    /**
     * Check if fields are not set
     */
    public class NotSet implements ICheck {
        public Boolean check(SObject record, String field) {
            return !record.isSet(field);
        }
    }
}
