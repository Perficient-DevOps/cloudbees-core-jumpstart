# https://docs.cert-manager.io/en/latest/getting-started/install.html

# Create a namespace to run cert-manager
kubectl create namespace cert-manager

# Disable resource validation on the cert-manager namespace
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true

# Install the CustomResourceDefinitions and cert-manager itself
kubectl apply -f cert-manager.yaml

# Create the Let's Encrypt ClusterIssuer
kubectl apply -f issuers/prod-cluster-issuer.yaml
