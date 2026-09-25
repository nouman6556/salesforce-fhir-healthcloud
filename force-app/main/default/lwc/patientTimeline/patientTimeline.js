import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getTimeline from '@salesforce/apex/PatientTimelineController.getTimeline';

// Contact.Description is used here only so the demo deploys to any org.
// In Health Cloud map this to the patient's FHIR identifier field.
import FHIR_ID_FIELD from '@salesforce/schema/Contact.Description';

const ICONS = {
    Encounter: 'standard:event',
    Observation: 'standard:metrics',
    Condition: 'standard:medication'
};

export default class PatientTimeline extends LightningElement {
    @api recordId;
    @api fhirPatientId; // optional override for App Builder
    events = [];
    error;
    isLoading = true;
    activeFilter = 'All';

    @wire(getRecord, { recordId: '$recordId', fields: [FHIR_ID_FIELD] })
    contact;

    get patientId() {
        return this.fhirPatientId || getFieldValue(this.contact.data, FHIR_ID_FIELD);
    }

    @wire(getTimeline, { fhirPatientId: '$patientId' })
    wiredTimeline({ data, error }) {
        if (data) {
            this.events = data.map((e) => ({ ...e, icon: ICONS[e.category] || 'standard:record' }));
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Unknown error';
            this.isLoading = false;
        }
    }

    get filters() {
        return ['All', 'Encounter', 'Observation', 'Condition'].map((value) => ({
            value,
            label: value === 'All' ? 'All' : `${value}s`,
            variant: value === this.activeFilter ? 'brand' : 'neutral'
        }));
    }

    get visibleEvents() {
        return this.activeFilter === 'All'
            ? this.events
            : this.events.filter((e) => e.category === this.activeFilter);
    }

    get hasEvents() {
        return this.visibleEvents.length > 0;
    }

    handleFilter(event) {
        this.activeFilter = event.target.value;
    }
}
