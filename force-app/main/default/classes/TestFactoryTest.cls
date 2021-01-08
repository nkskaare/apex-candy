/**
 * Not real test class, just showing examples of TestFactory in use, 
 * should not be deployed to any org as it has no real use case. 
 */
@IsTest
public class TestFactoryTest {
    @IsTest
    static void createOpportunityWithAccount(){

        List<Opportunity> opps = TestFactory.mock().createOpportunities(5).addAccount().getData();

        System.assertEquals(5, opps.size());
        for (Opportunity opp : opps) {
            System.assertNotEquals(null, opp.Account);
        }
        
    }
}
