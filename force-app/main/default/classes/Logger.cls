/**
 * Logger class, creating debug messages from Database results
 * and more (?)
 */
public virtual class Logger {
  public System.LoggingLevel logLevel { get; private set; }
  private Exception e;
  public Boolean throwException;

  public Logger(System.LoggingLevel logLevel) {
    this.setLevel(logLevel);
    this.throwException = false;
  }

  public Logger() {
    this(System.LoggingLevel.WARN);
  }

  /**
   * Set Logger to throw runtime exceptions
   *
   * @param e class instance of Exception or class extending Exception
   */
  public Logger throwOnError(Exception e) {
    this.e = e;
    this.throwException = true;
    return this;
  }

  /**
   * Set logging level
   *
   * @param logLevel System.LogginLevel enum
   */
  public Logger setLevel(System.LoggingLevel logLevel) {
    this.logLevel = logLevel;
    return this;
  }

  /**
   * General database error logging and exception throw
   *
   * @param errors List of Database error objects
   */
  public virtual void handleError(List<Database.Error> errors) {
    for (Database.Error err : errors) {
      System.debug(
        this.logLevel,
        err.getStatusCode() +
        ' : ' +
        err.getMessage()
      );

      if (this.throwException) {
        this.e.setMessage(err.getMessage());
        throw this.e;
      }
    }
  }

  /**
   * General DML save error logging
   *
   * @param saveResults List of save results after DML operation
   */
  public virtual void handleSave(List<Database.SaveResult> saveResults) {
    for (Database.SaveResult saveRes : saveResults) {
      if (!saveRes.success) {
        this.handleError(saveRes.getErrors());
      }
    }
  }

  /**
   * General DML delete error logging
   *
   * @param deleteResults List of delete results after DML operation
   */
  public virtual void handleDelete(List<Database.DeleteResult> deleteResults) {
    for (Database.DeleteResult deleteRes : deleteResults) {
      if (!deleteRes.success) {
        this.handleError(deleteRes.getErrors());
      }
    }
  }

  /**
   * General DML upsert error logging
   *
   * @param upsertResults List of upsert results after DML operation
   */
  public virtual void handleUpsert(List<Database.UpsertResult> upsertResults) {
    for (Database.UpsertResult upsertRes : upsertResults) {
      if (!upsertRes.success) {
        this.handleError(upsertRes.getErrors());
      }
    }
  }

  /**
   * General DML duplicate save error logging
   *
   * @param saveResults List of save results after DML operation
   */
  public virtual void handleDuplicateSave(
    List<Database.SaveResult> saveResults
  ) {
    for (Database.SaveResult saveResult : saveResults) {
      if (!saveResult.isSuccess()) {
        System.debug(
          this.logLevel,
          'Failed to insert record ' +
          saveResult.getId() +
          ' with errors: '
        );

        for (Database.Error error : saveResult.getErrors()) {
          if (error instanceof Database.DuplicateError) {
            Database.DuplicateError duplicateError = (Database.DuplicateError) error;

            DataCloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
            System.debug(
              this.logLevel,
              'Duplicate Error: ' + duplicateResult.getErrorMessage()
            );

            List<DataCloud.MatchRecord> matchRecords = duplicateResult.getMatchResults()[0]
              .getMatchRecords();

            for (DataCloud.MatchRecord matchRecord : matchRecords) {
              System.debug(
                this.logLevel,
                'MatchRecord: ' + matchRecord.getRecord()
              );
            }

            if (this.throwException) {
              this.e.setMessage(duplicateResult.getErrorMessage());
              throw this.e;
            }
          } else {
            this.handleError(new List<Database.Error>{ error });
          }
        }
      }
    }
  }

  public class StackTrace {
    public String traceString { get; private set; }
    public Integer line { get; private set; }
    public String caller {
      get {
        return this.traceString.substringAfterLast('Logger.')
          .substringAfter('\n');
      }
    }

    public String className {
      get {
        String str = caller;
        if (caller.startsWith('Class.')) {
          str = caller.substringAfter('Class.');
        }
        return str.substringBefore(':').substringBeforeLast('.');
      }
    }

    public String methodName {
      get {
        return caller.substringBefore(':').substringAfterLast('.');
      }
    }

    /**
     * @param e Exception to trace
     */
    public StackTrace(Exception e) {
      this.traceString = e.getStackTraceString();
      this.line = e.getLineNumber();
    }
  }
}
