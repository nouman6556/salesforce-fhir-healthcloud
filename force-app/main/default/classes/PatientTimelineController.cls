/**
 * LWC controller: builds a chronological clinical timeline (encounters,
 * observations, conditions) for a FHIR patient id stored on the Contact.
 */
public with sharing class PatientTimelineController {

    public class TimelineEvent implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String category;   // Encounter | Observation | Condition
        @AuraEnabled public String title;
        @AuraEnabled public String detail;
        @AuraEnabled public Date eventDate;

        public Integer compareTo(Object other) {
            Date o = ((TimelineEvent) other).eventDate;
            if (eventDate == o) { return 0; }
            if (eventDate == null) { return 1; }
            if (o == null) { return -1; }
            return eventDate > o ? -1 : 1; // newest first
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<TimelineEvent> getTimeline(String fhirPatientId) {
        if (String.isBlank(fhirPatientId)) {
            return new List<TimelineEvent>();
        }
        try {
            FhirClient client = new FhirClient();
            Map<String, String> byPatient = new Map<String, String>{ 'patient' => fhirPatientId, '_count' => '50' };
            List<TimelineEvent> events = new List<TimelineEvent>();

            for (Map<String, Object> r : FhirBundleParser.entries(client.search('Encounter', byPatient))) {
                Map<String, Object> period = (Map<String, Object>) r.get('period');
                List<Object> types = (List<Object>) r.get('type');
                String typeText = null;
                if (types != null && !types.isEmpty()) {
                    typeText = (String) ((Map<String, Object>) types[0]).get('text');
                }
                events.add(build((String) r.get('id'), 'Encounter',
                    typeText != null ? typeText : 'Encounter',
                    (String) r.get('status'),
                    period == null ? null : FhirBundleParser.toDate(period.get('start'))));
            }
            for (Map<String, Object> r : FhirBundleParser.entries(client.search('Observation', byPatient))) {
                Map<String, Object> qty = (Map<String, Object>) r.get('valueQuantity');
                String value = qty == null ? null : String.valueOf(qty.get('value')) + ' ' + String.valueOf(qty.get('unit'));
                events.add(build((String) r.get('id'), 'Observation',
                    FhirBundleParser.conceptText(r, 'code'), value,
                    FhirBundleParser.toDate(r.get('effectiveDateTime'))));
            }
            for (Map<String, Object> r : FhirBundleParser.entries(client.search('Condition', byPatient))) {
                events.add(build((String) r.get('id'), 'Condition',
                    FhirBundleParser.conceptText(r, 'code'),
                    FhirBundleParser.conceptText(r, 'clinicalStatus'),
                    FhirBundleParser.toDate(r.get('onsetDateTime'))));
            }
            events.sort();
            return events;
        } catch (FhirClient.FhirException e) {
            throw new AuraHandledException('Unable to load clinical timeline: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<CareGapService.CareGap> getCareGaps(String fhirPatientId) {
        try {
            return new CareGapService(new FhirClient()).evaluate(fhirPatientId);
        } catch (FhirClient.FhirException e) {
            throw new AuraHandledException('Unable to evaluate care gaps: ' + e.getMessage());
        }
    }

    private static TimelineEvent build(String id, String category, String title, String detail, Date d) {
        TimelineEvent e = new TimelineEvent();
        e.id = category + '-' + id;
        e.category = category;
        e.title = title;
        e.detail = detail;
        e.eventDate = d;
        return e;
    }
}
