public class Application {
  public static final fflib_Application.UnitOfWorkFactory UnitOfWork = new fflib_Application.UnitOfWorkFactory(
    new List<SObjectType>{
      Opportunity.SObjectType,
      Account.SObjectType,
      Contact.SObjectType
    }
  );
}
