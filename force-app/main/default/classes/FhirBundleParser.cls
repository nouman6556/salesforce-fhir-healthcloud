/**
 * Helpers for walking FHIR R4 JSON (Bundles, CodeableConcepts, references)
 * without generating hundreds of wrapper classes.
 */
public inherited sharing class FhirBundleParser {

    /** Returns the resource maps inside a searchset Bundle. */
    public static List<Map<String, Object>> entries(Map<String, Object> bundle) {
        List<Map<String, Object>> resources = new List<Map<String, Object>>();
        List<Object> entryList = (List<Object>) bundle.get('entry');
        if (entryList == null) {
            return resources;
        }
        for (Object e : entryList) {
            Map<String, Object> entry = (Map<String, Object>) e;
            if (entry.get('resource') != null) {
                resources.add((Map<String, Object>) entry.get('resource'));
            }
        }
        return resources;
    }

    /** First coding code of a CodeableConcept field, e.g. Observation.code. */
    public static String firstCode(Map<String, Object> resource, String field) {
        Map<String, Object> concept = (Map<String, Object>) resource.get(field);
        if (concept == null || concept.get('coding') == null) {
            return null;
        }
        List<Object> codings = (List<Object>) concept.get('coding');
        return codings.isEmpty() ? null : (String) ((Map<String, Object>) codings[0]).get('code');
    }

    /** Human readable text of a CodeableConcept (text, else first display). */
    public static String conceptText(Map<String, Object> resource, String field) {
        Map<String, Object> concept = (Map<String, Object>) resource.get(field);
        if (concept == null) {
            return null;
        }
        if (concept.get('text') != null) {
            return (String) concept.get('text');
        }
        List<Object> codings = (List<Object>) concept.get('coding');
        return (codings == null || codings.isEmpty()) ? null : (String) ((Map<String, Object>) codings[0]).get('display');
    }

    /** Parses FHIR date / dateTime strings (YYYY, YYYY-MM-DD or full ISO). */
    public static Date toDate(Object value) {
        if (value == null) {
            return null;
        }
        String s = (String) value;
        if (s.length() == 4) {
            return Date.newInstance(Integer.valueOf(s), 1, 1);
        }
        return Date.valueOf(s.left(10));
    }
}
