k8s-iptables
============

### Description

`k8s-iptables` is a docker container with a bash script to manipulate iptables `raw` table.
The idea is to apply your iptables restrictionis before docker/k8s/weave rules.

`k8s-iptables` bash script is pretty simple:

1. On the startup it applies the policy
2. Sleeps for the **CHECK_INTERVAL** seconds
3. Checks if the policy still exists
4. Reapplies it, if it does not
5. Go to 2.

### Configuration

Configuration is done via environment variables:

* **POLICY_FILE**  
Path to the iptables policy file, should be in `iptables-save` format and
contain only rules for the `raw` table. If the policy contains errors and
`k8s-iptables` fails to apply it, it will then apply default all-allowing 
policy instead. If **POLICY_FILE*** is not provided, the default all-allowing policy
will be applied.

* **POLICY_REVISION**  
Before applying a policy, `k8s-iptables` checks if the policy
already exists. This is done by grapping the keyword, defined
by **POLICY_REVISION** variable, in `iptables-save -t raw` output.
If the keyword is found, `k8s-iptables` assumes that the policy exists.
Don't forget to put the same keyword (for example, as a first comment only rule in the policy) in your policy definition, i.e. in your **POLICY_FILE***.

* **DEFAULT_POLICY_COMMENT**  
When applying default policy, `k8s-iptables` creates an allow-all policy, with a single comment only
rule. If **POLICY_FILE** is not provided, then **POLICY_REVISION** value will be used as the contents of the comment.
Otherwise, **DEFAULT_POLICY_COMMENT** value defines the contents of this comment. Default is **k8s-iptables-default-policy**.

* **CHECK_INTERVAL**  
Time in seconds between checks if the policy exists.
`k8s-iptables` applies the policy, then sleeps for the 
**CHECK_INTERVAl**, checks if the policy is still there (grapping for **POLICY_REVISION** in `iptables-save` output), and 
reapplies it if it is not. Default is **60**.

* **MAX_TRIES**  
Each time when `k8s-iptables` tries to apply the provided policy and fails, it increases an internal counter `failedAttempts`.
When `k8s-iptables`, on a new loop iteration, sees that the policy does not exist, it will try to reapply it 
only if `failedAttempts < MAX_TRIES`. 

