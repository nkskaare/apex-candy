@IsTest
public class FieldCheckerTest {
    @IsTest
    static void testFieldChangeAllIsNew() {
        List<Account> newAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addMockId()
            .addFieldValue('AccountNumber', '12345')
            .addFieldValue('Phone', '91122333')
            .addFieldValue('npsp__Number_of_Household_Members__c', 5)
            .getRecords();

        List<Account> oldAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addFieldValue(
                'Id',
                new List<Id>(new Map<Id, Account>(newAccounts).keySet())
            )
            .getRecords();

        List<String> fields = new List<String>{
            'AccountNumber',
            'Phone',
            'npsp__Number_of_Household_Members__c'
        };

        Test.startTest();
        FieldChecker fc = new FieldChecker(newAccounts);
        fc.setFields(fields);
        fc.setAll();
        fc.setChecker(
            new FieldChecker.IsNew(new Map<Id, Account>(oldAccounts))
        );
        List<FieldChecker.Result> res = FieldChecker.check(fc).getResults();

        for (Integer i = 0; i < newAccounts.size(); i++) {
            System.assertEquals(newAccounts[i], res[i].record);
            System.assertEquals(fields, res[i].checkedFields);
        }

        Test.stopTest();
    }

    @IsTest
    static void testFieldChangeAnyIsNew() {
        List<Account> newAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addMockId()
            .addFieldValue('AccountNumber', '12345')
            .addFieldValue('Phone', '91122333')
            .addFieldValue('npsp__Number_of_Household_Members__c', 5)
            .getRecords();

        List<Account> oldAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addFieldValue('Phone', '91122333')
            .addFieldValue(
                'Id',
                new List<Id>(new Map<Id, Account>(newAccounts).keySet())
            )
            .getRecords();

        List<String> fields = new List<String>{
            'AccountNumber',
            'Phone',
            'npsp__Number_of_Household_Members__c'
        };

        Test.startTest();
        FieldChecker fc = new FieldChecker(newAccounts);
        fc.setFields(fields);
        fc.setChecker(
            new FieldChecker.IsNew(new Map<Id, Account>(oldAccounts))
        );
        List<FieldChecker.Result> res = FieldChecker.check(fc).getResults();

        List<String> newFields = new List<String>{
            'AccountNumber',
            'npsp__Number_of_Household_Members__c'
        };

        for (Integer i = 0; i < newAccounts.size(); i++) {
            System.assertEquals(newAccounts[i], res[i].record);
            System.assertEquals(newFields, res[i].checkedFields);
        }

        FieldChecker fcAll = new FieldChecker(newAccounts);
        fcAll.setFields(fields);
        fcAll.setAll();
        fcAll.setChecker(
            new FieldChecker.IsNew(new Map<Id, Account>(oldAccounts))
        );
        System.assert(FieldChecker.check(fcAll).getResults().isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void testFieldChangeAllIsUpdated() {
        List<Account> newAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addMockId()
            .addFieldValue('AccountNumber', '12345')
            .addFieldValue('Phone', '91122333')
            .addFieldValue('npsp__Number_of_Household_Members__c', 5)
            .getRecords();

        List<Account> oldAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addFieldValue('AccountNumber', '54321')
            .addFieldValue('Phone', '98877666')
            .addFieldValue('npsp__Number_of_Household_Members__c', 3)
            .addFieldValue(
                'Id',
                new List<Id>(new Map<Id, Account>(newAccounts).keySet())
            )
            .getRecords();

        List<String> fields = new List<String>{
            'AccountNumber',
            'Phone',
            'npsp__Number_of_Household_Members__c'
        };

        Test.startTest();
        FieldChecker fc = new FieldChecker(newAccounts);
        fc.setFields(fields);
        fc.setAll();
        fc.setChecker(
            new FieldChecker.IsUpdated(new Map<Id, Account>(oldAccounts))
        );
        List<FieldChecker.Result> res = FieldChecker.check(fc).getResults();

        for (Integer i = 0; i < newAccounts.size(); i++) {
            System.assertEquals(newAccounts[i], res[i].record);
            System.assertEquals(fields, res[i].checkedFields);
        }

        Test.stopTest();
    }

    @IsTest
    static void testFieldChangeAnyIsUpdated() {
        List<Account> newAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addMockId()
            .addFieldValue('AccountNumber', '12345')
            .addFieldValue('Phone', '91122333')
            .addFieldValue('npsp__Number_of_Household_Members__c', 5)
            .getRecords();

        List<Account> oldAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addFieldValue('AccountNumber', '54321')
            .addFieldValue('Phone', '98877666')
            .addFieldValue('npsp__Number_of_Household_Members__c', 5)
            .addFieldValue(
                'Id',
                new List<Id>(new Map<Id, Account>(newAccounts).keySet())
            )
            .getRecords();

        List<String> fields = new List<String>{
            'AccountNumber',
            'Phone',
            'npsp__Number_of_Household_Members__c'
        };

        Test.startTest();
        FieldChecker fc = new FieldChecker(newAccounts);
        fc.setFields(fields);
        fc.setChecker(
            new FieldChecker.IsUpdated(new Map<Id, Account>(oldAccounts))
        );
        List<FieldChecker.Result> res = FieldChecker.check(fc).getResults();

        List<String> updatedFields = new List<String>{
            'AccountNumber',
            'Phone'
        };

        for (Integer i = 0; i < newAccounts.size(); i++) {
            System.assertEquals(newAccounts[i], res[i].record);
            System.assertEquals(updatedFields, res[i].checkedFields);
        }

        FieldChecker fcAll = new FieldChecker(newAccounts);
        fcAll.setFields(fields);
        fcAll.setAll();
        fcAll.setChecker(
            new FieldChecker.IsUpdated(new Map<Id, Account>(oldAccounts))
        );
        System.assert(FieldChecker.check(fcAll).getResults().isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void testFieldChangeAllIsDeleted() {
        List<Account> newAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addMockId()
            .getRecords();

        List<Account> oldAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addFieldValue('AccountNumber', '12345')
            .addFieldValue('Phone', '91122333')
            .addFieldValue('npsp__Number_of_Household_Members__c', 5)
            .addFieldValue(
                'Id',
                new List<Id>(new Map<Id, Account>(newAccounts).keySet())
            )
            .getRecords();

        List<String> fields = new List<String>{
            'AccountNumber',
            'Phone',
            'npsp__Number_of_Household_Members__c'
        };

        Test.startTest();
        FieldChecker fc = new FieldChecker(newAccounts);
        fc.setFields(fields);
        fc.setAll();
        fc.setChecker(
            new FieldChecker.IsDeleted(new Map<Id, Account>(oldAccounts))
        );
        List<FieldChecker.Result> res = FieldChecker.check(fc).getResults();

        for (Integer i = 0; i < newAccounts.size(); i++) {
            System.assertEquals(newAccounts[i], res[i].record);
            System.assertEquals(fields, res[i].checkedFields);
        }

        Test.stopTest();
    }

    @IsTest
    static void testFieldChangeAnyIsDeleted() {
        List<Account> newAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addMockId()
            .addFieldValue('Phone', '91122333')
            .getRecords();

        List<Account> oldAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addFieldValue('AccountNumber', '12345')
            .addFieldValue('Phone', '91122333')
            .addFieldValue('npsp__Number_of_Household_Members__c', 5)
            .addFieldValue(
                'Id',
                new List<Id>(new Map<Id, Account>(newAccounts).keySet())
            )
            .getRecords();

        List<String> fields = new List<String>{
            'AccountNumber',
            'Phone',
            'npsp__Number_of_Household_Members__c'
        };

        Test.startTest();
        FieldChecker fc = new FieldChecker(newAccounts);
        fc.setFields(fields);
        fc.setChecker(
            new FieldChecker.IsDeleted(new Map<Id, Account>(oldAccounts))
        );
        List<FieldChecker.Result> res = FieldChecker.check(fc).getResults();

        List<String> deletedFields = new List<String>{
            'AccountNumber',
            'npsp__Number_of_Household_Members__c'
        };

        for (Integer i = 0; i < newAccounts.size(); i++) {
            System.assertEquals(newAccounts[i], res[i].record);
            System.assertEquals(deletedFields, res[i].checkedFields);
        }

        FieldChecker fcAll = new FieldChecker(newAccounts);
        fcAll.setFields(fields);
        fcAll.setAll();
        fcAll.setChecker(
            new FieldChecker.IsDeleted(new Map<Id, Account>(oldAccounts))
        );
        System.assert(FieldChecker.check(fcAll).getResults().isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void testFieldCheckAnyIsSet() {
        List<Account> newAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addMockId()
            .addFieldValue('AccountNumber', '12345')
            .addFieldValue('Phone', '91122333')
            .getRecords();

        List<String> fields = new List<String>{
            'AccountNumber',
            'Phone',
            'npsp__Number_of_Household_Members__c'
        };

        Test.startTest();
        FieldChecker fc = new FieldChecker(newAccounts);
        fc.setFields(fields);
        fc.setChecker(new FieldChecker.IsSet());
        List<FieldChecker.Result> res = FieldChecker.check(fc).getResults();

        List<String> setFields = new List<String>{ 'AccountNumber', 'Phone' };

        for (Integer i = 0; i < newAccounts.size(); i++) {
            System.assertEquals(newAccounts[i], res[i].record);
            System.assertEquals(setFields, res[i].checkedFields);
        }

        FieldChecker fcAll = new FieldChecker(newAccounts);
        fcAll.setFields(fields);
        fcAll.setAll();
        fcAll.setChecker(new FieldChecker.IsSet());
        System.assert(FieldChecker.check(fcAll).getResults().isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void testFieldCheckAllIsSet() {
        List<Account> newAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addMockId()
            .addFieldValue('AccountNumber', '12345')
            .addFieldValue('Phone', '91122333')
            .addFieldValue('npsp__Number_of_Household_Members__c', 5)
            .getRecords();

        List<String> fields = new List<String>{
            'AccountNumber',
            'Phone',
            'npsp__Number_of_Household_Members__c'
        };

        Test.startTest();
        FieldChecker fc = new FieldChecker(newAccounts);
        fc.setFields(fields);
        fc.setAll();
        fc.setChecker(new FieldChecker.IsSet());
        List<FieldChecker.Result> res = FieldChecker.check(fc).getResults();

        for (Integer i = 0; i < newAccounts.size(); i++) {
            System.assertEquals(newAccounts[i], res[i].record);
            System.assertEquals(fields, res[i].checkedFields);
        }
        Test.stopTest();
    }

    @IsTest
    static void testFieldCheckAnyNotSet() {
        List<Account> newAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addMockId()
            .addFieldValue('AccountNumber', '12345')
            .addFieldValue('Phone', '91122333')
            .getRecords();

        List<String> fields = new List<String>{
            'AccountNumber',
            'Phone',
            'npsp__Number_of_Household_Members__c'
        };

        Test.startTest();
        FieldChecker fc = new FieldChecker(newAccounts);
        fc.setFields(fields);
        fc.setChecker(new FieldChecker.NotSet());
        List<FieldChecker.Result> res = FieldChecker.check(fc).getResults();

        List<String> notSetFields = new List<String>{
            'npsp__Number_of_Household_Members__c'
        };

        for (Integer i = 0; i < newAccounts.size(); i++) {
            System.assertEquals(newAccounts[i], res[i].record);
            System.assertEquals(notSetFields, res[i].checkedFields);
        }
        Test.stopTest();
    }

    @IsTest
    static void testFieldCheckAllNotSet() {
        List<Account> newAccounts = (List<Account>) TestFactory.mock()
            .createAccounts(5)
            .addMockId()
            .getRecords();

        List<String> fields = new List<String>{
            'AccountNumber',
            'Phone',
            'npsp__Number_of_Household_Members__c'
        };

        Test.startTest();
        FieldChecker fc = new FieldChecker(newAccounts);
        fc.setFields(fields);
        fc.setAll();
        fc.setChecker(new FieldChecker.NotSet());
        List<FieldChecker.Result> res = FieldChecker.check(fc).getResults();

        for (Integer i = 0; i < newAccounts.size(); i++) {
            System.assertEquals(newAccounts[i], res[i].record);
            System.assertEquals(fields, res[i].checkedFields);
        }
        Test.stopTest();
    }
}
