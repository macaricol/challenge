public class VehicleInformationProcessor {
    
    /*
	* Updates existing asset having the same vehice identification number(VIN) with additional vehicle information
	* Since the JSON response is formated to provide a single asset per request, I would assume that the correlation-id would
	* be the variable to be used to request data from other assets. In that scenario the correlation id would be set as an argument on
	* this funtion. For the purpose of this exercise this will be called from a quick action on the asset record.
	*/
    @AuraEnabled
    public static void updateVehicleInformation(){
        
        VehicleInformationWrapper viWrapper = new VehicleInformationWrapper();
        
        String jsonResp = getVehicleInformationFromRemote();
        
        viWrapper = (VehicleInformationWrapper)JSON.deserialize(jsonResp, VehicleInformationWrapper.class);
        
        List<Asset> asset = [SELECT Id, VIN__c FROM Asset WHERE VIN__c =:viWrapper.vin LIMIT 1];

        system.assert(asset.size()==1, 'No Asset found for the provided VIN!');
        
        Asset theAsset = asset[0];
        
        theAsset.VIN__c = viWrapper.vin;
        theAsset.Vehicle_Number__c = viWrapper.vehicleNum;
        theAsset.Vehicle_Registration_Number__c = viWrapper.vehicleRegNum;
        theAsset.Registration_Country__c = viWrapper.regNumCountryKey;
        theAsset.Manufacturer__c = viWrapper.manufacturer;
        theAsset.Model_Range__c = viWrapper.modelRange;
        theAsset.Vehicle_Type__c = viWrapper.vehicleType;
        theAsset.Type_Variant__c = viWrapper.typeVariant;
        theAsset.InstallDate = parseDate(viWrapper.deliveryExWorkDate);
        theAsset.First_Registration_Date__c = parseDate(viWrapper.firstRegDate);
        
        update theAsset;
        
    }
    
    /*
	* Retrieves vehicle information from endpoint
	* @return JSON response with vehicle data
	*/
    public static String getVehicleInformationFromRemote(){
        
        List<Endpoints__mdt> endpoints = [SELECT DeveloperName, Client_Id__c, Client_Secret__c, Correlation_id__c ,Endpoint_URL__c 
                                          FROM Endpoints__mdt WHERE DeveloperName = 'JOINTHEDIGITALHUB'];
        
        system.assert(endpoints.size() == 1, 'Failed to obtain the endpoint information.');
        
        Endpoints__mdt digitalhubEndpoint = endpoints[0];
        
        String endpointURL = digitalhubEndpoint.Endpoint_URL__c;
        String clientId = digitalhubEndpoint.Client_Id__c;
        String clientSecret = digitalhubEndpoint.Client_Secret__c;
        String correlationId = digitalhubEndpoint.Correlation_id__c;
        Map<String,String> headers = new Map<String,String>{'Client-id' => clientId, 'Client-secret' => clientSecret, 'correlation-id' => correlationId};
        
        HTTPResponse resp = HttpRestCallout.makeCallout(endpointURL, headers, 'GET', null);
        
        //force an exception when request fails
        system.assert(resp.getStatusCode() == 200, 'Failed to retrieve vehicle data. ' + resp.getStatusCode() + ' ' + resp.getStatus());
            
        return resp.getBody();
        
    }
    
    /*
	* Utility function to parse date in the format yyyymmdd
	* @param dateString string containing the date in raw format.
	* @return parsed date in a Date type.
	*/
    public static Date parseDate(String dateString){
        
        Pattern p = pattern.compile('(\\d{4})(\\d{2})(\\d{2})');
        Matcher m = p.matcher(dateString);
        m.find();
        Integer year = Integer.valueOf(m.group(1)),month = Integer.valueOf(m.group(2)),day = Integer.valueOf(m.group(3));
        Date d = Date.newInstance(year, month, day);
        
        return d;
    }
    
    /*
	* Wrapper to store the vehicle related information that will be retrieved from the remote server
	*/
    class VehicleInformationWrapper{
        
        public String vin;
        public String vehicleNum;
        public String vehicleRegNum;
        public String regNumCountryKey;
        public String manufacturer;
        public String modelRange;
        public String vehicleType;
        public String typeVariant;
        public String deliveryExWorkDate;
        public String firstRegDate;
        
    }
}
