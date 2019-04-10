# Troubleshooting

To get an overall view of the system run

    kubectl get -a pod,svc,statefulset,ingress,pvc,role,rolebinding

# Pod Errors

Run

    kubectl describe pod the_pod_name

ie.

    kubectl describe pod cjoc-0


| Status | Events | Cause |
|--------|--------|-------|
| `ImagePullBackOff` | | The image you are using can not be found in the Docker registry, or when using a private registry there is no `secret` configured |
| **Node issues** | `No nodes are available that match all of the following predicates` | See below. Get node info with `kubectl describe nodes` |
| `Pending` | `Insufficient memory` | Not enough memory, either increase the nodes or node size in the cluster or reduce the memory requirement of CJOC (yaml file) or Master (under configuration) |
| `Pending` | `Insufficient cpu` | Not enough CPUs, either increase the nodes or node size in the cluster or reduce the CPU requirement of CJOC (yaml file) or Master (under configuration) |
| `Pending` | `NoVolumeZoneConflict` | There are no nodes available in the zone where the persistent volume was created, start more nodes in that zone |
| `Running` but restarting every so often. `describe pod` shows `Last State: Terminated Reason: OOMKilled Exit Code: 137` | | The `Xmx` or `MaxRAM` JVM parameters are too high for the container memory, try increasing memory limit |
| `Unknown` |  | This usually indicates a bad node, if there are several pods in that node in the same state. Check with `kubectl get pods --all-namespaces -o wide | grep "Unknown"`

Once changes are made to the CJOC Pod or StatefulSet, you can trigger a regeneration of the Pod running

    kubectl delete pod cjoc-0

## Agent Pod Errors

| Status | Events | Cause |
|--------|--------|-------|
| `Completed` | | One of the containers in the pod has exited. [Containers must run a long running process](https://github.com/jenkinsci/kubernetes-plugin#constraints), so the container does not exit. If the default entrypoint or command just runs something and exit then it should be overridden with something like `cat` with `ttyEnabled: true`. The master log would eventually show `Total container cap of 10 reached, not provisioning: 10 running or errored in namespace N` |

## Resource usage

Run

    kubectl describe nodes
    
ie.

    kubectl get nodes --no-headers | awk '{print $1}' | xargs -I {} sh -c 'echo {}; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- ; echo'
    ...
    ip-10-0-106-107.us-west-2.compute.internal
      CPU Requests  CPU Limits  Memory Requests  Memory Limits
      2010m (50%)   2 (50%)     3048M (18%)      3048M (18%)   

# Persistent Volume Claim errors

Run

    kubectl describe pvc the_pvc_name

ie.

    kubectl describe pvc jenkins-home-cjoc-0


| Status | Events | Cause |
|--------|--------|-------|
| `Pending` | `no persistent volumes available for this claim and no storage class is set` | There is no default `storageclass`, follow [this instructions to set a default `storageclass`](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/) |

# CJOC Errors

### CJOC requests errors with "No valid crumb was included in the request"

According to [Kubernetes documentation](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-typenodeport)
the origin ips are not preserved when using the `nginx-controller` as `NodePort`.
`nginx-ingress` service should be a `LoadBalancer` with `service.spec.externalTrafficPolicy=Local`

See our [`nginx-controller` service configuration](nginx-ingress.yml) for reference.

# Pods running on each nodes

Run

    kubectl get nodes --no-headers | awk '{print $1}' | xargs -I {} sh -c 'echo {}; kubectl describe node {} | grep -A10000  "Non-terminated Pods" | grep -B10000 "Allocated resources" | grep -v "Allocated resources" -- ; echo'

ie.

    gke-cje-1-default-pool-b56b747c-75c6
    Non-terminated Pods:         (5 in total)
      Namespace                  Name                                               CPU Requests  CPU Limits  Memory Requests  Memory Limits
      ---------                  ----                                               ------------  ----------  ---------------  -------------
      cje                        cjoc-0                                             1 (51%)       1 (51%)     1G (16%)         1G (16%)
      cje                        master-2-0                                         0 (0%)        0 (0%)      2048M (34%)      2048M (34%)
      kube-system                fluentd-gcp-v2.0.10-69g5t                          100m (5%)     0 (0%)      200Mi (3%)       300Mi (5%)
      kube-system                kube-proxy-gke-cje-1-default-pool-b56b747c-75c6    100m (5%)     0 (0%)      0 (0%)           0 (0%)
      kube-system                kubernetes-dashboard-74f855c8c6-lqk5m              50m (2%)      100m (5%)   100Mi (1%)       300Mi (5%)

# Debugging the JVM

Using [arthas](https://alibaba.github.io/arthas/en/).

```
export POD_NAME=cjoc-0
kubectl exec -ti $POD_NAME -- bash -c 'cd /tmp; curl -L https://alibaba.github.io/arthas/install.sh | sh; sed -i s/sanity_check$/#sanity_check/ /tmp/as.sh; /tmp/as.sh --attach-only $(jps | grep "jenkins.war" | cut -f 1 -d " ")'
kubectl port-forward $POD_NAME 3658
```

Then in another console

```
telnet localhost 3658
```

you can start using `dashboard` command to have an overview of what is going on. Please read the tool documentation for full usage.
