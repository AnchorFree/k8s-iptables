#!/bin/bash

POLICY_FILE="${POLICY_FILE:-DEFAULT}"
POLICY_REVISION="${POLICY_REVISION:-k8s-iptables-default-rev1}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"
DEFAULT_POLICY_MODE="${DEFAULT_POLICY_MODE:-DROP}"
DEFAULT_POLICY_COMMENT="${DEFAULT_POLICY_COMMENT:-k8s-iptables-default-policy}"
MAX_TRIES="${MAX_TRIES:-0}"

failedAttempts=0

applyDefaultPolicy () {

    policyComment="${DEFAULT_POLICY_COMMENT}"
    if [[ ! -f "${POLICY_FILE}" ]]; then
        policyComment="${POLICY_REVISION}"
   fi

    if [[ "${DEFAULT_POLICY_MODE}" != "DROP" ]]; then

    cat <<EOF | iptables-restore -T raw
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -m comment --comment "${policyComment}"
COMMIT
EOF

    else 

    cat <<EOF | iptables-restore -T raw
*raw
:PREROUTING DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -m comment --comment "${policyComment}"
-A PREROUTING -p tcp -s 127.0.0.0/8 -j ACCEPT
-A PREROUTING -p tcp -d 127.0.0.0/8 -j ACCEPT
-A PREROUTING -p tcp -s 10.0.0.0/8 -j ACCEPT
-A PREROUTING -p tcp -d 10.0.0.0/8 -j ACCEPT
-A PREROUTING -p tcp -s 172.16.0.0/12 -j ACCEPT
-A PREROUTING -p tcp -d 172.16.0.0/12 -j ACCEPT
-A PREROUTING -p tcp -s 192.168.0.0/16 -j ACCEPT
-A PREROUTING -p tcp -d 192.168.0.0/16 -j ACCEPT
-A PREROUTING -p tcp --dport 22 -j ACCEPT
EOF

    fi

    echo "$(date +%s): applied default ${DEFAULT_POLICY_MODE} policy"
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
        if [[ ${MAX_TRIES} == 0 ]]; then
            applyPolicy
        else
            if [[ ${failedAttempts} < ${MAX_TRIES} ]]; then
                applyPolicy
            fi
        fi
    fi

done
