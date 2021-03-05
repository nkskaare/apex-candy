public class Filter {
  ConditionalManager manager;

  private enum Operator {
    equals,
    notEquals,
    lessThan,
    greaterThan,
    lessThanOrEq,
    greaterThanOrEq
  }

  private enum Condition {
    c_and,
    c_nand,
    c_or,
    c_xor,
    c_nor
  }

  public Filter(List<SObject> records) {
    this.manager = new ConditionalManager(records);
  }

  public Compare byField(String field) {
    return new Compare(field, this.manager);
  }

  private class ConditionalManager {
    List<Compare> compares;
    List<Filter.Condition> conditionals;
    List<SObject> records;

    public ConditionalManager(List<SObject> records) {
      this.records = records;
    }

    public void addCompare(Compare comp) {
      this.compares.add(comp);
    }

    public void addCondition(Filter.Condition cond) {
      this.conditionals.add(cond);
    }

    public List<SObject> runFilter() {
      List<SObject> resultList = new List<SObject>();

      for (SObject record : this.records) {
        Compare firstCompare = this.compares.get(0);
        Boolean state = new Comparison(record).compare(firstCompare);

        if (this.conditionals.size() > 0) {
          for (Integer i = 0; i < this.conditionals.size(); i++) {
            Filter.Condition cond = this.conditionals.get(i);
            Compare comp = this.compares.get(i + 1);

            state = new ConditionalCalculator()
              .calculate(state, cond, new Comparison(record).compare(comp));
          }
        }

        if (state) {
          resultList.add(record);
        }
      }

      return resultList;
    }
  }

  public class Comparison {
    SObject sObj;

    public Comparison(SObject sObj) {
      this.sObj = sObj;
    }

    public Boolean equals(String field, Object value) {
      return this.sObj.get(field) == value;
    }

    public Boolean notEquals(String field, Object value) {
      return this.sObj.get(field) != value;
    }

    public Boolean lessThan(String field, Integer value) {
      return (Integer) this.sObj.get(field) < value;
    }

    public Boolean lessThan(String field, Datetime value) {
      return (Datetime) this.sObj.get(field) < value;
    }

    public Boolean greaterThan(String field, Integer value) {
      return (Integer) this.sObj.get(field) > value;
    }

    public Boolean lessThanOrEqual(String field, Integer value) {
      return (Integer) this.sObj.get(field) <= value;
    }

    public Boolean greaterThanOrEqual(String field, Integer value) {
      return (Integer) this.sObj.get(field) >= value;
    }

    public Boolean compare(Compare compare) {
      String field = compare.field;
      Object value = compare.value;
      switch on compare.operator {
        when equals {
          return this.equals(field, value);
        }
        when notEquals {
          return this.notEquals(field, value);
        }
        when lessThan {
          return this.lessThan(field, value);
        }
        when greaterThan {
          return this.greaterThan(field, value);
        }
        when lessThanOrEq {
          return this.lessThanOrEqual(field, value);
        }
        when greaterThanOrEq {
          return this.greaterThanOrEqual(field, value);
        }
      }
      return null;
    }
  }

  private class Compare {
    public String field;
    public Filter.Operator operator;
    public Object value;
    ConditionalManager manager;

    public Compare(String field, ConditionalManager manager) {
      this.field = field;
      this.manager = manager;
    }

    public Conditional equals(Object value) {
      this.operator = Filter.Operator.equals;
      this.value = value;
      return this.newConditional();
    }

    public Conditional notEquals(Object value) {
      this.operator = Filter.Operator.notEquals;
      this.value = value;
      return this.newConditional();
    }

    public Conditional lessThan(Object value) {
      this.operator = Filter.Operator.lessThan;
      this.value = value;
      return this.newConditional();
    }

    public Conditional greaterThan(Object value) {
      this.operator = Filter.Operator.greaterThan;
      this.value = value;
      return this.newConditional();
    }

    public Conditional lessThanOrEqual(Object value) {
      this.operator = Filter.Operator.lessThanOrEq;
      this.value = value;
      return this.newConditional();
    }

    public Conditional greaterThanOrEqual(Object value) {
      this.operator = Filter.Operator.greaterThanOrEq;
      this.value = value;
      return this.newConditional();
    }

    private Conditional newConditional() {
      this.manager.addCompare(this);
      return new Conditional(this.manager);
    }
  }

  private class Conditional {
    ConditionalManager manager;
    Filter.Condition cond;

    public Conditional(ConditionalManager manager) {
      this.manager = manager;
    }

    public Compare andField(String field) {
      this.cond = Filter.Condition.c_and;
      return this.newCompare(field);
    }

    public Compare nandField(String field) {
      this.cond = Filter.Condition.c_nand;
      return this.newCompare(field);
    }

    public Compare orField(String field) {
      this.cond = Filter.Condition.c_or;
      return this.newCompare(field);
    }

    public Compare xorField(String field) {
      this.cond = Filter.Condition.c_xor;
      return this.newCompare(field);
    }

    public Compare norField(String field) {
      this.cond = Filter.Condition.c_nor;
      return this.newCompare(field);
    }

    private Compare newCompare(String field) {
      this.manager.addCondition(this.cond);
      return new Compare(field, this.manager);
    }

    public void done() {
      this.manager.runFilter();
    }
  }

  /**
   * Cumulative conditional
   */
  private class ConditionalCalculator {
    public ConditionalCalculator() {
    }

    public Boolean calculate(
      Boolean bool1,
      Filter.Condition cond,
      Boolean bool2
    ) {
      switch on cond {
        when c_and {
          return this.c_and(bool1, bool2);
        }
        when c_nand {
          return this.c_nand(bool1, bool2);
        }
        when c_or {
          return this.c_or(bool1, bool2);
        }
        when c_xor {
          return this.c_xor(bool1, bool2);
        }
        when c_nor {
          return this.c_nor(bool1, bool2);
        }
      }
    }

    public Boolean c_and(Boolean bool1, Boolean bool2) {
      return bool1 && bool2;
    }

    public Boolean c_nand(Boolean bool1, Boolean bool2) {
      return !(bool1 && bool2);
    }

    public Boolean c_or(Boolean bool1, Boolean bool2) {
      return bool1 || bool2;
    }

    public Boolean c_xor(Boolean bool1, Boolean bool2) {
      return (bool1 || bool2) && !(bool1 || bool2);
    }

    public Boolean c_nor(Boolean bool1, Boolean bool2) {
      return !(bool1 || bool2);
    }
  }
}

