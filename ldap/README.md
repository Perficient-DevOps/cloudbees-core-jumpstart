## PRFT DevOps LDAP

1. Export your LDAP administrator password to a shell environment variable and create a Kubernetes secret:
   ```
   export LDAP_ADMIN_PASS='my-password'
   kubectl create secret generic ldap-admin-password --from-literal=password="$LDAP_ADMIN_PASS"
   ```

2. Create the Kubernetes resources for `openldap-server`:
   
   `kubectl apply -f ldap/ldap.yaml`

   To interact with the LDAP server via `ldapsearch` or `ldapmodify` commands, you must execute commands inside the `openldap-server` container of the `openldap-server` pod:
   ```
   export OPENLDAP_POD=$(kubectl get pod -l app=openldap-server -o jsonpath="{.items[0].metadata.name}")
   kubectl exec $OPENLDAP_POD -- ldapsearch -x -H ldap://openldap-server-svc:3893 -b dc=perficientdevops,dc=com -D "cn=admin,dc=perficientdevops,dc=com" -w $LDAP_ADMIN_PASS
   ```

   **The LDAP server is not exposed outside the cluster and is not accessible outside its namespace.**

3. Create users or groups using the LDIF in `/ldap`. Watch out for duplicates!
   ```
   kubectl cp ldap/prft-devops.ldif $OPENLDAP_POD:/tmp
   kubectl exec $OPENLDAP_POD -- ldapadd -x -H ldap:/// -D "cn=admin,dc=perficientdevops,dc=com" -w $LDAP_ADMIN_PASS -f /tmp/prft-devops.ldif
   ```

   If creating individual users, set the password for new users:

   `kubectl exec $OPENLDAP_POD -- ldappasswd -H ldap://openldap-server-svc:3893 -s welcome123 -D "cn=admin,dc=perficientdevops,dc=com" -w $LDAP_ADMIN_PASS -x "cn=Joe Blow,ou=Developers,dc=perficientdevops,dc=com"`

4. Dump the contents of the LDAP server for periodic backups:

   `kubectl exec $OPENLDAP_POD -- ldapsearch -x -H ldap://openldap-server-svc:3893 -LLL -D "cn=admin,dc=perficientdevops,dc=com" -b "dc=perficientdevops,dc=com" -w $LDAP_ADMIN_PASS > ldap/prft-devops.ldif`

### Try/Repeat Cycle
```
kubectl delete deploy openldap-server
kubectl apply -f ldap/ldap.yaml
export OPENLDAP_POD=$(kubectl get pod -l app=openldap-server -o jsonpath="{.items[0].metadata.name}")
kubectl cp ldap/prft-devops.ldif $OPENLDAP_POD:/tmp
kubectl exec $OPENLDAP_POD -- ldapadd -x -H ldap:/// -D "cn=admin,dc=perficientdevops,dc=com" -w $LDAP_ADMIN_PASS -f /tmp/prft-devops.ldif
```
