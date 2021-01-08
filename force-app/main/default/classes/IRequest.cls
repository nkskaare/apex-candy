public interface IRequest {

  Boolean isAuthorized();

  void authorize();
  
  void post(String body, String path);  

  void get(String path);

  void put(String body, String path);

  void patch(String body, String path);

  void del(String body, String path);

  void send();

}
