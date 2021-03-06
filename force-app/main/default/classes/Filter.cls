/**
 * Inline filtering on field values of SObject records. Possible to chain multiple conditions
 * and comparisons, but best suitable for simple filters. 
 * 
 * @author nkskaare
 */
public class Filter {
  FilterManager manager;

  public Filter(List<SObject> records) {
    this.manager = new FilterManager(records);
  }

  public ComparisonBuilder byField(String field) {
    return new ComparisonBuilder(field, this.manager);
  }

  private class FilterManager {
    List<Filter.Comparison> compares;
    List<Filter.IConditional> conditionals;
    List<SObject> records;

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

        if (this.conditionals.size() > 0) {
          for (Integer i = 0; i < this.conditionals.size(); i++) {
            IConditional condition = this.conditionals.get(i);
            Comparison compare = this.compares.get(i + 1);

            state = condition.resolve(state, compare.compare(record));
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
      return this.newConditional(
        new Equals(field, value)
      );
    }

    public ConditionalBuilder notEquals(Object value) {
      return this.newConditional(
        new NotEquals(field, value)
      );
    }

    public ConditionalBuilder lessThan(Object value) {
      return this.newConditional(
        new LessThan(field, value)
      );
    }

    public ConditionalBuilder greaterThan(Object value) {
      return this.newConditional(
        new GreaterThan(field, value)
      );
    }

    public ConditionalBuilder lessThanOrEqual(Object value) {
      return this.newConditional(
        new LessThanOrEq(field, value)
      );
    }

    public ConditionalBuilder greaterThanOrEqual(Object value) {
      return this.newConditional(
        new GreaterThanOrEq(field, value)
      );
    }

    private ConditionalBuilder newConditional(Comparison compare) {
      this.manager.addComparison(
        compare
      );
      return new ConditionalBuilder(this.manager);
    }


  }

  public abstract class Comparison {

    protected String field;
    protected Object value;

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
      return this.newComparison(
        new C_And(),
        field
      );
    }

    /**
     * Nand condition. Boolean state is cumulative, using this condition 
     * will affect all previous conditions.
     */
    public ComparisonBuilder nandField(String field) {
      return this.newComparison(
        new C_Nand(),
        field
      );
    }

    public ComparisonBuilder orField(String field) {
      return this.newComparison(
        new C_Or(),
        field
      );
    }

    /**
     * Xor condition. Boolean state is cumulative, using this condition 
     * will affect all previous conditions.
     */
    public ComparisonBuilder xorField(String field) {
      return this.newComparison(
        new C_Xor(),
        field
      );
    }

    /**
     * Nor condition. Boolean state is cumulative, using this negative condition 
     * will invert all previous conditions.
     */
    public ComparisonBuilder norField(String field) {
      return this.newComparison(
        new C_Nor(),
        field
      );
    }

    private ComparisonBuilder newComparison(IConditional condition, String field) {
      this.manager.addConditional(
        condition
      );
      return new ComparisonBuilder(field, this.manager);
    }

    public List<SObject> run() {
      return this.manager.runFilter();
    }
  }


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
      return (a || b) && !(a || b);
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

