/**
 * Collection of useful methods for working with HttpRequest, HttpResponse and Url construction
 * 
 * @author nkskaare
 */
public virtual class Request {

    public Request() {
    }

    /**
     * Url class constructs and modifies Request url
     */
    public virtual class Url {
        public String hostname { get; private set; }
        public String path { get; private set; }
        public Map<String, String> parameters { get; private set; }

        public Url(String hostname) {
            this(hostname, '');
        }

        public Url(String hostname, String path) {
            this.hostname = hostname;
            this.setPath(path);
            this.parameters = new Map<String, String>();
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
            String endpoint = this.hostname + this.path;

            String queryString = getQueryString();
            if (String.isNotBlank(queryString)) {
                endpoint += '?' + queryString;
            }
            return endpoint;
        }
    }

    /**
     * Checks if response is success.
     * Status code begins with '2' defined as success.
     */
    public virtual Boolean isSuccess(HttpResponse res) {
        String statusCode = String.valueOf(res.getStatusCode());
        return (statusCode.left(1) == '2');
    }

    /**
     * Status code and message as one string, for logging purposes
     */
    public virtual String getStatusMessage(HttpResponse res) {
        return String.valueOf(res.getStatusCode()) + ' : ' + res.getStatus();
    }

    /**
     * Parse JSON string response to map
     */
    public Map<String, Object> getAsMap(HttpResponse res) {
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }

    /**
     * Parse JSON string response to object
     */
    public Object getAsObject(Type apexType, HttpResponse res) {
        return JSON.deserialize(res.getBody(), apexType);
    }

    public class SendException extends Exception {
    }

    /**
     * Simple shorthand creation of new HttpRequest from Url
     * 
     * @param url
     */
    public virtual HttpRequest newRequest(Request.Url url) {
        return this.setUrl(url, new HttpRequest);
    }

    /**
     * Simple creation of a JSON request
     *
     * @param body request body
     * @param url request url
     */
    public virtual HttpRequest newJSONRequest(
        Map<String, Object> body,
        Request.Url url
    ) {
        HttpRequest req = new HttpRequest();
        req.setBody(Request.mapToJSON(body));
        this.setHeaders(
            new Map<String, String>{ 'Content-Type' => 'application/json' },
            req
        );
        this.setUrl(url, req);
        return req;
    }

    /**
     * Set headers on request
     *
     * @param headers Map containting headers key and values
     * @param req Request to set headers on
     */
    public HttpRequest setHeaders(
        Map<String, String> headers,
        HttpRequest req
    ) {
        for (String key : headers.keySet()) {
            req.setHeader(key, headers.get(key));
        }
        return req;
    }

    /**
     * Set endpoint on request from Url instance
     *
     * @param url Url class instance with hostname and path
     * @param req Request to set endpoint on
     */
    public HttpRequest setUrl(Request.Url url, HttpRequest req) {
        req.setEndpoint(url.getEndpoint());
        return req;
    }

    /**
     * Shorthand POST request
     *
     * @param req HttpRequest object
     */
    public virtual HttpResponse post(HttpRequest req) {
        req.setMethod('POST');
        return this.send(req);
    }

    /**
     * Shorthand GET request
     *
     * @param req HttpRequest object
     */
    public virtual HttpResponse get(HttpRequest req) {
        req.setMethod('GET');
        return this.send(req);
    }

    /**
     * Shorthand PUT request
     *
     * @param req HttpRequest object
     */
    public virtual HttpResponse put(HttpRequest req) {
        req.setMethod('PUT');
        return this.send(req);
    }

    /**
     * Shorthand PATCH request
     *
     * @param req HttpRequest object
     */
    public virtual HttpResponse patch(HttpRequest req) {
        req.setMethod('PATCH');
        return this.send(req);
    }

    /**
     * Shorthand DELETE request
     *
     * @param req HttpRequest object
     */
    public virtual HttpResponse del(HttpRequest req) {
        req.setMethod('DELETE');
        return this.send(req);
    }

    /**
     * General send HttpRequest method and response check
     *
     * @param req HttpRequest object
     * @throws SendException
     */
    public virtual HttpResponse send(HttpRequest req) {
        HttpResponse res = new Http().send(req);

        if (!(this.isSuccess(res))) {
            throw new SendException(this.getStatusMessage(res));
        }
        return res;
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

    /**
     * Converts a map of different datatypes, but depth of 1, to a JSON string.
     * Avoids the need to create a class for simple JSON generation.
     *
     * @param dataMap
     */
    public static String mapToJSON(Map<String, Object> dataMap) {
        JSONGenerator generator = JSON.createGenerator(true);

        generator.writeStartObject();
        for (String field : dataMap.keySet()) {
            Object value = dataMap.get(field);

            if (value instanceof String) {
                generator.writeStringField(field, (String) value);
            } else if (value instanceof Integer) {
                generator.writeNumberField(field, (Integer) value);
            } else if (value instanceof Decimal) {
                generator.writeNumberField(field, (Decimal) value);
            } else if (value instanceof Long) {
                generator.writeNumberField(field, (Long) value);
            } else if (value instanceof Id) {
                generator.writeIdField(field, (Id) value);
            } else if (value instanceof Boolean) {
                generator.writeBooleanField(field, (Boolean) value);
            } else if (value instanceof Datetime) {
                generator.writeDateTimeField(field, (Datetime) value);
            } else if (value instanceof Date) {
                generator.writeDateField(field, (Date) value);
            } else if (value != null) {
                generator.writeObjectField(field, value);
            } else {
                generator.writeNullField(field);
            }
        }
        generator.writeEndObject();

        generator.close();
        return generator.getAsString();
    }
}
