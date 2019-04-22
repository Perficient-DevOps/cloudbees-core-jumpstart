# Create namespace, ConfigMaps, and RBAC resources
kubectl apply -f ./mandatory.yaml

# Create the LoadBalancer service which routes to ingress-nginx pods
kubectl apply -f ./cloud-generic.yaml
