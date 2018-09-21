#!/bin/bash

POLICY_FILE="${POLICY_FILE:-DEFAULT}"
POLICY_REVISION="${POLICY_REVISION:-k8s-iptables-default-rev1}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"
DEFAULT_POLICY_COMMENT="${DEFAULT_POLICY_COMMENT:-k8s-iptables-default-policy}"
MAX_TRIES="${MAX_TRIES:-15}"

defaultPolicyApplied=0

applyDefaultPolicy () {

    cat <<EOF | iptables-restore -T raw
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -m comment --comment "${DEFAULT_POLICY_COMMENT}"
COMMIT
EOF
    ((defaultPolicyApplied++))
    echo "applied default policy: ${defaultPolicyApplied}"
}

applyPolicy () {

    if [[ -f "${POLICY_FILE}" ]]; then 
            echo "applying provided policy"
            iptables-restore -T raw < ${POLICY_FILE} || applyDefaultPolicy
            return
    fi
    applyDefaultPolicy

}

policyExists () {
    
    if (iptables-save -t raw | grep "${POLICY_REVISION}" &>/dev/null); then
        return 0
    fi
    return 1

}

applyPolicy

while :; do
    
    
    sleep ${CHECK_INTERVAL}
    if ! policyExists; then 
        if [[ ${defaultPolicyApplied} < ${MAX_TRIES} ]]; then
            applyPolicy
        fi
    fi

done
