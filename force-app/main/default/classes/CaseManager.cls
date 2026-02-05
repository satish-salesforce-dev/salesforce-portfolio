/**
 * @description Case Manager Apex Class
 * @author Satish Kumar Illuri
 * @date 2024
 * @group Case Management
 * @see CaseTriggerHandler
 */
public with sharing class CaseManager {
    
    /**
     * @description Update case priority based on SLA violation
     * @param caseIds List of Case IDs to process
     */
    public static void updatePriorityBasedOnSLA(List<Id> caseIds) {
        List<Case> casesToUpdate = new List<Case>();
        
        for(Case c : [SELECT Id, Priority, SLA_Violation__c, CreatedDate 
                      FROM Case 
                      WHERE Id IN :caseIds 
                      AND Status != 'Closed'
                      WITH SECURITY_ENFORCED]) {
            
            // Business logic: If SLA is violated, set to High priority
            if(c.SLA_Violation__c == true && c.Priority != 'High') {
                casesToUpdate.add(new Case(
                    Id = c.Id,
                    Priority = 'High',
                    SLA_Review_Date__c = System.now()
                ));
            }
        }
        
        if(!casesToUpdate.isEmpty()) {
            try {
                update casesToUpdate;
            } catch(DmlException e) {
                System.debug('Error updating cases: ' + e.getMessage());
                // Log error to custom object or platform event
            }
        }
    }
    
    /**
     * @description Batch Apex example for nightly case cleanup
     */
    public class CaseCleanupBatch implements Database.Batchable<sObject> {
        
        public Database.QueryLocator start(Database.BatchableContext bc) {
            // Query cases older than 1 year that are closed
            return Database.getQueryLocator(
                'SELECT Id, Description, IsClosed ' +
                'FROM Case ' +
                'WHERE IsClosed = true ' +
                'AND LastModifiedDate < LAST_N_DAYS:365 ' +
                'WITH SECURITY_ENFORCED'
            );
        }
        
        public void execute(Database.BatchableContext bc, List<Case> scope) {
            // Archive description field before cleanup
            for(Case c : scope) {
                // Archive logic here
                c.Description = 'Archived: ' + c.Description;
            }
            update scope;
        }
        
        public void finish(Database.BatchableContext bc) {
            // Send notification email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Case Cleanup Batch Completed');
            mail.setPlainTextBody('Batch processed successfully.');
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }
    }
}
