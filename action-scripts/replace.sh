#!/usr/bin/env bash

LOGFILE="/var/log/stdout"
WORKDIR="/opt/turbonomic/actionscripts"

function _log()
{
    ts="[$(date +%Y-%m-%d" "%H:%M:%S)]"
    echo -e "${ts} - [${VMT_ACTION_INTERNAL}] - [${VMT_TARGET_NAME}] - ${1}" >> $LOGFILE

}

_log "[REPLACE] Action Script executed for action \"${VMT_ACTION_NAME}\"" >> $LOGFILE

_log "Create change request start" >> $LOGFILE

target_node_name=`echo ${VMT_ACTION_NAME}|awk '{print $NF}'`

if [ ${target_node_name} == "cluster1-control-plane" ];then
    aisle_number=1
fi

if [ ${target_node_name} == "cluster2-control-plane" ];then
    aisle_number=2
fi

_log "target_node_name:${target_node_name}" >> $LOGFILE

current_time=`date +%F-%H-%M-%S`

sed "s/TIMESTAMP/${current_time}/g" $WORKDIR/cr-template.yaml  > $WORKDIR/temp-cr
sed "s/AISLE/${aisle_number}/g" $WORKDIR/temp-cr  > $WORKDIR/last-cr.yaml

# Point to the internal API server hostname
APISERVER=https://kubernetes.default.svc

# Path to ServiceAccount token
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

# Read this Pod's namespace
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

# Read the ServiceAccount bearer token
TOKEN=$(cat ${SERVICEACCOUNT}/token)

# Reference the internal certificate authority (CA)
CACERT=${SERVICEACCOUNT}/ca.crt


#curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/apis/turbonomic.io/v1alpha1/namespaces/changereq/changerequests
curl --cacert ${CACERT} -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type:application/yaml" --data-binary @${WORKDIR}/last-cr.yaml ${APISERVER}/apis/turbonomic.io/v1alpha1/namespaces/changereq/changerequests 1>${WORKDIR}/out 2>&1

rm -f  $WORKDIR/temp-cr
rm -f  $WORKDIR/last-cr.yaml
_log "Create change request end" >> $LOGFILE
exit 0
