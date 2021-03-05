/**
 * Match a list of records against a pool of other records based on identifier and
 * matching rule
 */
public abstract class Matcher {
    protected Map<Id, SObject> recordsById;
    protected Map<Object, List<SObject>> recordsByIdentifier;
    protected Schema.SObjectField identifier;

    public Matcher(List<SObject> records, Schema.SObjectField identifier) {
        this.recordsById = new Map<Id, SObject>(records);
        this.identifier = identifier;
        this.recordsByIdentifier = this.getRecordsByIdentifier();
    }

    private virtual Map<Object, List<SObject>> getRecordsByIdentifier() {
        Map<Object, List<SObject>> recsByIdentifier = new Map<Object, List<SObject>>();
        for (SObject record : this.recordsById.values()) {
            Object value = record.get(this.identifier);
            if (recsByIdentifier.containsKey(value)) {
                recsByIdentifier.get(value).add(record);
            } else {
                recsByIdentifier.put(
                    value,
                    new List<SObject>{ record }
                );
            }
        }
        return recsByIdentifier;
    }

    public virtual List<SObject> getPool(Database.QueryLocator queryLocator) {
        return Database.query(queryLocator.getQuery());
    }

    public abstract List<SObject> getPool();

    public virtual List<MatchResult> match(Schema.SObjectField poolIdentifier) {
        Map<Id, Matcher.MatchResult> matchResultsById = new Map<Id, Matcher.MatchResult>();

        for (SObject poolRecord : this.getPool()) {
            for (
                SObject original : this.recordsByIdentifier.get(
                    poolRecord.get(poolIdentifier)
                )
            ) {
                Id originalId = (Id) original.get('Id');
                Matcher.MatchResult res;

                if (matchResultsById.containsKey(originalId)) {
                    res = matchResultsById.get(originalId);
                } else {
                    res = new Matcher.MatchResult();
                    res.original = original;
                    res.identifier = this.identifier;
                    res.identifierValue = original.get(this.identifier);
                    res.poolIdentifier = poolIdentifier;
                    matchResultsById.put(original.Id, res);
                }

                res.matchedRecords.add(poolRecord);

            }
        }

        return matchResultsById.values();
    }

    public abstract List<Matcher.MatchResult> match();

    public virtual class MatchResult {
        public SObject original;
        public List<SObject> matchedRecords;
        public Schema.SObjectField identifier;
        public Object identifierValue;
        public Schema.SObjectField poolIdentifier;

        public MatchResult() {
            this.matchedRecords = new List<SObject>();
        }

    }
}
