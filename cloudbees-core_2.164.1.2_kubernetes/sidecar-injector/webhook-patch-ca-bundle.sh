#!/bin/bash -e
set -o pipefail

ROOT=$(cd $(dirname $0)/../../; pwd)

export CA_BUNDLE=$(kubectl get configmap -n kube-system extension-apiserver-authentication -o=jsonpath='{.data.client-ca-file}' | base64 | tr -d '\n')
[ -z ${CA_BUNDLE} ] && export CA_BUNDLE=$(kubectl run sidecar-injector-get-ca --restart=Never -i --tty --image=centos -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 | tr -d '\n')
kubectl delete pod sidecar-injector-get-ca > /dev/null 2>&1 || true

if command -v envsubst >/dev/null 2>&1; then
    envsubst
else
    sed -e "s|\${CA_BUNDLE}|${CA_BUNDLE}|g"
fi
