public class OpportunityLineItemService {
    
    //flag to bypass block on edit and delete on service line items
    public static Boolean allowModifyServiceLineItems = false;
    
    public static void handleBeforeInsert(List<OpportunityLineItem> newList){
        
        blockServiceLineItemInsertEditDelete(newList);
        
    }
    
    public static void handleBeforeUpdate(List<OpportunityLineItem> newList){
        
        blockServiceLineItemInsertEditDelete(newList);
        
    }
    
    public static void handleBeforeDelete(Map<Id,OpportunityLineItem> oldMap){
        
        blockServiceLineItemInsertEditDelete(oldMap.values());
        manageServiceOppLineItems(null, oldMap);
        
    }
    
    public static void handleAfterInsert(List<OpportunityLineItem> newList){
        manageServiceOppLineItems(newList, null);
    }
    
    public static void handleAfterUpdate(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap){
        manageServiceOppLineItems(newList, oldMap);
    }
    
    /*
     * Product line item - opportunity line item connected to a product of record type 'Product'
     * Service line item - opportunity line item connected to a product of record type 'Product Service'
     * 
     * This function takes care of the automation behind the creation, edition and deletion of Service line items.
     * Service line items will be automatically created when the flag add subscription service is checked on the 
     * product line item (and the product has the service product lookup populated).
     * Removing the flag add subscription service or deleting the product line item will automatically delete the related service line items.
     * Updating the quantity on the product line item will automatically update the quantity in the related service line item.
     * 
     */
    public static void manageServiceOppLineItems(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap){
        
        List<OpportunityLineItem> olisToProcess = newList != null ? newList : oldMap.values();
        
        List<OpportunityLineItem> olisAddService = new List<OpportunityLineItem>();
        Set<Id> olisRemoveService = new Set<Id>();
        List<OpportunityLineItem> olisUpdateService = new List<OpportunityLineItem>();
        
        for(OpportunityLineItem oli: olisToProcess){
            //on insert --> create service line items if Add Subscription Service is checked
            if(oldMap == null && oli.Add_Subscription_Service__c && oli.Product_Service_Id__c != null){
                olisAddService.add(oli);
            }
            //Add subscription service changed to true --> need to create service olis
            else if(oldMap != null && !oldMap.get(oli.Id).Add_Subscription_Service__c && oli.Add_Subscription_Service__c && oli.Product_Service_Id__c != null){
                olisAddService.add(oli);
            }
            //Add subscription service changed to false --> need to remove service olis
            else if(oldMap != null && oldMap.get(oli.Id).Add_Subscription_Service__c && !oli.Add_Subscription_Service__c){
                olisRemoveService.add(oli.Id);
            }
            //the quantity changed and add subscription service is true --> need to update related service olis
            else if(oldMap != null && oldMap.get(oli.Id).Quantity != oli.Quantity && oli.Add_Subscription_Service__c){
                olisUpdateService.add(oli);
            }
            //parent OLI was deleted --> need to remove related service OLI
            else if(newList == null && oli.Parent_OLI_Id__c == null){
                olisRemoveService.add(oli.Id);
            }
        }
        
        if(!olisAddService.isEmpty())
        	createServiceOLIs(olisAddService);
        if(!olisRemoveService.isEmpty())
        	removeServiceOLIs(olisRemoveService);
        if(!olisUpdateService.isEmpty())
        	updateServiceOLIs(olisUpdateService);
        
    }
    
