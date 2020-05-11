# IBM Catalog UI Operator

> **Important:** Do not install this operator directly. Only install this operator using the IBM Common Services Operator. For more information about installing this operator and other Common Services operators, see [Installer documentation](http://ibm.biz/cpcs_opinstall). If you are using this operator as part of an IBM Cloud Pak, see the documentation for that IBM Cloud Pak to learn more about how to install and use the operator service. For more information about IBM Cloud Paks, see [IBM Cloud Paks that use Common Services](http://ibm.biz/cpcs_cloudpaks).

Operator used to manager IBM Catalog UI service. The Catalag UI service provides an user interface for Helm charts management.

## Supported platforms

Red Hat OpenShift Container Platform 4.3 or newer installed on one of the following platforms:

- Linux x86_64
- Linux on Power (ppc64le)
- Linux on IBM Z and LinuxONE

## Operator versions

- 3.5.0
- 3.6.0

## Prerequisites

Before you install this operator, you need to first install the operator dependencies and prerequisites:

- For the list of operator dependencies, see the IBM Knowledge Center [Common Services dependencies documentation](http://ibm.biz/cpcs_opdependencies).

- For the list of prerequisites for installing the operator, see the IBM Knowledge Center [Preparing to install services documentation](http://ibm.biz/cpcs_opinstprereq).

## Documentation

To install the operator with the IBM Common Services Operator follow the the installation and configuration instructions within the IBM Knowledge Center.

- If you are using the operator as part of an IBM Cloud Pak, see the documentation for that IBM Cloud Pak. For a list of IBM Cloud Paks, see [IBM Cloud Paks that use Common Services](http://ibm.biz/cpcs_cloudpaks).
- If you are using the operator with an IBM Containerized Software, see the IBM Cloud Platform Common Services Knowledge Center [Installer documentation](http://ibm.biz/cpcs_opinstall).

## SecurityContextConstraints Requirements

The Catalog UI service supports running with the OpenShift Container Platform 4.3 default restricted Security Context Constraints (SCCs).

For more information about the OpenShift Container Platform Security Context Constraints, see [Managing Security Context Constraints](https://docs.openshift.com/container-platform/4.3/authentication/managing-security-context-constraints.html).

## Developer guide

Information about building and testing the operator.

### Quick start guide

Use the following quick start commands for building and testing the operator:

Cloning the operator repository
```
# git clone git@github.com:IBM/ibm-catalog-ui-operator.git
# cd ibm-catalog-ui-operator
```

Building the operator image
```
# make build
```

Installing the operator 
```
# make install
```

Uninstalling the operator
```
# make uninstall
```

### Debugging guide

Use the following commands to debug the operator:

Check the Cluster Service Version (CSV) installation status
```
# oc get csv
# oc describe csv ibm-catalog-ui-operator.v3.6.0
```

Check the custom resource status
```
# oc describe cataloguis catalog-ui
# oc get cataloguis catalog-ui -o yaml
```

Check the operator status and log
```
# oc describe po -l name=ibm-catalog-ui-operator
# oc logs -f $(oc get po -l name=ibm-catalog-ui-operator -o name)
```

### End-to-End testing

For more instructions on how to run end-to-end testing with the Operand Deployment Lifecycle Manager, see [ODLM guide](https://github.com/IBM/operand-deployment-lifecycle-manager/blob/master/docs/install/common-service-integration.md#end-to-end-test).