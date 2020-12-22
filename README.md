# nexus3-community-install-cli
Deploy Sonatype Nexus 3.x Repository on OpenShift using the Nexus Community Operator.

## Setup Procedure

Ensure that the Nexus operator exists in the channel catalog.
```shell script
oc get packagemanifests -n openshift-marketplace | grep nexus-operator
```

Query the available channels for Nexus operator (nexus-operator-m88i Community Operators)
```shell script
oc get packagemanifest -o jsonpath='{range .status.channels[*]}{.name}{"\n"}{end}{"\n"}' -n openshift-marketplace nexus-operator-m88i
```

Discover whether the operator can be installed cluster-wide or in a single namespace
```shell script
oc get packagemanifest -o jsonpath='{range .status.channels[*]}{.name}{" => cluster-wide: "}{.currentCSVDesc.installModes[?(@.type=="AllNamespaces")].supported}{"\n"}{end}{"\n"}' -n openshift-marketplace nexus-operator-m88i
```

Check the CSV information for additional details
```shell script
oc describe packagemanifests/nexus-operator-m88i -n openshift-marketplace | grep -A36 Channels
```

## Install Nexus operator cluster-wide in openshift-operators namespace using the CLI

- Create a Subscription object YAML file to subscribe a namespace to the Nexus Community Operator.

**Example Subscription**

[nexus-sub.yaml](nexus-sub.yaml)

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nexus-operator-m88i
  namespace: openshift-operators
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: nexus-operator-m88i
  source: community-operators-index
  sourceNamespace: openshift-marketplace
```
```shell script
oc apply -f nexus-sub.yaml
```

### Deploy CheCluster CR example
You can get details about the Custom Resource Definitions (CRD) supported by the operator or retrieve some sample CRDs.

- Get the CSV name of the installed Nexus operator
```shell script
oc get csv #get operator name
CSV=$(oc get csv -o name |grep nexus-operator) #store the CSV data
```
- Query the ClusterServiceVersion (CSV)
```shell script
oc get $CSV -o json |jq -r '.spec.customresourcedefinitions.owned[]|.name' #query the CRDs enabled by the operator
oc get $CSV -o json |jq -r '.metadata.annotations["alm-examples"]' #retrieve the sample CRDs if you need some help to get started
```

- Create a Project

[nexus-namespace.yaml](nexus-namespace.yaml)
```yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    openshift.io/description: "Single source of truth for all of your components, binaries, and build artifacts."
    openshift.io/display-name: "Sonatype Nexus 3 Repository"
  name: nexus-repository
```
```shell script
oc apply -f nexus-namespace.yaml
```
or
```shell script
oc new-project nexus-repository
```
- It's necessary to configure a Security Context Constraints (SCC) resource.
This is necessary because the Nexus image requires its container to be ran as UID 200. 
The use of the restricted default SCC in Openshift results in a failure when starting the pods.
```shell script
oc apply -f scc-volatile.yaml -n nexus-repository
```
- Once the SCC has been created, run:
```shell script
oc adm policy add-scc-to-user allow-nexus-userid-200 -z nexus3
```

- Crate a Nexus Repository instance using the provided sample CRD
```shell script
oc get $CSV -o json |jq -r '.metadata.annotations["alm-examples"]' |jq '.[0]' |oc apply -n nexus-repository -f -
```
or using the example [nexus-cr.yaml](nexus-cr.yaml) for more examples check [nexus-operator git project](https://github.com/m88i/nexus-operator/tree/main/examples)
```yaml
apiVersion: apps.m88i.io/v1alpha1
kind: Nexus
metadata:
  name: nexus3
spec:
  # Number of Nexus pod replicas (can't be increased after creation)
  replicas: 1
  # Here you can specify the image version to fulfill your needs. Defaults to docker.io/sonatype/nexus3:latest if useRedHatImage is set to false
  #image: "docker.io/sonatype/nexus3:latest"
  # let's use the RedHat image since we have access to Red Hat Catalog
  useRedHatImage: true
  # Set the resources requests and limits for Nexus pods. See: https://help.sonatype.com/repomanager3/system-requirements
  resources:
    limits:
      cpu: "2"
      memory: "2Gi"
    requests:
      cpu: "1"
      memory: "2Gi"
  # Data persistence details
  persistence:
    # Should we persist Nexus data? Volatile only!
    persistent: false
  networking:
    # let the operator expose the Nexus server for you (the method will be the one that fits better for your cluster)
    expose: true
```
```shell script
oc apply -f nexus-cr.yaml -n nexus-repository
```

### Access Nexus GUI
```shell script
oc get routes -n nexus-repository
```
You should see 1 route:
- nexus3 — for connecting to the Nexus Repository Console

connect to the route named **nexus3** using your browser
using credentials admin/admin123

---
The installation process is based on documentation from [github.com/m88i/nexus-operator](https://github.com/m88i/nexus-operator#openshift)