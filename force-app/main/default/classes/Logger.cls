public virtual class Logger {

  public System.LoggingLevel logLevel {get; private set;}
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
   * @param err Database error object
   */
  public virtual void handleError(Database.Error err) {
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

  /**
   * General DML save error logging
   *
   * @param saveResults List of save results after DML operation
   */
  public virtual void handleSave(
    List<Database.SaveResult> saveResults
  ) {
    for (Database.SaveResult saveRes : saveResults) {
      if (!saveRes.success) {
        for (Database.Error err : saveRes.getErrors()) {
          this.handleError(err);
        }
      }
    }
  }

  /**
   * General DML delete error logging
   *
   * @param deleteResults List of save results after DML operation
   */
  public virtual void handleDelete(
    List<Database.DeleteResult> deleteResults
  ) {
    for (Database.DeleteResult saveRes : deleteResults) {
      if (!saveRes.success) {
        for (Database.Error err : saveRes.getErrors()) {
          this.handleError(err);
        }
      }
    }
  }

  /**
   * General DML upsert error logging
   *
   * @param upsertResults List of save results after DML operation
   */
  public virtual void handleUpsert(
    List<Database.UpsertResult> upsertResults
  ) {
    for (Database.UpsertResult upsertRes : upsertResults) {
      if (!upsertRes.success) {
        for (Database.Error err : upsertRes.getErrors()) {
          this.handleError(err);
        }
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
            this.handleError(error);
          }
        }
      }
    }
  }

}
