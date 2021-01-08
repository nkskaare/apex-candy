@IsTest
public class LoggerTest {

    class TestException extends Exception {}

    @IsTest
    static void testSetLevel(){
        Logger log = new Logger(System.LoggingLevel.ERROR);
        System.assertEquals(System.LoggingLevel.ERROR, log.logLevel);

        log.setLevel(System.LoggingLevel.INFO);
        System.assertEquals(System.LoggingLevel.INFO, log.logLevel);
    }

    @IsTest
    static void testThrowOnError(){
        Logger log = new Logger();
        log.throwOnError(new TestException());

        System.assert(log.throwException);
    }
}
