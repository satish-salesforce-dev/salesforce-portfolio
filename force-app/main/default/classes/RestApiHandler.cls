/**
 * @description Utility class for handling REST API integrations
 * @author Satish Kumar Illuri
 */
public with sharing class RestApiHandler {
    
    private static final Integer MAX_RETRY_COUNT = 3;
    private static final Integer TIMEOUT_MS = 120000;
    
    /**
     * @description Make REST API callout with retry mechanism
     * @param endpoint Named Credential or endpoint URL
     * @param method HTTP method (GET, POST, PUT, DELETE)
     * @param body Request body as JSON string
     * @return HttpResponse
     */
    public static HttpResponse makeCallout(String endpoint, String method, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + endpoint);
        req.setMethod(method);
        req.setTimeout(TIMEOUT_MS);
        
        if(String.isNotBlank(body)) {
            req.setBody(body);
            req.setHeader('Content-Type', 'application/json');
        }
        
        Http http = new Http();
        HttpResponse res = null;
        
        // Retry logic
        for(Integer i = 0; i < MAX_RETRY_COUNT; i++) {
            try {
                res = http.send(req);
                if(res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    break; // Success
                } else if(i < MAX_RETRY_COUNT - 1) {
                    // Exponential backoff
                    Integer delay = (Integer)Math.pow(2, i) * 1000;
                    System.debug('Retry ' + (i+1) + ' after ' + delay + 'ms');
                    wait(delay);
                }
            } catch(Exception e) {
                System.debug('Callout attempt ' + (i+1) + ' failed: ' + e.getMessage());
                if(i == MAX_RETRY_COUNT - 1) {
                    throw new CalloutException('Max retries reached: ' + e.getMessage());
                }
            }
        }
        
        // Log the callout
        logCallout(endpoint, method, res);
        return res;
    }
    
    /**
     * @description Parse JSON response to specific type
     */
    public static Object parseResponse(HttpResponse res, Type resultType) {
        if(res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            return JSON.deserialize(res.getBody(), resultType);
        }
        return null;
    }
    
    /**
     * @description Log callout details for monitoring
     */
    private static void logCallout(String endpoint, String method, HttpResponse res) {
        // Implementation for logging to custom object
        // This is a placeholder for actual logging logic
        System.debug('Callout: ' + endpoint + ' | Method: ' + method + 
                    ' | Status: ' + (res != null ? res.getStatusCode() : 'No response'));
    }
    
    /**
     * @description Wait utility for retry mechanism
     */
    private static void wait(Integer delay) {
        Long startingTime = System.now().getTime();
        while(System.now().getTime() - startingTime < delay) {
            // Do nothing, just wait
        }
    }
    
    public class CalloutException extends Exception {}
}
