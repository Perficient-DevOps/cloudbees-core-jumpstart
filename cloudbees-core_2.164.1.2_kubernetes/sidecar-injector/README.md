# Using self-signed certificates in CloudBees Core

This optional component of CloudBees Core allows to use self-signed certificates or custom root CA.

# Prerequisites

Kubernetes 1.9 or later, with admission controller `MutatingAdmissionWebhook` enabled.

In order to check whether it is enabled for your cluster, you can run the following command:
                              
```
kubectl api-versions | grep admissionregistration.k8s.io/v1beta1
```

The result should be:

```
admissionregistration.k8s.io/v1beta1
```

# Installation

This procedure requires a context with `cluster-admin` privilege in order to create the `MutatingWebhookConfiguration`.

## Create a certificate bundle

Assuming you are working in the namespace where CloudBees Core is installed,
and the certificate you want to install is named `mycertificate.pem`.

For a self-signed certificate, add the certificate itself.
If the certificate has been issued from a custom root CA, add the root CA itself.

```
kubectl cp cjoc-0:/etc/ssl/certs/ca-certificates.crt .
kubectl cp cjoc-0:/etc/ssl/certs/java/cacerts .
cat mycertificate.pem >> ca-certificates.crt
keytool -import -noprompt -keystore cacerts -file mycertificate.pem -storepass changeit -alias service-mycertificate;
kubectl create configmap --from-file=ca-certificates.crt,cacerts ca-bundles
```

## Setup injector

1. Create a namespace to deploy the sidecar injector

   ```
   kubectl create namespace sidecar-injector
   ```

2. Create a signed cert/key pair and store it in a Kubernetes `secret` that will be consumed by sidecar deployment

   ```
   ./webhook-create-signed-cert.sh \
    --service sidecar-injector-webhook-svc \
    --secret sidecar-injector-webhook-certs \
    --namespace sidecar-injector
   ```

3. Patch the `MutatingWebhookConfiguration` by set `caBundle` with correct value from Kubernetes cluster

   ```
   cat sidecar-injector.yaml | \
       ./webhook-patch-ca-bundle.sh > \
       sidecar-injector-ca-bundle.yaml
   ```

4. Switch to `sidecar-injector` namespace

5. Deploy resources

   ```
   kubectl create -f sidecar-injector-ca-bundle.yaml
   ```

6. Verify everything is running

   The sidecar-inject webhook should be running

   ```
   # kubectl get pods
   NAME                                                  READY     STATUS    RESTARTS   AGE
   sidecar-injector-webhook-deployment-bbb689d69-882dd   1/1       Running   0          5m

   # kubectl get deployment
   NAME                                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
   sidecar-injector-webhook-deployment   1         1         1            1           5m
   ```

## Configure namespace

1. Label the namespace where CloudBees Core is installed with `sidecar-injector=enabled`

   ```
   kubectl label namespace mynamespace sidecar-injector=enabled
   ```

2. Check
   ```
   # kubectl get namespace -L sidecar-injector
   NAME          STATUS    AGE       SIDECAR-INJECTOR
   default       Active    18h
   mynamespace   Active    18h       enabled
   kube-public   Active    18h
   kube-system   Active    18h
   ```

## Verify

1. Deploy an app in Kubernetes cluster, take `sleep` app as an example

   ```
   # cat <<EOF | kubectl create -f -
   apiVersion: extensions/v1beta1
   kind: Deployment
   metadata:
     name: sleep
   spec:
     replicas: 1
     template:
       metadata:
         labels:
           app: sleep
       spec:
         containers:
         - name: sleep
           image: tutum/curl
           command: ["/bin/sleep","infinity"]
   EOF
   ```

2. Verify injection has happened
   ```
   # kubectl get pods -o 'go-template={{range .items}}{{.metadata.name}}{{"\n"}}{{range $key,$value := .metadata.annotations}}* {{$key}}: {{$value}}{{"\n"}}{{end}}{{"\n"}}{{end}}'
   sleep-d5bf9d8c9-bfglq
   * com.cloudbees.sidecar-injector/status: injected
   ```

## Conclusion

You are now all set to use your custom CA. If you restart CJOC and running masters, they will pick up the new certificate bundle.
When scheduling new build agents, they will also pick up the certificate bundle and allow connection to remote endpoints using your certificates.
