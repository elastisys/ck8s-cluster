# Guidelines for sharing customer credentials

The basic idea is to not send any critical credentials that can be used longterm. 
The preffered way of this is to give access to certain OIDC users and let OIDC
handle the authentication. For some applications were this is not possible create
a user with a temporary password and instruct the customer to change this the first
time they use them.

This way instead of relying on the sharing method to be 100% secured we make sure
the content cant be used to access any services.

## Cluster access
This is handled by a combination of kubelogin and dex. Dex handles the OIDC login and
kubelogin makes sure you can use it to a specific role (see [customer-credentials.md](./customer-access.md)).

## Grafana access
Grafana also has OIDC support. The customer will be asked for a user which will be admin on the cutomer
side. This address can then be added ass a admin user in the grafana gui. This way the default admin
credentials never have to be shared to customers.

## Kibana access
Kibana does not have OIDC support(in the free version). This can be handled by creating a user for the
customer admin with a initial password (this can be done through kibana gui). Then the customer should
be instructed to change this password upon initial login. 

OBS! The default admin for kibana can not be removed and is not by default supported to change
passwords. Make sure these credentials are not shared or leaked. A workaround to enable password change
is presented in https://github.com/elastic/cloud-on-k8s/issues/967

## Postgresql access
Postgres access can be handled in a similar way to kibana. Cluster admin creates user for customer admin. 
Then the customer admin is instructed to change the password on first use. 

An alteranive solution is to enable oauth on postgres as zalando explains in 
[salando p54](https://www.postgresql.eu/events/fosdem2018/sessions/session/1735/slides/59/FOSDEM%202018_%20Blue_Elephant_On_Demand.pdf)


## Sharing credentials and enpoints
An idea for customers is to build a webpage behind the oauth-proxy with a summary of all
the endpoints and initial credentials (this would work like the dashboard). Then the credentials
is protected by oauth but still does not have any credentials which will be usable if breached.

For more immediate customers (Tempus) the initial credentials can be shared with e.g. slack, 
even if this method is not that secure.