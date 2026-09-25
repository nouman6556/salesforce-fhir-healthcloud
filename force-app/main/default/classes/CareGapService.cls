/**
 * Rule-based care-gap evaluation (HEDIS-style) over FHIR Observations.
 * Each rule: LOINC code that must have been observed within N months.
 * Rules are data, so they can be moved to Custom Metadata without code change.
 */
public with sharing class CareGapService {

    public class CareGap {
        @AuraEnabled public String measure;
        @AuraEnabled public String loincCode;
        @AuraEnabled public Date lastPerformed;
        @AuraEnabled public Date dueDate;
        @AuraEnabled public Boolean isOpen;
        @AuraEnabled public String recommendation;
    }

    public class Rule {
        public String measure;
        public String loincCode;
        public Integer intervalMonths;
        public String recommendation;
        public Rule(String measure, String loinc, Integer months, String rec) {
            this.measure = measure; this.loincCode = loinc; this.intervalMonths = months; this.recommendation = rec;
        }
    }

    @TestVisible
    private static List<Rule> rules = new List<Rule>{
        new Rule('Diabetes HbA1c test', '4548-4', 6, 'Order HbA1c lab and schedule follow-up.'),
        new Rule('Blood pressure check', '85354-9', 12, 'Schedule BP screening at next visit.'),
        new Rule('LDL cholesterol screening', '13457-7', 12, 'Order lipid panel.'),
        new Rule('BMI assessment', '39156-5', 12, 'Record height/weight at next encounter.')
    };

    private final FhirClient client;

    public CareGapService(FhirClient client) {
        this.client = client;
    }

    public List<CareGap> evaluate(String fhirPatientId) {
        List<CareGap> gaps = new List<CareGap>();
        if (String.isBlank(fhirPatientId)) {
            return gaps;
        }
        Map<String, Date> latestByCode = new Map<String, Date>();
        Map<String, Object> bundle = client.search('Observation',
            new Map<String, String>{ 'patient' => fhirPatientId, '_count' => '200' });

        for (Map<String, Object> obs : FhirBundleParser.entries(bundle)) {
            String code = FhirBundleParser.firstCode(obs, 'code');
            Date d = FhirBundleParser.toDate(obs.get('effectiveDateTime'));
            if (code != null && d != null && (!latestByCode.containsKey(code) || d > latestByCode.get(code))) {
                latestByCode.put(code, d);
            }
        }

        Date today = Date.today();
        for (Rule r : rules) {
            CareGap g = new CareGap();
            g.measure = r.measure;
            g.loincCode = r.loincCode;
            g.lastPerformed = latestByCode.get(r.loincCode);
            g.dueDate = g.lastPerformed == null ? today : g.lastPerformed.addMonths(r.intervalMonths);
            g.isOpen = g.dueDate <= today;
            g.recommendation = g.isOpen ? r.recommendation : 'Up to date';
            gaps.add(g);
        }
        return gaps;
    }
}
