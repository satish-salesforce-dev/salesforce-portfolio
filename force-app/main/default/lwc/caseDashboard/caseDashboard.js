import { LightningElement, wire, track } from 'lwc';
import getCaseStats from '@salesforce/apex/CaseController.getCaseStats';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseDashboard extends LightningElement {
    @track caseStats = {};
    @track isLoading = true;
    wiredCaseStatsResult;

    @wire(getCaseStats)
    wiredStats(result) {
        this.wiredCaseStatsResult = result;
        if (result.data) {
            this.caseStats = result.data;
            this.isLoading = false;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load case statistics', 'error');
            this.isLoading = false;
        }
    }

    // Handle refresh button click
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredCaseStatsResult)
            .then(() => {
                this.showToast('Success', 'Dashboard refreshed', 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Calculate SLA compliance percentage
    get slaCompliance() {
        if (this.caseStats.totalCases && this.caseStats.slaMetCases) {
            return ((this.caseStats.slaMetCases / this.caseStats.totalCases) * 100).toFixed(1);
        }
        return 0;
    }

    // Show Toast message
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}
