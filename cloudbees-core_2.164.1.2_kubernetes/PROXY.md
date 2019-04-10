How to work with CloudBees Core behind a http/https proxy
====

Jenkins proxy configuration
-----

The following system properties can be added to the java startup of Jenkins.
* http.proxyHost
* http.proxyPort
* https.proxyHost
* https.proxyPort
* http.nonProxyHosts

Please refer to the [Oracle documentation](https://docs.oracle.com/javase/8/docs/api/java/net/doc-files/net-properties.html) for the full syntax and meaning of these system properties. 

These should be honored by any http library used across Jenkins.

Configuring update center access
----
The Jenkins update center has its own configuration panel to provide proxy configuration.
It provides more straightforward way to configure proxy, but it may not be used by all the plugins.

Configuring agents using Kubernetes plugin
----
When declaring a _Pod Template_ or a _Container Template_ through the Kubernetes plugin, environment variables such as `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` can be added to allow using proxy using `libcurl`-based programs.

The same system properties as for Jenkins instances can be provided through the `JAVA_OPTS` environment variable.
The content of this environment variable is [automatically appended](https://github.com/jenkinsci/docker-jnlp-slave/blob/master/jenkins-slave#L93) to the java command line used to run the jenkins agent process, provided the default docker image is used.
If using a custom docker image, the system properties can be declared directly in the corresponding launch script.
