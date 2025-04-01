/**
 * @description Provides an Invocable Action to interrogate a warehouse system for item quantity.
 * Uses the AI_ApiCallUtility class for the underlying HTTP callout.
 * @group Antoine
 */
public with sharing class AI_WarehouseQuantity {

    // Hardcoded endpoint for the warehouse quantity API
    private static final String WAREHOUSE_ENDPOINT = 'https://miniwarehouse-ce59a058c23c.herokuapp.com/quantity';
    private static final String HTTP_METHOD = 'POST';
    private static final String HEADERS_JSON = '{"Content-Type":"application/json"}';

    /**
     * @description Input wrapper class for the Invocable Method.
     */
    public class WarehouseRequest {
        @InvocableVariable(label='warehouseName' description='String with the name of the warehouse to interrogate' required=true)
        public String warehouseName;
    }

    /**
     * @description Output wrapper class for the Invocable Method.
     */
    public class WarehouseResponse {
        @InvocableVariable(label='warehouseQuantity' description='String with the available quantity, incoming quantity, and forecasted quantity of item at a specific warehouse (JSON format)')
        public String warehouseQuantity; // Output will be a JSON string
    }

    /**
     * @description Invocable method to get warehouse quantity information.
     * @param requests List containing the warehouse names to query.
     * @return List of responses containing the quantity details as a JSON string or an error message.
     */
    @InvocableMethod(
        label='Warehouse Item Quantity'
        description='Interrogate the warehouse system to know what is the quantity of item available, in transit, and forecasted at a specific warehouse'
        category='Antoine'
        callout=true // Indicate that this method performs a callout
    )
    public static List<WarehouseResponse> getWarehouseQuantity(List<WarehouseRequest> requests) {
        List<WarehouseResponse> responses = new List<WarehouseResponse>();
        List<AI_ApiCallUtility.RequestWrapper> calloutRequests = new List<AI_ApiCallUtility.RequestWrapper>();

        // Prepare callout requests for each input request
        for (WarehouseRequest req : requests) {
            if (String.isBlank(req.warehouseName)) {
                // Handle blank input - create an error response directly
                WarehouseResponse errorResp = new WarehouseResponse();
                Map<String, String> errorMap = new Map<String, String>{
                    'error' => 'Input Error',
                    'message' => 'Warehouse name cannot be blank.'
                };
                errorResp.warehouseQuantity = JSON.serialize(errorMap);
                responses.add(errorResp);
                // Skip adding to calloutRequests for this invalid input
                continue;
            }

            // Construct the payload using a Map and JSON.serialize for safety
            Map<String, String> payloadMap = new Map<String, String>();
            payloadMap.put('warehouseName', req.warehouseName);
            String jsonPayload = JSON.serialize(payloadMap);

            // Create the request wrapper for the utility class
            AI_ApiCallUtility.RequestWrapper calloutReq = new AI_ApiCallUtility.RequestWrapper();
            calloutReq.method = HTTP_METHOD;
            calloutReq.endpoint = WAREHOUSE_ENDPOINT;
            calloutReq.payload = jsonPayload;
            calloutReq.headersJson = HEADERS_JSON;
            // Optionally set timeout if needed: calloutReq.timeout = 30000; // 30 seconds

            calloutRequests.add(calloutReq);

            // Add a placeholder response for now; will be updated after callout
            // This ensures the response list matches the request list size if some inputs were invalid
             if (responses.size() < calloutRequests.size()) {
                 // Only add placeholder if we didn't already add an error response above
                 responses.add(new WarehouseResponse());
             }
        }

        // Perform the callouts only if there are valid requests to send
        List<AI_ApiCallUtility.ResponseWrapper> calloutResponses = new List<AI_ApiCallUtility.ResponseWrapper>();
        if (!calloutRequests.isEmpty()) {
             calloutResponses = AI_ApiCallUtility.makeHttpCallout(calloutRequests);
        }


        // Process the callout responses and map them back to our final response list
        Integer calloutResponseIndex = 0;
        for (Integer i = 0; i < requests.size(); i++) {
             // Skip processing if we already added an error response for this index earlier
             if (responses[i].warehouseQuantity != null) {
                 continue;
             }

            // Ensure we have a corresponding callout response
            if (calloutResponseIndex < calloutResponses.size()) {
                AI_ApiCallUtility.ResponseWrapper calloutResp = calloutResponses[calloutResponseIndex];
                WarehouseResponse finalResp = responses[i]; // Get the placeholder response

                if (calloutResp.isSuccess) {
                    // Success: Pass the response body directly as the output JSON string
                    finalResp.warehouseQuantity = calloutResp.body;
                } else {
                    // Failure: Construct an error JSON string
                    Map<String, Object> errorMap = new Map<String, Object>{
                        'error' => 'API Callout Failed',
                        'statusCode' => calloutResp.statusCode,
                        'statusMessage' => calloutResp.status,
                        'details' => calloutResp.errorMessage,
                        'responseBody' => calloutResp.body // Include API error body if available
                    };
                    finalResp.warehouseQuantity = JSON.serialize(errorMap);
                    System.debug('AI_WarehouseQuantity Error: Callout failed for warehouse "' + requests[i].warehouseName + '". Details: ' + finalResp.warehouseQuantity);
                }
                 calloutResponseIndex++; // Move to the next callout response
            } else {
                 // Should not happen if logic is correct, but handle defensively
                 WarehouseResponse errorResp = responses[i];
                 Map<String, String> errorMap = new Map<String, String>{
                     'error' => 'Processing Error',
                     'message' => 'Mismatch between requests and responses.'
                 };
                 errorResp.warehouseQuantity = JSON.serialize(errorMap);
                 System.debug('AI_WarehouseQuantity Error: Mismatch in response processing for warehouse "' + requests[i].warehouseName + '".');
            }

        }


        return responses;
    }
}