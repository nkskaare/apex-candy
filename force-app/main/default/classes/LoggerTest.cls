@IsTest
public class LoggerTest {
  class TestException extends Exception {
  }

  @IsTest
  static void testSetLevel() {
    Logger log = new Logger(System.LoggingLevel.ERROR);
    System.assertEquals(System.LoggingLevel.ERROR, log.logLevel);

    log.setLevel(System.LoggingLevel.INFO);
    System.assertEquals(System.LoggingLevel.INFO, log.logLevel);
  }

  @IsTest
  static void testThrowOnError() {
    Logger log = new Logger();
    log.throwOnError(new TestException());

    System.assert(log.throwException);
  }

  @IsTest
  static void testHandleSave() {
    Opportunity opp = new Opportunity();

    Logger log = new Logger();
    log.throwOnError(new TestException());

    try {
      log.handleSave(Database.insert(new List<Opportunity>{ opp }, false));
      System.assert(false);
    } catch (TestException e) {
      System.assert(String.isNotBlank(e.getMessage()));
    }
  }

  @IsTest
  static void testHandleDelete() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    acc.addError('Cannot delete because I say so');

    Logger log = new Logger();
    log.throwOnError(new TestException());

    try {
      log.handleDelete(Database.delete(new List<Account>{ acc }, false));
      System.assert(false);
    } catch (TestException e) {
      System.assertEquals('Cannot delete because I say so', e.getMessage());
    }
  }

  @IsTest
  static void testHandleUpsert() {
    Account acc = new Account();
    acc.Name = 'Test Account';
    insert acc;

    acc.Name = 'Test Account updated';
    acc.addError('Cannot upsert because I say so');

    Logger log = new Logger();
    log.throwOnError(new TestException());

    try {
      log.handleUpsert(Database.upsert(new List<Account>{ acc }, false));
      System.assert(false);
    } catch (TestException e) {
      System.assert(String.isNotBlank(e.getMessage()));
    }
  }
}
