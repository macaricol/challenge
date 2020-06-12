public class HttpRestCallout {

    public static HTTPResponse makeCallout(String endpoint, Map<String,String> headers, String method, String body){
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        if(body != null)
        	req.setBody(body);
        
        for(String key: headers.keySet())
            req.setHeader(key, headers.get(key));
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() != 200) {
            System.debug('An unexpected error has occurred: ' +
                res.getStatusCode() + ' ' + res.getStatus());
        }
        
        return res;
        
    }
    
}