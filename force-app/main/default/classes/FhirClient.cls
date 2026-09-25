/**
 * Thin HL7 FHIR R4 REST client.
 * All callouts go through the FHIR_Server Named Credential so no endpoint
 * or secret is ever stored in code (OAuth 2.0 handled by the External Credential).
 */
public with sharing class FhirClient {

    @TestVisible
    private static final String NAMED_CREDENTIAL = 'callout:FHIR_Server';
    private static final Integer TIMEOUT_MS = 20000;

    public class FhirException extends Exception {}

    /** GET a single resource, e.g. get('Patient', '123'). */
    public Map<String, Object> getResource(String resourceType, String id) {
        return send('GET', '/' + resourceType + '/' + EncodingUtil.urlEncode(id, 'UTF-8'));
    }

    /** Search a resource type, e.g. search('Observation', new Map<String,String>{'patient'=>'123'}). */
    public Map<String, Object> search(String resourceType, Map<String, String> params) {
        List<String> parts = new List<String>();
        for (String key : params.keySet()) {
            parts.add(EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8'));
        }
        String query = parts.isEmpty() ? '' : '?' + String.join(parts, '&');
        return send('GET', '/' + resourceType + query);
    }

    private Map<String, Object> send(String method, String path) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + path);
        req.setMethod(method);
        req.setTimeout(TIMEOUT_MS);
        req.setHeader('Accept', 'application/fhir+json');

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() < 200 || res.getStatusCode() > 299) {
            throw new FhirException('FHIR ' + method + ' ' + path + ' failed: ' + res.getStatusCode() + ' ' + res.getStatus());
        }
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }
}
