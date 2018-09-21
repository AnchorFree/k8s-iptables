k8s-iptables
============

### Description

k8s-iptables is a docker container to manipulate iptables `raw` table.
The idea is to apply your iptables restrictionis before docker/k8s/weave rules.

### Configuration

Configuration is done via environment variables:

* *POLICY_FILE*  
Path to the iptables policy file, should be in `iptables-save` format and
contain only rules for the `raw` table. If the policy contains errors and
k8s-iptables fails to apply it, it will then apply default restrictive 
policy instead.

* *POLICY_REVISION*  
Before applying a policy, k8s-iptables checks if the policy
already exists. This is done by grapping the keyword, defined
by *POLICY_REVISION* variable, in `iptables-save -t raw` output.
If the keyword is found, k8s-iptables won't be reapplying the policy.
Don't forget to put the same keyword in your policy definition.

* *CHECK_INTERVAL*  
Time in seconds between checks if the policy exists.
k8s-iptables applies the policy, then sleeps for the 
CHECK_INTERVAl, checks if the policy is still there, and 
reapplies it if it is not.