    public static void createServiceOLIs(List<OpportunityLineItem> olisToProcess){
        
        List<OpportunityLineItem> serviceOLIsToInsert = new List<OpportunityLineItem>();
        
        //retrieve product services pricebookentryIds
        Map<Id, Id> pricebookEntriesPerService = new Map<Id, Id>();
        Set<Id> productServiceIds = new Set<Id>();
        for(OpportunityLineItem oli: olisToProcess){
            productServiceIds.add(oli.Product_Service_Id__c);
        }
        
        //Assumption made here: only working with Standard Pricebook. would need rework if multiple pricebooks were used
        List<PriceBookEntry> pbeList = new List<PriceBookEntry>([SELECT Id, Product2Id FROM PriceBookEntry WHERE Product2Id IN:productServiceIds]);
        
        for(PriceBookEntry pbe: pbeList){
            if(!pricebookEntriesPerService.containsKey(pbe.Product2Id))
                pricebookEntriesPerService.put(pbe.Product2Id, pbe.Id);
        }
        
        for(OpportunityLineItem oli: olisToProcess){
            if(oli.Add_Subscription_Service__c && oli.Product_Service_Id__c != null){
                OpportunityLineItem serviceOLI = new OpportunityLineItem();
                serviceOLI.OpportunityId = oli.OpportunityId;
                serviceOLI.Parent_OLI_Id__c = oli.Id;
                serviceOLI.Product2Id = oli.Product_Service_Id__c;
                serviceOLI.Quantity = oli.Quantity;
                serviceOLI.PriceBookEntryId = pricebookEntriesPerService.get(oli.Product_Service_Id__c);
                //TODO: replace with dynamic value stored in a product service field
                serviceOLI.UnitPrice = oli.UnitPrice * 0.1;
                serviceOLI.Description = 'Service for ' + oli.Product_Name__c;
                
                serviceOLIsToInsert.add(serviceOLI);
            }
        }
        
        if(!serviceOLIsToInsert.isEmpty())
            allowModifyServiceLineItems = true;
            insert serviceOLIsToInsert;
        	allowModifyServiceLineItems = false;
        
    }
    
    public static void removeServiceOLIs(Set<Id> olisToProcess){
        
        List<OpportunityLineItem> serviceOLIsToDelete = new List<OpportunityLineItem>([SELECT Id FROM OpportunityLineItem WHERE Parent_OLI_Id__c IN:olisToProcess]);
        
        if(!serviceOLIsToDelete.isEmpty()){
            allowModifyServiceLineItems = true;
            delete serviceOLIsToDelete;
            allowModifyServiceLineItems = false;
        }
    }
    
    public static void updateServiceOLIs(List<OpportunityLineItem> olisToProcess){
        
        Set<Id> olisToProcessIds = (new Map<Id,SObject>(olisToProcess)).keySet();
        Map<Id, OpportunityLineItem> parentOLIsMap = new Map<Id, OpportunityLineItem>(olisToProcess);
        
        List<OpportunityLineItem> serviceOLIsToUpdate = new List<OpportunityLineItem>([SELECT Id, Quantity, Parent_OLI_Id__c FROM OpportunityLineItem WHERE Parent_OLI_Id__c IN: olisToProcessIds]);
        
        for(OpportunityLineItem oli: serviceOLIsToUpdate){
            oli.Quantity = parentOLIsMap.get(oli.Parent_OLI_Id__c).Quantity;
        }
        
        if(!serviceOLIsToUpdate.isEmpty()){
            allowModifyServiceLineItems = true;
            update serviceOLIsToUpdate;
            allowModifyServiceLineItems = false;
        }
        
    }
    
    /*
     * Prevent users from editing or deleting service line items manually in order to keep data consistency
     * between product line items and their respective service line items.
     */
    public static void blockServiceLineItemInsertEditDelete(List<OpportunityLineItem> olisToProcess){
        
        for(OpportunityLineItem oli: olisToProcess){
            if(oli.Is_Service_Product__c && !allowModifyServiceLineItems){
                if(Trigger.isInsert){
                	oli.addError(Label.Block_insert_service_line_item);
                }
                if(Trigger.isUpdate){
                	oli.addError(Label.Block_edit_service_line_item);
                }
                else if(Trigger.isDelete){
                    oli.addError(Label.Block_delete_service_line_item);
                }
            }
        }
        
    }
    
}