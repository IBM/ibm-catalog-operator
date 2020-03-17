# Multicloud Catalog

IBM Private Cloud Catalog allows install/upgrade/management of IBM and non IBM workloads in Kubernestes Cluster.  It provides configuration and management of Helm Repositories in IBM Private Cloud Cluster.

## Introduction

This chart bootstraps ICP Catalog demonset on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Chart Details

This Chart installs catalog-ui demonset in kubernetes cluster.  This chart deploys the following Kubernetes resources within the cluster:
- 1 Daemonset for the `catalog-ui` application
- 3 Ingress endpoints
- 1 Service

## Prerequisites
The `catalog-ui` chart requires the following resources to be running along with their dependencies:

- auth-idp
- Chart needs platform-oidc-credentials secret to be created with keys as clientIdSecretKey, clientSecretSecretKey
- icp-management-ingress
- helm and kubectl must be installed and configured on your system
- helm-api, helm-rudder and tiller.  Catalog-ui pod use helm-api as a backend.

### PodSecurityPolicy Requirements

This chart requires a PodSecurityPolicy to be bound to the target namespace prior to installation. Choose either a predefined [`ibm-anyuid-psp`](https://ibm.biz/cpkspec-psp) PodSecurityPolicy or have your cluster administrator create a custom PodSecurityPolicy for you:
* Custom PodSecurityPolicy definition:

```
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: ibm-ace-psp
spec:
  allowPrivilegeEscalation: true
  fsGroup:
    rule: RunAsAny
  requiredDropCapabilities:
  - MKNOD
  allowedCapabilities:
  - SETPCAP
  - AUDIT_WRITE
  - CHOWN
  - NET_RAW
  - DAC_OVERRIDE
  - FOWNER
  - FSETID
  - KILL
  - SETUID
  - SETGID
  - NET_BIND_SERVICE
  - SYS_CHROOT
  - SETFCAP
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - configMap
  - emptyDir
  - projected
  - secret
  - persistentVolumeClaim
  forbiddenSysctls:
  - '*'
```
* Custom ClusterRole for the custom PodSecurityPolicy:

    ```yaml
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: ibm-aspera-hsts-prod-psp-clusterrole
    rules:
    - apiGroups: ['policy']
      resources: ['podsecuritypolicies']
      verbs:     ['use']
      resourceNames:
      - ibm-aspera-hsts-prod-psp
    ```

### Red Hat OpenShift SecurityContextConstraints Requirements

This chart requires a SecurityContextConstraints to be bound to the target namespace prior to installation. To meet this requirement there may be cluster-scoped, as well as namespace-scoped, pre- and post-actions that need to occur.

The predefined SecurityContextConstraints [`ibm-anyuid-scc`](https://ibm.biz/cpkspec-scc) has been verified for this chart. If your target namespace is not bound to this SecurityContextConstraints resource you can bind it with the following command:

`oc adm policy add-scc-to-group ibm-anyuid-scc system:serviceaccounts:<namespace>` For example, for release into the `default` namespace:
``` 
oc adm policy add-scc-to-group ibm-anyuid-scc system:serviceaccounts:default
```
* From the user interface, you can copy and paste the following snippets to enable the custom SecurityContextConstraints
  * Custom SecurityContextConstraints definition:

    ```yaml
    apiVersion: security.openshift.io/v1
    kind: SecurityContextConstraints
    metadata:
      name: ibm-aspera-hsts-prod-scc
    readOnlyRootFilesystem: false
    allowedCapabilities: []
    allowHostPorts: true
    seLinuxContext:
      type: RunAsAny
    supplementalGroups:
      type: MustRunAs
      ranges:
      - max: 65535
        min: 1
    runAsUser:
      type: MustRunAsNonRoot
    fsGroup:
      type: MustRunAs
      ranges:
      - max: 65535
        min: 1
    volumes:
    - configMap
    - downwardAPI
    - emptyDir
    - persistentVolumeClaim
    - projected
    - secret
    ```

## Resources Required

This chart uses the following resources as a default:
- 300m CPU Core
- 256Mi Memory

## Installing the Chart

To install the chart with the name `catalog-ui`

```
helm install --name catalog-ui icp-catalog-ui
```

## Uninstalling the Chart

To uninstall/delete the release named `catalog-ui`:
```
helm delete catalog-ui --purge
```
The command removes all the Kubernetes components associated with the chart.

## Configuration

The following table lists the configurable parameters of the `catalog-ui` chart and their default values.

| Parameter                        | Description                                     | Default                                                    |
| -------------------------------- | ----------------------------------------------- | ---------------------------------------------------------- |
| `image.repository`               | Image full name including repository            | `quay.io/opencloudio/icp-catalog-ui`                                                |
| `image.tag`                      | Image tag                                       | `3.1.1`                                                        |
| `image.pullPolicy`               | Image pull policy                               | `IfNotPresent`                                             |
| `envVar.cfcRouterUrl`                   | IBM Cloud Private management ingress URL       | `https://icp-management-ingress:443`                                  |
| `envVar.identityProviderUrl`            | Identity Provider URL as provided by the `auth-idp` service                    | `https://icp-management-ingress:443/idprovider`     |
| `envVar.authServiceUrl`            | Auth Service URL as provided by the `auth-idp` service                      | `https://icp-management-ingress:443/idprovider`     |
| `envVar.secretRefName`            | Name of OIDC secret                        | `platform-oidc-credentials`     |
| `resources.limits.cpu`          | Kubernetes CPU limit for the Queue Manager container | `300mi`                                                   |
| `resources.limits.memory`       | Kubernetes memory limit for the Queue Manager container | `256Mi`                                              |
| `resources.requests.cpu`        | Kubernetes CPU request for the Queue Manager container | `300mi`                                                 |
| `resources.requests.memory`     | Kubernetes memory request for the Queue Manager container | `256Mi`                                            |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart.

> **Tip**: You can use the default [values.yaml](./values.yaml)


## Limitations

ICP Catalog UI have following dependencies : 
- Helm API : Multicloud Catalog needs version 2 of Multicloud Helm API 

## Useful Links

[Learn more about Managing charts and apps](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.0/app_center/app_center.html)


_Copyright IBM Corporation 2018. All Rights Reserved._

