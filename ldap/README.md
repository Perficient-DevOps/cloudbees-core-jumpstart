## PRFT DevOps LDAP

1. Create the Kubernetes resources for `openldap-server`:
   ```
   kubectl create secret generic ldap-admin-password --from-literal=password='j0nsn0w'
   kubectl apply -f ldap/ldap.yaml
   kubectl run ldapsearch --image=emeraldsquad/ldapsearch
   ```

   To interact with the LDAP server via `ldapsearch` or `ldapmodify` commands, you must use the `ldapsearch` pod:

   `kubectl exec ldapsearch-69cc844647-4xf98 -- ldapsearch -x -H ldap://openldap-server-svc:3893 -b dc=perficientdevops,dc=com -D "cn=admin,dc=perficientdevops,dc=com" -w j0nsn0w`

   **The LDAP server is not exposed outside the cluster and is not accessible outside its namespace.**

2. Create users or groups using the LDIF templates in `/ldap`:
   ```
   kubectl cp ldap/users.ldif ldapsearch-69cc844647-4xf98:/tmp/

   kubectl exec ldapsearch-69cc844647-4xf98 -- ldapadd -x -H ldap://openldap-server-svc:3893 -D "cn=admin,dc=perficientdevops,dc=com" -w j0nsn0w -f /tmp/users.ldif
   ```

   Set the password for new users:

   `kubectl exec ldapsearch-69cc844647-4xf98 -- ldappasswd -H ldap://openldap-server-svc:3893 -s welcome123 -D "cn=admin,dc=perficientdevops,dc=com" -w j0nsn0w -x "cn=Geoff Rosenthal,ou=Developers,dc=perficientdevops,dc=com"`

3. Dump the contents of the LDAP server in LDIF for periodic backup:
   `kubectl exec ldapsearch-69cc844647-4xf98 -- ldapsearch -x -H ldap://openldap-server-svc:3893 -LLL -D "cn=admin,dc=perficientdevops,dc=com" -b "dc=perficientdevops,dc=com" -w j0nsn0w > ldap/prft-devops.ldif`


