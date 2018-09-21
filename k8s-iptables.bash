#!/bin/bash

POLICY_FILE="${POLICY_FILE:-DEFAULT}"
POLICY_REVISION="${POLICY_REVISION:-k8s-iptables-default-rev1}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"

applyDefaultPolicy () {

    echo "applying default policy"
    cat <<EOF | iptables-restore -T raw
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -m comment --comment "${POLICY_REVISION}"
COMMIT
EOF

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
        applyPolicy
    fi

done
