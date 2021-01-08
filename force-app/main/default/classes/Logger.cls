public virtual class Logger {

  public System.LoggingLevel logLevel {get; private set;}
  private Exception e;
  public Boolean throwException;

  public Logger(System.LoggingLevel logLevel) {
    this.setLoggingLevel(logLevel);
    this.throwException = false;
  }

  public Logger() {
    this(System.LoggingLevel.WARN);
  } 


  /**
   * Set Logger to throw runtime exceptions
   */
  public Logger throwOnError(Exception e) {
    this.e = e;
    this.throwException = true;
    return this;
  }

  /**
   * Set logging level
   */
  public Logger setLoggingLevel(System.LoggingLevel logLevel) {
    this.logLevel = logLevel;
    return this;
  }


  /**
   * General DML save error logging, throws an exception on the first error encoutered
   *
   * @param saveResults List of save results after DML operation
   * @param exceptionObj The exception to throw
   */
  public void saveLog(
    List<Database.SaveResult> saveResults
  ) {
    for (Database.SaveResult saveRes : saveResults) {
      if (!saveRes.success) {
        for (Database.Error err : saveRes.getErrors()) {
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
    }
  }

  /**
   * General DML delete error logging, throws an exception on the first error encoutered
   *
   * @param deleteResults List of save results after DML operation
   */
  public void deleteLog(
    List<Database.DeleteResult> deleteResults
  ) {
    for (Database.DeleteResult saveRes : deleteResults) {
      if (!saveRes.success) {
        for (Database.Error err : saveRes.getErrors()) {
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
    }
  }

  /**
   * General DML delete error logging, throws an exception on the first error encoutered
   *
   * @param deleteResults List of save results after DML operation
   */
  public void upsertLog(
    List<Database.UpsertResult> upsertResults
  ) {
    for (Database.UpsertResult upsertRes : upsertResults) {
      if (!upsertRes.success) {
        for (Database.Error err : upsertRes.getErrors()) {
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
    }
  }

  /**
   * General DML duplicate save error logging
   *
   * ? TODO: Add exception throw
   *
   * @param saveResults List of save results after DML operation
   */
  public void duplicateSaveLog(
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
          } else {
            System.debug(
              this.logLevel,
              error.getStatusCode() +
              ': ' +
              error.getMessage()
            );
          }
        }
      }
    }
  }

}
