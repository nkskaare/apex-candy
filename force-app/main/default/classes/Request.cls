/**
 * General HTTP client for REST API's with JSON support and URL construction. Works as a layer around HttpRequest and HttpResponse objects.
 */
public virtual class Request implements IRequest {
  public HttpRequest httpRequest { get; private set; }
  public Request.IResponse response { get; private set; }
  public Request.Url url { get; private set; }

  public Request(String hostname) {
    this.httpRequest = new HttpRequest();
    this.url = new Request.Url(hostname);
  }

  public Request() {
    this.httpRequest = new HttpRequest();
  }

  /**
   * Url class constructs and modifies request url
   */
  public virtual class Url {
    public String hostname { get; private set; }
    public String path { get; private set; }
    public String endpoint { get; private set; }
    public Map<String, String> parameters { get; private set; }

    public Url(String hostname) {
      this(hostname, '');
    }

    public Url(String hostname, String path) {
      this.hostname = hostname;
      this.setPath(path);
      this.clearParameters();
    }

    /**
     * Sets url path
     * @param  path url path
     */
    public Url setPath(String path) {
      this.path = path;
      return this;
    }

    /**
     * Add a url parameter to querystring
     * @param field parameter field
     * @param value parameter value
     */
    public Url setParameter(String field, String value) {
      this.parameters.put(field, value);
      return this;
    }

    /**
     * Add a url parameter to querystring
     * @param field parameter field
     */
    public Url setParameters(Map<String, String> parameters) {
      this.parameters.putAll(parameters);
      return this;
    }

    /**
     * Remove a url parameter from querystring
     * @param field parameter field
     */
    public Url removeParameter(String field) {
      this.parameters.remove(field);
      return this;
    }

    /**
     * Clear all url parameters
     */
    public Url clearParameters() {
      this.parameters.clear();
      return this;
    }

    /**
     * Get final querystring from parameters
     */
    public String getQueryString() {
      return Request.getQueryString(this.parameters);
    }

    /**
     * Get complete url/endpoint
     */
    public virtual String getEndpoint() {
      this.endpoint = hostname + path;

      String queryString = this.getQueryString();
      if (String.isNotBlank(queryString)) {
        this.endpoint += '?' + queryString;
      }
      return this.endpoint;
    }
  }

  public interface IResponse {
    void setResponse(HttpResponse res);

    Boolean isSuccess();

    String status();
  }

  /**
   * Response class serializes JSON. Works as a layer around HttpResponse.
   */
  public virtual class Response implements IResponse {
    public HttpResponse httpResponse { get; private set; }

    public Response() {
    }

    public Response(HttpResponse res) {
      this.setResponse(res);
    }

    public void setResponse(HttpResponse res) {
      this.httpResponse = res;
    }

    /**
     * Checks if response is success. Overridable.
     * Status code begins with '2' defined as success.
     */
    public virtual Boolean isSuccess() {
      String statusCode = String.valueOf(this.httpResponse.getStatusCode());
      return (statusCode.left(1) == '2');
    }

    public virtual String status() {
      return String.valueOf(this.httpResponse.getStatusCode()) +
        ' : ' +
        this.httpResponse.getStatus();
    }

    /**
     * Parse JSON string to map
     */
    public Map<String, Object> asMap() {
      return (Map<String, Object>) JSON.deserializeUntyped(
        this.httpResponse.getBody()
      );
    }

    /**
     * Parse JSON string to object
     */
    public Object asObject(Type apexType) {
      return JSON.deserialize(this.httpResponse.getBody(), apexType);
    }

    /**
     * Get response as string
     */
    public String asString() {
      return this.httpResponse.getBody();
    }

    /**
     * Get response object
     */
    public HttpResponse raw() {
      return this.httpResponse;
    }
  }

  public class SendException extends Exception {
  }

  /**
   * Set hostname for request
   */
  public void setHostname(String hostname) {
    this.url = new Request.Url(hostname);
  }

  public virtual void authorize() {
  }

  /**
   * Can be extended and used with API's requiring authentication.
   */
  public virtual Boolean isAuthorized() {
    return true;
  }

  public void resetRequest() {
    this.httpRequest = new HttpRequest();
    this.url.clearParameters();
  }

  public virtual void setResponse(HttpResponse res) {
    Type cls = Type.forName('Request.Response');
    this.setResponse(res, cls);
  }

  public void setResponse(HttpResponse res, Type cls) {
    this.response = (IResponse) cls.newInstance();
    this.response.setResponse(res);
  }

  public void setHeaders(Map<String, String> headers) {
    for (String key : headers.keySet()) {
      this.httpRequest.setHeader(key, headers.get(key));
    }
  }

  /**
   * Make POST call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void post(String body, String path) {
    this.httpRequest.setBody(body);
    this.send(path, 'POST');
  }

  /**
   * Make POST call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void post(Map<String, Object> body, String path) {
    this.httpRequest.setHeader('Content-Type', 'application/json');
    this.post(ApplicationService.mapToJSON(body), path);
  }

  /**
   * Make POST call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void post(Object body, String path) {
    this.httpRequest.setHeader('Content-Type', 'application/json');
    this.post(JSON.serialize(body, true), path);
  }

  /**
   * Make GET call
   * @param path
   */
  public virtual void get(String path) {
    this.send(path, 'GET');
  }

  /**
   * Make PUT call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void put(String body, String path) {
    this.httpRequest.setBody(body);
    this.send(path, 'PUT');
  }

  /**
   * Make PUT call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void put(Map<String, Object> body, String path) {
    this.httpRequest.setHeader('Content-Type', 'application/json');
    this.put(ApplicationService.mapToJSON(body), path);
  }

  /**
   * Make PUT call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void put(Object body, String path) {
    this.httpRequest.setHeader('Content-Type', 'application/json');
    this.put(JSON.serialize(body, true), path);
  }

  /**
   * Make PATCH call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void patch(String body, String path) {
    this.httpRequest.setBody(body);
    this.send(path, 'PATCH');
  }

  /**
   * Make PATCH call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void patch(Map<String, Object> body, String path) {
    this.httpRequest.setHeader('Content-Type', 'application/json');
    this.patch(ApplicationService.mapToJSON(body), path);
  }

  /**
   * Make PATCH call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void patch(Object body, String path) {
    this.httpRequest.setHeader('Content-Type', 'application/json');
    this.patch(JSON.serialize(body, true), path);
  }

  /**
   * Make DELETE call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void del(String body, String path) {
    this.httpRequest.setBody(body);
    this.send(path, 'DELETE');
  }

  /**
   * Make DELETE call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void del(Map<String, Object> body, String path) {
    this.httpRequest.setHeader('Content-Type', 'application/json');
    this.del(ApplicationService.mapToJSON(body), path);
  }

  /**
   * Make DELETE call
   * @param body Request body
   * @param path Request url path
   */
  public virtual void del(Object body, String path) {
    this.httpRequest.setHeader('Content-Type', 'application/json');
    this.del(JSON.serialize(body, true), path);
  }

  /**
   * Send request
   * @param body request body
   * @param path request url path
   * @param method request method
   */
  public virtual void send(String body, String path, String method) {
    this.httpRequest.setBody(body);
    this.send(path, method);
  }

  /**
   * Send request
   * @param path request url path
   * @param method request method
   */
  public virtual void send(String path, String method) {
    this.httpRequest.setMethod(method);
    this.url.setPath(path);
    this.send();
  }

  /**
   * Send request
   * @throws Request.SendException
   */
  public virtual void send() {
    this.httpRequest.setEndpoint(this.url.getEndpoint());
    System.debug(this.httpRequest.getEndpoint());
    this.setResponse(new Http().send(this.httpRequest));
    if (!this.response.isSuccess()) {
      throw new SendException(this.response.status());
    }
    this.resetRequest();
  }

  /**
   * Generate querystring from map
   * @param parameters Map of field value pairs
   * @return querystring
   */
  public static String getQueryString(Map<String, String> parameters) {
    String queryString = '';
    List<String> fields = new List<String>(parameters.keySet());

    for (Integer i = 0; i < fields.size(); i++) {
      String field = fields[i];
      String value = parameters.get(field);
      queryString += field + '=' + value;
      if (i != fields.size() - 1) {
        queryString += '&';
      }
    }

    return queryString;
  }
}
