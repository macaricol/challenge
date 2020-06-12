trigger OpportunityLineItem on OpportunityLineItem (before insert, after insert, before update, after update, before delete, after delete) {
    
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            OpportunityLineItemService.handleBeforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            OpportunityLineItemService.handleBeforeUpdate(Trigger.new);
        }
        if(Trigger.isDelete){
            OpportunityLineItemService.handleBeforeDelete(Trigger.oldMap);
        }
    }
    
    if(Trigger.isAfter){
        if(Trigger.IsInsert){
            OpportunityLineItemService.handleAfterInsert(Trigger.new);
        }
        if(Trigger.IsUpdate){
            OpportunityLineItemService.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
}