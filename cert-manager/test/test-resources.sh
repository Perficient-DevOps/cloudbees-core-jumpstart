# Create the test resources
kubectl apply -f test-resources.yaml

# Check the status of the newly created certificate.
# You may need to wait a few seconds before cert-manager processes the certificate request.
kubectl describe certificate -n cert-manager-test
