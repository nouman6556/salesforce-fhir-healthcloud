import { LightningElement, api, wire } from 'lwc';
import getCareGaps from '@salesforce/apex/PatientTimelineController.getCareGaps';

const COLUMNS = [
    { label: 'Measure', fieldName: 'measure' },
    { label: 'Last Performed', fieldName: 'lastPerformed', type: 'date-local' },
    { label: 'Due', fieldName: 'dueDate', type: 'date-local' },
    { label: 'Status', fieldName: 'status', cellAttributes: { class: { fieldName: 'statusClass' } } },
    { label: 'Recommendation', fieldName: 'recommendation', wrapText: true }
];

export default class CareGapPanel extends LightningElement {
    @api fhirPatientId;
    columns = COLUMNS;
    gaps;
    error;

    @wire(getCareGaps, { fhirPatientId: '$fhirPatientId' })
    wired({ data, error }) {
        if (data) {
            this.gaps = data.map((g) => ({
                ...g,
                status: g.isOpen ? 'Open' : 'Closed',
                statusClass: g.isOpen ? 'slds-text-color_error' : 'slds-text-color_success'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Unknown error';
        }
    }

    get openCount() {
        return this.gaps ? this.gaps.filter((g) => g.isOpen).length : 0;
    }

    get title() {
        return `Care Gaps (${this.openCount} open)`;
    }
}
