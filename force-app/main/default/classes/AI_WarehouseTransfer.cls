/**
 * @description Provides an Invocable Action to transfer item quantity between warehouses.
 * Uses the AI_ApiCallUtility class for the underlying HTTP callout.
 * @group Antoine
 */
public with sharing class AI_WarehouseTransfer {

    // Hardcoded endpoint for the warehouse transfer API
    private static final String TRANSFER_ENDPOINT = 'https://miniwarehouse-ce59a058c23c.herokuapp.com/transfer';
    private static final String HTTP_METHOD = 'POST';
    private static final String HEADERS_JSON = '{"Content-Type":"application/json"}';

    /**
     * @description Input wrapper class for the Invocable Method.
     */
    public class TransferRequest {
        @InvocableVariable(label='Origin Warehouse Name' description='The name of the warehouse to transfer stock FROM' required=true)
        public String originWarehouseName;

        @InvocableVariable(label='Destination Warehouse Name' description='The name of the warehouse to transfer stock TO' required=true)
        public String destinationWarehouseName;

        @InvocableVariable(label='Quantity to Transfer' description='The amount of stock to transfer' required=true)
        public Integer quantityTransfer; // Using Integer as per API example
    }

    /**
     * @description Output wrapper class for the Invocable Method.
     */
    public class TransferResponse {
        @InvocableVariable(label='Transfer Status' description='JSON string indicating the status of the transfer operation (success or error details)')
        public String transferStatus; // Output will be a JSON string
    }

    /**
     * @description Invocable method to perform a warehouse quantity transfer.
     * @param requests List containing the transfer details.
     * @return List of responses containing the status of each transfer attempt as a JSON string.
     */
    @InvocableMethod(
        label='Warehouse Item Transfer' // Added label
        description='Transfers a specified quantity of an item from an origin warehouse to a destination warehouse.' // Added description
        category='Antoine'
        callout=true // Indicate that this method performs a callout
    )
    public static List<TransferResponse> transferWarehouseQuantity(List<TransferRequest> requests) {
        List<TransferResponse> responses = new List<TransferResponse>();
        List<AI_ApiCallUtility.RequestWrapper> calloutRequests = new List<AI_ApiCallUtility.RequestWrapper>();

        // Prepare callout requests for each input request
        for (TransferRequest req : requests) {
            // --- Input Validation ---
            String validationError = null;
            if (String.isBlank(req.originWarehouseName)) {
                validationError = 'Origin Warehouse Name cannot be blank.';
            } else if (String.isBlank(req.destinationWarehouseName)) {
                validationError = 'Destination Warehouse Name cannot be blank.';
            } else if (req.quantityTransfer == null || req.quantityTransfer <= 0) {
                 validationError = 'Quantity to Transfer must be a positive number.';
            } else if (req.originWarehouseName == req.destinationWarehouseName) {
                 validationError = 'Origin and Destination warehouses cannot be the same.';
            }

            if (validationError != null) {
                // Handle validation error - create an error response directly
                TransferResponse errorResp = new TransferResponse();
                Map<String, String> errorMap = new Map<String, String>{
                    'status' => 'Error',
                    'message' => 'Input Validation Failed',
                    'details' => validationError
                };
                errorResp.transferStatus = JSON.serialize(errorMap);
                responses.add(errorResp);
                // Skip adding to calloutRequests for this invalid input
                continue;
            }
            // --- End Input Validation ---


            // Construct the payload using a Map and JSON.serialize for safety
            Map<String, Object> payloadMap = new Map<String, Object>();
            payloadMap.put('originWarehouseName', req.originWarehouseName);
            payloadMap.put('destinationWarehouseName', req.destinationWarehouseName);
            payloadMap.put('quantityTransfer', req.quantityTransfer);
            String jsonPayload = JSON.serialize(payloadMap);

            // Create the request wrapper for the utility class
            AI_ApiCallUtility.RequestWrapper calloutReq = new AI_ApiCallUtility.RequestWrapper();
            calloutReq.method = HTTP_METHOD;
            calloutReq.endpoint = TRANSFER_ENDPOINT;
            calloutReq.payload = jsonPayload;
            calloutReq.headersJson = HEADERS_JSON;

            calloutRequests.add(calloutReq);

            // Add a placeholder response; will be updated after callout
             if (responses.size() < calloutRequests.size()) {
                 responses.add(new TransferResponse());
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
             // Skip processing if we already added an error response for this index due to validation
             if (responses[i].transferStatus != null) {
                 continue;
             }

            // Ensure we have a corresponding callout response
            if (calloutResponseIndex < calloutResponses.size()) {
                AI_ApiCallUtility.ResponseWrapper calloutResp = calloutResponses[calloutResponseIndex];
                TransferResponse finalResp = responses[i]; // Get the placeholder response

                if (calloutResp.isSuccess) {
                    // Success: Construct a success JSON string
                     Map<String, Object> successMap = new Map<String, Object>{
                        'status' => 'Success',
                        'message' => 'Transfer initiated successfully.',
                        'details' => calloutResp.body // Include response body from API if any
                    };
                    finalResp.transferStatus = JSON.serialize(successMap);
                } else {
                    // Failure: Construct an error JSON string
                    Map<String, Object> errorMap = new Map<String, Object>{
                        'status' => 'Error',
                        'message' => 'API Callout Failed',
                        'statusCode' => calloutResp.statusCode,
                        'statusMessage' => calloutResp.status,
                        'details' => calloutResp.errorMessage,
                        'responseBody' => calloutResp.body // Include API error body if available
                    };
                    finalResp.transferStatus = JSON.serialize(errorMap);
                     System.debug('AI_WarehouseTransfer Error: Callout failed for transfer from "' + requests[i].originWarehouseName + '" to "' + requests[i].destinationWarehouseName + '". Details: ' + finalResp.transferStatus);
                }
                 calloutResponseIndex++; // Move to the next callout response
            } else {
                 // Handle defensively - should not happen if logic is correct
                 TransferResponse errorResp = responses[i];
                 Map<String, String> errorMap = new Map<String, String>{
                     'status' => 'Error',
                     'message' => 'Processing Error',
                     'details' => 'Mismatch between requests and responses.'
                 };
                 errorResp.transferStatus = JSON.serialize(errorMap);
                 System.debug('AI_WarehouseTransfer Error: Mismatch in response processing for transfer from "' + requests[i].originWarehouseName + '" to "' + requests[i].destinationWarehouseName + '".');
            }
        }

        return responses;
    }
}