/**
 * @description Utility class to make HTTP callouts to external services, often used for AI integrations.
 * Contains an invocable method to be used in Flows and other Apex classes.
 */
public with sharing class AI_ApiCallUtility {

    /**
     * @description Wrapper class for input parameters required by the invocable method.
     */
    public class RequestWrapper {
        @InvocableVariable(label='HTTP Method' description='The HTTP method (GET, POST, PUT, PATCH)' required=true)
        public String method;

        @InvocableVariable(label='Endpoint URL' description='The full URL of the API endpoint' required=true)
        public String endpoint;

        @InvocableVariable(label='Request Payload (JSON)' description='The JSON payload for POST, PUT, or PATCH requests')
        public String payload;

        @InvocableVariable(label='Request Timeout (ms)' description='Timeout in milliseconds for the request' required=false)
        public Integer timeout = 60000; // Default to 60 seconds

        @InvocableVariable(label='Request Headers (JSON)' description='JSON string representing request headers as key-value pairs. E.g., {"Authorization":"Bearer YOUR_TOKEN", "Content-Type":"application/json"}')
        public String headersJson;
    }

    /**
     * @description Wrapper class for the output returned by the invocable method.
     */
    public class ResponseWrapper {
        @InvocableVariable(label='Is Success' description='Indicates if the callout was successful (status code 2xx)')
        public Boolean isSuccess;

        @InvocableVariable(label='Status Code' description='The HTTP status code returned by the server')
        public Integer statusCode;

        @InvocableVariable(label='Status Message' description='The HTTP status message returned by the server')
        public String status;

        @InvocableVariable(label='Response Body' description='The body of the response from the server')
        public String body;

        @InvocableVariable(label='Error Message' description='Details of any error that occurred during the callout')
        public String errorMessage;
    }

    /**
     * @description Invocable method to perform an HTTP callout.
     * @param requests A list of RequestWrapper objects containing callout details.
     * Flows typically send a list with a single element.
     * @return A list of ResponseWrapper objects containing the results of each callout.
     */
    @InvocableMethod(label='Make API Calls' description='Sends an HTTP request to an external service (often an API) and returns the response.' category='Antoine')
    public static List<ResponseWrapper> makeHttpCallout(List<RequestWrapper> requests) {
        List<ResponseWrapper> responses = new List<ResponseWrapper>();

        // Process each request in the input list
        for (RequestWrapper reqWrapper : requests) {
            ResponseWrapper respWrapper = new ResponseWrapper();
            HttpRequest req = new HttpRequest();
            Http http = new Http();
            HttpResponse res = null;

            try {
                // Validate required inputs
                if (String.isBlank(reqWrapper.method) || String.isBlank(reqWrapper.endpoint)) {
                    throw new CalloutException('HTTP Method and Endpoint URL are required.');
                }

                // Set Endpoint
                req.setEndpoint(reqWrapper.endpoint);

                // Set Method (convert to uppercase for consistency)
                req.setMethod(reqWrapper.method.toUpperCase());

                // Set Timeout
                req.setTimeout(reqWrapper.timeout == null ? 60000 : reqWrapper.timeout); // Use default if null

                // Set Headers from JSON string
                if (String.isNotBlank(reqWrapper.headersJson)) {
                    try {
                        Map<String, Object> headerMap = (Map<String, Object>) JSON.deserializeUntyped(reqWrapper.headersJson);
                        for (String key : headerMap.keySet()) {
                            // Ensure the value is treated as a String
                            req.setHeader(key, String.valueOf(headerMap.get(key)));
                        }
                    } catch (Exception e) {
                        throw new CalloutException('Error parsing Headers JSON: ' + e.getMessage());
                    }
                }

                // Set Body for methods that typically require it (POST, PUT, PATCH)
                String upperCaseMethod = reqWrapper.method.toUpperCase();
                if (upperCaseMethod == 'POST' || upperCaseMethod == 'PUT' || upperCaseMethod == 'PATCH') {
                    if (String.isNotBlank(reqWrapper.payload)) {
                        req.setBody(reqWrapper.payload);
                        // Automatically set Content-Type if not provided, assuming JSON
                        if (req.getHeader('Content-Type') == null) {
                           req.setHeader('Content-Type', 'application/json;charset=UTF-8');
                        }
                    }
                     // Optionally add a check here if payload is *required* for these methods
                     // else if (String.isBlank(reqWrapper.payload)) {
                     //    throw new CalloutException('Payload is required for POST, PUT, or PATCH methods.');
                     // }
                }

                // Perform the callout
                System.debug('AI_ApiCallUtility: Sending ' + req.getMethod() + ' request to ' + req.getEndpoint());
                if (!Test.isRunningTest()) { // Avoid actual callouts during tests unless mocked
                   res = http.send(req);
                } else {
                    // Provide a mock response during test execution
                    res = new HttpResponse();
                    res.setStatusCode(200);
                    res.setStatus('OK');
                    res.setBody('{"message":"Mock response during test"}');
                }


                // Process the response
                respWrapper.statusCode = res.getStatusCode();
                respWrapper.status = res.getStatus();
                respWrapper.body = res.getBody();
                // Consider status codes 200-299 as success
                respWrapper.isSuccess = (res.getStatusCode() >= 200 && res.getStatusCode() < 300);
                respWrapper.errorMessage = respWrapper.isSuccess ? null : 'Callout failed with status code ' + res.getStatusCode();
                System.debug('AI_ApiCallUtility: Received response. Status Code: ' + res.getStatusCode());

            } catch (Exception e) {
                // Handle exceptions (e.g., CalloutException, JSONException)
                System.debug('AI_ApiCallUtility Error: ' + e.getMessage() + '\nStackTrace: ' + e.getStackTraceString());
                respWrapper.isSuccess = false;
                respWrapper.errorMessage = 'Exception during callout: ' + e.getTypeName() + ': ' + e.getMessage();
                // Optionally set status code to a specific value for errors, e.g., 500
                respWrapper.statusCode = null; // Or set a default error code like 500
                respWrapper.status = 'Error';
                respWrapper.body = null;
            } finally {
                // Add the response wrapper (even if an error occurred) to the list
                responses.add(respWrapper);
            }
        }

        return responses;
    }

    /**
     * @description Example of how to call the utility directly from another Apex class.
     */
    public static void exampleUsageFromApex() {
        // Prepare the request
        RequestWrapper req = new RequestWrapper();
        req.method = 'GET';
        req.endpoint = 'https://jsonplaceholder.typicode.com/posts/1'; // Example public API
        req.payload = null; // No payload for GET
        req.headersJson = '{"Accept":"application/json"}'; // Example header

        // Call the method (needs to be in a list for the invocable method signature)
        List<RequestWrapper> requestList = new List<RequestWrapper>{ req };
        // No change needed here as it calls the static method directly
        List<ResponseWrapper> responseList = makeHttpCallout(requestList);

        // Process the response
        if (responseList != null && !responseList.isEmpty()) {
            ResponseWrapper resp = responseList[0];
            System.debug('Callout from Apex Example - Success: ' + resp.isSuccess);
            System.debug('Callout from Apex Example - Status Code: ' + resp.statusCode);
            System.debug('Callout from Apex Example - Body: ' + resp.body);
            if (resp.errorMessage != null) {
                System.debug('Callout from Apex Example - Error: ' + resp.errorMessage);
            }
        }
    }
}