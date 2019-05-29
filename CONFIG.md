## Best Practice Configuration Steps for Jenkins
#### LDAP with RBAC
1. Browse to `Manage Jenkins -> Configure Global Security` within CJOC
2. Check the `Enable Security` box and select `LDAP` as the Security Realm
3. Specify LDAP details and bind credentials. For example:
   ```
   Server: openldap-server-svc:3893
   root DN: dc=perficientdevops,dc=com
   User search filter: uid={0}
   Display Name LDAP attribute: displayname
   Email Address LDAP attribute: mail
   ```
4. Select `Role-based matrix authorization strategy` as the Authorization realm
5. For first-time use, select `Typical initial setup` in the `Import strategy` drop-down

#### Pod Templates
Pod templates may be created at the CJOC-level or Master-level, depending on how you wish to propogate the template (across all Masters or just specific Masters). By default, a single pod template is defined which contains the JNLP agent. This template is also configured as the `Defaults Provider Template` meaning the template will be used as a parent to all other pod templates.

To create additional pod templates:
1. Configure the `kubernetes shared cloud` configuration within CJOC (switch to the `All` view), or browse to `Manage Jenkins -> Kubernetes Pod Templates` within a Master
2. Click `Add Pod Template` at the bottom of the page
3. Specify a name and label for the new template
4. Specify containers, volumes, and other configurations for the template
