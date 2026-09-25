@IsTest
public class FhirCalloutMock implements HttpCalloutMock {

    public Integer statusCode = 200;

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setStatus(statusCode == 200 ? 'OK' : 'Server Error');
        res.setHeader('Content-Type', 'application/fhir+json');
        String ep = req.getEndpoint();
        String recent = String.valueOf(Date.today().addMonths(-2));
        String old = String.valueOf(Date.today().addMonths(-20));
        if (ep.contains('/Observation')) {
            res.setBody('{"resourceType":"Bundle","type":"searchset","entry":['
                + '{"resource":{"resourceType":"Observation","id":"o1","code":{"coding":[{"system":"http://loinc.org","code":"4548-4","display":"Hemoglobin A1c"}],"text":"HbA1c"},'
                + '"effectiveDateTime":"' + recent + '","valueQuantity":{"value":6.8,"unit":"%"}}},'
                + '{"resource":{"resourceType":"Observation","id":"o2","code":{"coding":[{"code":"13457-7"}],"text":"LDL"},'
                + '"effectiveDateTime":"' + old + '","valueQuantity":{"value":130,"unit":"mg/dL"}}}]}');
        } else if (ep.contains('/Encounter')) {
            res.setBody('{"resourceType":"Bundle","entry":[{"resource":{"resourceType":"Encounter","id":"e1","status":"finished",'
                + '"type":[{"text":"Annual wellness visit"}],"period":{"start":"' + recent + 'T09:00:00Z"}}}]}');
        } else if (ep.contains('/Condition')) {
            res.setBody('{"resourceType":"Bundle","entry":[{"resource":{"resourceType":"Condition","id":"c1",'
                + '"code":{"text":"Type 2 diabetes mellitus"},"clinicalStatus":{"coding":[{"code":"active","display":"Active"}]},"onsetDateTime":"2019"}}]}');
        } else {
            res.setBody('{"resourceType":"Patient","id":"p1","name":[{"family":"Doe","given":["Jane"]}]}');
        }
        return res;
    }
}
