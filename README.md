# CloudBees Core Quickstart
This repo contains scripts, Kubernetes resource defintions, and Kustomize configuration to get started with CloudBees Core.

New CloudBees Core resource definitions from CloudBees can be [downloaded](https://downloads.cloudbees.com/cloudbees-core/cloud/) and extracted to this repo locally, then pushed to the remote. Do not modify the CloudBees Core resource definitons at all! This is what Kustomize is for.

`tar -xvzf cloudbees-core_2.164.2.1_kubernetes.tgz`

## Prerequisites
* A running Kubernetes v1.7+/OpenShift v3.7+ cluster with nodes that have at least 2 CPUs and 4 GBs of memory
* A namespace in the cluster with permissions to create `Role` and `RoleBinding` objects, i.e. `cluster-admin` role (full permissions) in that namespace (and that namespace only). This is only needed during installation, services run with custom RBAC resources.
* A [default `storageclass`](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/) configured. The following should return something:

  `kubectl get sc -o yaml | grep storageclass.beta.kubernetes.io/is-default-class`

* [Kustomize](https://kustomize.io/) installed

## Deploy the NGINX Ingress Controller
See the official [docs](https://kubernetes.github.io/ingress-nginx/deploy/) before jumping in. There are required resource definitions in `mandatory.yaml` and potentially provider-specific steps to follow.

## Setup cert-manager for Let's Encrypt TLS Certificates
Run `./cert-manager/install.sh` to install cert-manager. This creates several Custom Resource Definitions and additional resources:
* CRDs
  * Certificates
  * Challenges
  * ClusterIssuers
  * Issuers
  * Orders

* Deployments
  * cert-manager
  * cert-manager-cainjector
  * cert-manager-webhook

* Service
  * cert-manager-webhook

* Issuers
  * cert-manager-webhook-ca
  * cert-manager-webhook-selfsign

* Certificates
  * cert-manager-webhook-ca
  * cert-manager-webhook-webhook-tls

The [cert-manager webhook](https://docs.cert-manager.io/en/latest/getting-started/webhook.html) provides advanced resource validation ([ValidatingWebhookConfiguration](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)). The webhook allows cert-manager to validate that Issuer, ClusterIssuer, and Certificate resource submissions are syntactically correct, and automatically rejects `create` events when resources are submitted that are invalid. With the webhook disabled, users may be able to submit a resource that renders the controller inoperable, so it is always recommended for use.

We use a `ClusterIssuer` tied to the Let's Encrypt production endpoint for Jenkins.

## Setup YAML
There are a few places where the CloudBees Core resource definitions must be customized:
1. The CJOC ingress resource should be modified to include a proper `<HOSTNAME>`, which is a DNS alias pointing to the external IP of the `ingress-ngninx` load balancer.
```
kubectl get svc/ingress-nginx -n ingress-nginx
```

2. The CJOC ingress resource must also be configured for TLS:
```
    ...
    certmanager.k8s.io/cluster-issuer: "letsencrypt-prod"
    certmanager.k8s.io/acme-challenge-type: http01
spec:
  # SSL offloading at ingress resource level
  tls:
  - hosts:
    - k8s.perficientdevops.com
    secretName: cloudbees-cjoc-tls
    ...
```

3. For external, custom CAs or self-signed certificates, use the sidecar-injector provided by CloudBees or [create a ConfigMap](https://support.cloudbees.com/hc/en-us/articles/360018267271-Deploy-Self-Signed-Certificates-in-Masters-and-Agents) which includes the CA certificate data and JVM trustore, and mount this as a volume in CJOC and Managed Master StatefulSets. Create a patch for the CJOC StatefulSet in `kustomization.yaml`.

## Use Kustomize to Deploy
Ensure the `jenkins` namespace exists:

`kubectl create ns jenkins`

To deploy using Kustomize:

`kustomize build | kubectl apply -f -`

A successful deployment looks like this:
```
serviceaccount/cjoc created
serviceaccount/jenkins created
role.rbac.authorization.k8s.io/master-management created
role.rbac.authorization.k8s.io/pods-all created
rolebinding.rbac.authorization.k8s.io/cjoc created
rolebinding.rbac.authorization.k8s.io/jenkins created
configmap/cjoc-configure-jenkins-groovy created
configmap/jenkins-agent created
service/cjoc created
statefulset.apps/cjoc created
ingress.extensions/cjoc created
```

Check the status of pods in the `jenkins` namespace. There should only be one at this point for the CJOC container. When `STATUS` changes from `ContainerCreating` to `Running`, access the Jenkins web UI at  `http://<HOSTNAME>/cjoc`. :
```
➜  prft-devops-k8s git:(master) ✗ kubectl get pods -w -n jenkins -o wide
NAME     READY   STATUS    RESTARTS   AGE    IP           NODE                       NOMINATED NODE   READINESS GATES
cjoc-0   1/1     Running   0          2m8s   10.244.1.6   aks-agentpool-30924121-1   <none>           <none>
```

Cleanup:

`kustomize build | kubectl delete -f -`
