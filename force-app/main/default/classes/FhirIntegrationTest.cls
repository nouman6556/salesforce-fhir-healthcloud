@IsTest
private class FhirIntegrationTest {

    @IsTest
    static void timelineIsSortedNewestFirst() {
        Test.setMock(HttpCalloutMock.class, new FhirCalloutMock());
        Test.startTest();
        List<PatientTimelineController.TimelineEvent> events = PatientTimelineController.getTimeline('p1');
        Test.stopTest();

        Assert.areEqual(4, events.size(), 'Encounter + 2 observations + condition');
        for (Integer i = 1; i < events.size(); i++) {
            Assert.isTrue(events[i - 1].eventDate >= events[i].eventDate, 'Events must be newest first');
        }
    }

    @IsTest
    static void careGapsFlagOverdueMeasures() {
        Test.setMock(HttpCalloutMock.class, new FhirCalloutMock());
        Test.startTest();
        List<CareGapService.CareGap> gaps = PatientTimelineController.getCareGaps('p1');
        Test.stopTest();

        Map<String, CareGapService.CareGap> byCode = new Map<String, CareGapService.CareGap>();
        for (CareGapService.CareGap g : gaps) { byCode.put(g.loincCode, g); }

        Assert.isFalse(byCode.get('4548-4').isOpen, 'HbA1c done 2 months ago is not a gap');
        Assert.isTrue(byCode.get('13457-7').isOpen, 'LDL done 20 months ago is overdue');
        Assert.isTrue(byCode.get('85354-9').isOpen, 'Never-performed measure is open');
    }

    @IsTest
    static void serverErrorSurfacesAsAuraException() {
        FhirCalloutMock mock = new FhirCalloutMock();
        mock.statusCode = 500;
        Test.setMock(HttpCalloutMock.class, mock);
        Boolean thrown = false;
        Test.startTest();
        try {
            PatientTimelineController.getTimeline('p1');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();
        Assert.isTrue(thrown, 'HTTP 500 should raise AuraHandledException');
    }

    @IsTest
    static void getResourceAndBlankInputs() {
        Test.setMock(HttpCalloutMock.class, new FhirCalloutMock());
        Test.startTest();
        Map<String, Object> patient = new FhirClient().getResource('Patient', 'p1');
        Test.stopTest();
        Assert.areEqual('Patient', patient.get('resourceType'));
        Assert.areEqual(0, PatientTimelineController.getTimeline('').size());
        Assert.areEqual(Date.newInstance(2019, 1, 1), FhirBundleParser.toDate('2019'));
    }
}
