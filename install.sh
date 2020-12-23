#!/bin/bash

#Make sure you're connected to your OpenShift cluster with admin user before running this script

echo "Creating Nexus Project"
oc apply -f nexus-namespace.yaml
echo "Nexus Project created!"
echo " "
echo "Deploying Nexus CR"
oc apply -f deployment/nexus.yaml -n nexus-repository
echo "Nexus CR created!"
echo " "

#echo "Creating Nexus Subscription"
#oc apply -f nexus-sub.yaml
#NEXUS_POD="$(oc get pods -o name -n openshift-operators | grep nexus)" \
#oc -n openshift-operators wait --for=condition=Ready ${NEXUS_POD}
#echo "Nexus Subscription created!"
#echo " "
#echo "Creating Nexus Project"
#oc apply -f nexus-namespace.yaml
#echo "Nexus Project created!"
#echo " "
#echo "Configure Nexus"
#oc apply -f scc-volatile.yaml
#oc adm policy add-scc-to-user allow-nexus-userid-200 -z nexus3 -n nexus-repository
#echo "Configure Nexus Done!"
#echo " "
#echo "Deploying Nexus CR"
#oc apply -f nexus-cr.yaml -n nexus-repository
#echo "Nexus CR created!"
#echo " "

#echo "Searching for available routes"
#oc get routes -n nexus
#echo "connect to the route named nexus using your browser \
#and login using admin/admin123"