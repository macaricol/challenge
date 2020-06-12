# challenge

Contains code for Opportunity Product trigger and code for integration with backend service.

Opportunity Product code was required in order to fully automate the addition services to an Opportunity while adding Opportunity Products.

	Services are added by checking the "Add Subscription Service" on Opportunity Product.
	Services are removed by unchecking the "Add Subscription Service" on Opportunity Product.
	Changing the quantity on an Opportunity Product will also change the quantity in the respective service.
	When an Opportunity Product is deleted, the related Opportunity Product for service is also deleted.

	Creation, deletion or edition of Opportunity Products associated with a service product is not allowed in order to keep data consistency.



