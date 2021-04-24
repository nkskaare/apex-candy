@IsTest
public class FilterTest {
    @IsTest
    static void testEqualsNotEquals() {
        List<Account> accs = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addFieldValue(
                'Name',
                new List<String>{
                    'Dunder Mifflin',
                    'Dunder Mifflin',
                    'Dunder Mifflin',
                    'Dunder Mifflin',
                    'Michael Scott Paper Company'
                }
            )
            .getRecords();

        Test.startTest();

        List<Account> dunderMifflins = (List<Account>) new Filter(accs)
            .byField('Name')
            .equals('Dunder Mifflin')
            .getRecords();
        List<Account> michaelScotts = (List<Account>) new Filter(accs)
            .byField('Name')
            .notEquals('Dunder Mifflin')
            .getRecords();

        System.assertEquals(5, accs.size());
        System.assertEquals(4, dunderMifflins.size());
        System.assertEquals(1, michaelScotts.size());

        Test.stopTest();
    }

    @IsTest
    static void testOrNor() {
        List<Account> accs = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addFieldValue(
                'Name',
                new List<String>{
                    'Dunder Mifflin',
                    'Dunder Mifflin',
                    'Dunder Mifflin',
                    'Michael Scott Paper Company',
                    'Staples'
                }
            )
            .getRecords();

        Test.startTest();
        List<Account> theOffice = (List<Account>) new Filter(accs)
            .byField('Name')
            .equals('Dunder Mifflin')
            .orField('Name')
            .equals('Michael Scott Paper Company')
            .getRecords();

        List<Account> staples = (List<Account>) new Filter(accs)
            .byField('Name')
            .equals('Dunder Mifflin')
            .norField('Name')
            .equals('Michael Scott Paper Company')
            .getRecords();

        System.assertEquals(4, theOffice.size());
        System.assertEquals(1, staples.size());
        System.assertEquals('Staples', staples[0].Name);
        Test.stopTest();
    }

    @IsTest
    static void testAndNand() {
        List<Account> accs = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addFieldValue(
                'Name',
                new List<String>{
                    'Dunder Mifflin',
                    'Dunder Mifflin',
                    'Dunder Mifflin',
                    'Michael Scott Paper Company',
                    'Michael Scott Paper Company'
                }
            )
            .addFieldValue(
                'Phone',
                new List<String>{
                    '12345678',
                    '12345678',
                    '12345678',
                    '87654321',
                    '87654321'
                }
            )
            .getRecords();

        Test.startTest();
        List<Account> dunderMifflins = (List<Account>) new Filter(accs)
            .byField('Name')
            .equals('Dunder Mifflin')
            .andField('Phone')
            .equals('12345678')
            .getRecords();

        List<Account> michaelScotts = (List<Account>) new Filter(accs)
            .byField('Name')
            .equals('Dunder Mifflin')
            .nandField('Phone')
            .equals('12345678')
            .getRecords();

        System.assertEquals(3, dunderMifflins.size());
        System.assertEquals(2, michaelScotts.size());

        Test.stopTest();
    }
}
