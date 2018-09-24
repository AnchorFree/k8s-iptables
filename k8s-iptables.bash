#!/bin/bash

POLICY_FILE="${POLICY_FILE:-DEFAULT}"
POLICY_REVISION="${POLICY_REVISION:-k8s-iptables-default-rev1}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"
DEFAULT_POLICY_COMMENT="${DEFAULT_POLICY_COMMENT:-k8s-iptables-default-policy}"
MAX_TRIES="${MAX_TRIES:-15}"

failedAttempts=0

applyDefaultPolicy () {

    policyComment="${DEFAULT_POLICY_COMMENT}"
    if [[ ! -f "${POLICY_FILE}" ]]; then
        policyComment="${POLICY_REVISION}"
    fi
    cat <<EOF | iptables-restore -T raw
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -m comment --comment "${policyComment}"
COMMIT
EOF

    echo "$(date +%s): applied default policy"
}

applyPolicy () {

    if [[ -f "${POLICY_FILE}" ]]; then 

            if ! (iptables-restore -T raw < ${POLICY_FILE}); then
                ((failedAttempts++))
                echo "$(date +%s): failed to apply provided policy for the ${failedAttempts} times"
                applyDefaultPolicy
            else
                echo "$(date +%s): applied provided policy"
            fi
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
        if [[ ${failedAttempts} < ${MAX_TRIES} ]]; then
            applyPolicy
        fi
    fi

done
