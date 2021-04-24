/**
 * Inline filtering on field values of SObject records. Possible to chain multiple conditions
 * and comparisons, but best suitable for simple filters.
 *
 * @author nkskaare
 */
public virtual class Filter {
    FilterManager manager;

    public Filter(List<SObject> records) {
        this.manager = new FilterManager(records);
    }

    public Filter(List<SObject> records, Map<Id, SObject> oldMap) {
        this.manager = new FilterManager(records, oldMap);
    }

    public ComparisonBuilder byField(String field) {
        return new ComparisonBuilder(field, this.manager);
    }

    /**
     * Register for all compares and conditions
     */
    private class FilterManager {
        List<Filter.Comparison> compares;
        List<Filter.IConditional> conditionals;
        List<SObject> records;
        Map<Id, SObject> oldMap;

        public FilterManager(List<SObject> records, Map<Id, SObject> oldMap) {
            this(records);
            this.oldMap = oldMap;
        }

        public FilterManager(List<SObject> records) {
            this.records = records.clone();
            this.compares = new List<Filter.Comparison>();
            this.conditionals = new List<Filter.IConditional>();
        }

        public void addComparison(Comparison comp) {
            this.compares.add(comp);
        }

        public void addConditional(IConditional cond) {
            this.conditionals.add(cond);
        }

        /**
         * Iterates through records and the registered Comparisons and Conditionals
         */
        public List<SObject> runFilter() {
            List<SObject> resultList = new List<SObject>();

            for (SObject record : this.records) {
                Comparison firstCompare = this.compares.get(0);
                Boolean state = firstCompare.compare(record);

                // Accumulate boolean state
                if (this.conditionals.size() > 0) {
                    for (Integer i = 0; i < this.conditionals.size(); i++) {
                        IConditional condition = this.conditionals.get(i);
                        Comparison compare = this.compares.get(i + 1);

                        state = condition.resolve(
                            state,
                            compare.compare(record)
                        );
                    }
                }

                if (state) {
                    resultList.add(record);
                }
            }

            return resultList;
        }
    }

    /**
     * Container for comparison methods
     */
    public class ComparisonBuilder {
        public String field;
        FilterManager manager;

        public ComparisonBuilder(String field, FilterManager manager) {
            this.field = field;
            this.manager = manager;
        }

        public ConditionalBuilder equals(Object value) {
            return this.newConditional(new Equals(field, value));
        }

        public ConditionalBuilder notEquals(Object value) {
            return this.newConditional(new NotEquals(field, value));
        }

        public ConditionalBuilder lessThan(Object value) {
            return this.newConditional(new LessThan(field, value));
        }

        public ConditionalBuilder greaterThan(Object value) {
            return this.newConditional(new GreaterThan(field, value));
        }

        public ConditionalBuilder lessThanOrEqual(Object value) {
            return this.newConditional(new LessThanOrEq(field, value));
        }

        public ConditionalBuilder greaterThanOrEqual(Object value) {
            return this.newConditional(new GreaterThanOrEq(field, value));
        }

        public ConditionalBuilder contains(List<Object> possibleValues) {
            return this.newConditional(new Contains(field, possibleValues));
        }

        public ConditionalBuilder isSet() {
            return this.newConditional(new IsSet(field));
        }

        public ConditionalBuilder notSet() {
            return this.newConditional(new NotSet(field));
        }

        public ConditionalBuilder isNew() {
            return this.newConditional(new IsNew(field, this.manager.oldMap));
        }

        public ConditionalBuilder isUpdated() {
            return this.newConditional(
                new IsUpdated(field, this.manager.oldMap)
            );
        }

        public ConditionalBuilder isDeleted() {
            return this.newConditional(
                new IsDeleted(field, this.manager.oldMap)
            );
        }

        public ConditionalBuilder isChanged() {
            return this.newConditional(
                new IsChanged(field, this.manager.oldMap)
            );
        }

        public ConditionalBuilder notChanged() {
            return this.newConditional(
                new NotChanged(field, this.manager.oldMap)
            );
        }
        /**
         * Register new condition to filter manager
         */
        private ConditionalBuilder newConditional(Comparison compare) {
            this.manager.addComparison(compare);
            return new ConditionalBuilder(this.manager);
        }
    }

    /**
     * Represents a comparison. A field with fieldvalue compared to a given value.
     */
    public abstract class Comparison {
        protected String field;
        protected Object value;

        /**
         * @param field field to find value
         * @param value value to compare fieldvalue to
         */
        public Comparison(String field, Object value) {
            this.field = field;
            this.value = value;
        }

        abstract Boolean compare(SObject record);
    }

    private class Equals extends Comparison {
        public Equals(String field, Object value) {
            super(field, value);
        }

        public override Boolean compare(SObject record) {
            return record.get(field) == value;
        }
    }

    private class NotEquals extends Comparison {
        public NotEquals(String field, Object value) {
            super(field, value);
        }

        public override Boolean compare(SObject record) {
            return record.get(field) != value;
        }
    }

    private class LessThan extends Comparison {
        public LessThan(String field, Object value) {
            super(field, value);
        }

        public override Boolean compare(SObject record) {
            if (value instanceof Integer) {
                return (Integer) record.get(field) < (Integer) value;
            } else if (value instanceof Double) {
                return (Double) record.get(field) < (Double) value;
            } else if (value instanceof DateTime) {
                return (DateTime) record.get(field) < (Datetime) value;
            }

            return false;
        }
    }

    private class GreaterThan extends Comparison {
        public GreaterThan(String field, Object value) {
            super(field, value);
        }

        public override Boolean compare(SObject record) {
            if (value instanceof Integer) {
                return (Integer) record.get(field) > (Integer) value;
            } else if (value instanceof Double) {
                return (Double) record.get(field) > (Double) value;
            } else if (value instanceof DateTime) {
                return (DateTime) record.get(field) > (Datetime) value;
            }

            return false;
        }
    }

    private class LessThanOrEq extends Comparison {
        public LessThanOrEq(String field, Object value) {
            super(field, value);
        }

        public override Boolean compare(SObject record) {
            if (value instanceof Integer) {
                return (Integer) record.get(field) <= (Integer) value;
            } else if (value instanceof Double) {
                return (Double) record.get(field) <= (Double) value;
            } else if (value instanceof DateTime) {
                return (DateTime) record.get(field) <= (Datetime) value;
            }

            return false;
        }
    }

    private class GreaterThanOrEq extends Comparison {
        public GreaterThanOrEq(String field, Object value) {
            super(field, value);
        }
        public override Boolean compare(SObject record) {
            if (value instanceof Integer) {
                return (Integer) record.get(field) >= (Integer) value;
            } else if (value instanceof Double) {
                return (Double) record.get(field) >= (Double) value;
            } else if (value instanceof DateTime) {
                return (DateTime) record.get(field) >= (Datetime) value;
            }

            return false;
        }
    }

    private class Contains extends Comparison {
        public Contains(String field, Object value) {
            super(field, value);
        }
        public override Boolean compare(SObject record) {
            return ((List<Object>) value).contains(record.get(field));
        }
    }

    private class IsSet extends Comparison {
        public IsSet(String field) {
            super(field, null);
        }
        public override Boolean compare(SObject record) {
            return record.isSet(field);
        }
    }

    private class NotSet extends Comparison {
        public NotSet(String field) {
            super(field, null);
        }
        public override Boolean compare(SObject record) {
            return !record.isSet(field);
        }
    }

    public class IsNew extends Comparison {
        Map<Id, SObject> oldMap;

        public IsNew(String field, Map<Id, SObject> oldMap) {
            super(field, null);
            this.oldMap = oldMap;
        }

        public override Boolean compare(SObject record) {
            SObject oldRecord = this.oldMap.get(record.Id);
            return record.get(field) != null && oldRecord.get(field) == null;
        }
    }

    public class IsUpdated extends Comparison {
        Map<Id, SObject> oldMap;

        public IsUpdated(String field, Map<Id, SObject> oldMap) {
            super(field, null);
            this.oldMap = oldMap;
        }

        public override Boolean compare(SObject record) {
            SObject oldRecord = this.oldMap.get(record.Id);
            return record.get(field) != oldRecord.get(field) &&
                record.get(field) != null &&
                oldRecord.get(field) != null;
        }
    }

    public class IsDeleted extends Comparison {
        Map<Id, SObject> oldMap;

        public IsDeleted(String field, Map<Id, SObject> oldMap) {
            super(field, null);
            this.oldMap = oldMap;
        }

        public override Boolean compare(SObject record) {
            SObject oldRecord = this.oldMap.get(record.Id);
            return record.get(field) == null && oldRecord.get(field) != null;
        }
    }

    public class IsChanged extends Comparison {
        Map<Id, SObject> oldMap;

        public IsChanged(String field, Map<Id, SObject> oldMap) {
            super(field, null);
            this.oldMap = oldMap;
        }

        public override Boolean compare(SObject record) {
            SObject oldRecord = this.oldMap.get(record.Id);
            return record.get(field) != oldRecord.get(field);
        }
    }

    public class NotChanged extends Comparison {
        Map<Id, SObject> oldMap;

        public NotChanged(String field, Map<Id, SObject> oldMap) {
            super(field, null);
            this.oldMap = oldMap;
        }

        public override Boolean compare(SObject record) {
            SObject oldRecord = this.oldMap.get(record.Id);
            return record.get(field) == oldRecord.get(field);
        }
    }

    /**
     * Container for conditional methods
     */
    public class ConditionalBuilder {
        FilterManager manager;

        public ConditionalBuilder(FilterManager manager) {
            this.manager = manager;
        }

        /**
         * And condition.
         */
        public ComparisonBuilder andField(String field) {
            return this.newComparison(new C_And(), field);
        }

        /**
         * Nand condition. Boolean state is cumulative, using this condition
         * will affect all previous conditions.
         */
        public ComparisonBuilder nandField(String field) {
            return this.newComparison(new C_Nand(), field);
        }

        public ComparisonBuilder orField(String field) {
            return this.newComparison(new C_Or(), field);
        }

        /**
         * Xor condition. Boolean state is cumulative, using this condition
         * will affect all previous conditions.
         */
        public ComparisonBuilder xorField(String field) {
            return this.newComparison(new C_Xor(), field);
        }

        /**
         * Nor condition. Boolean state is cumulative, using this negative condition
         * will invert all previous conditions.
         */
        public ComparisonBuilder norField(String field) {
            return this.newComparison(new C_Nor(), field);
        }

        /**
         * Register new Comparison to filter manager
         */
        private ComparisonBuilder newComparison(
            IConditional condition,
            String field
        ) {
            this.manager.addConditional(condition);
            return new ComparisonBuilder(field, this.manager);
        }

        public List<SObject> getRecords() {
            return this.manager.runFilter();
        }
    }

    /**
     * Conditional interface
     */
    public interface IConditional {
        Boolean resolve(Boolean a, Boolean b);
    }
    // C_* prefixes due to reserved names
    private class C_And implements IConditional {
        public Boolean resolve(Boolean a, Boolean b) {
            return a && b;
        }
    }

    private class C_Nand implements IConditional {
        public Boolean resolve(Boolean a, Boolean b) {
            return !(a && b);
        }
    }
    private class C_Or implements IConditional {
        public Boolean resolve(Boolean a, Boolean b) {
            return a || b;
        }
    }

    /**
     * XOR logic implementation
     */
    private class C_Xor implements IConditional {
        public Boolean resolve(Boolean a, Boolean b) {
            return (a || b) && !(a && b);
        }
    }
    /**
     * NOR logic implementation
     */
    private class C_Nor implements IConditional {
        public Boolean resolve(Boolean a, Boolean b) {
            return !(a || b);
        }
    }
}
