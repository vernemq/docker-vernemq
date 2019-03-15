# VerneMQ

[VerneMQ](https://vernemq.com/) is a high-performance, distributed MQTT message broker. It scales
horizontally and vertically on commodity hardware to support a high number of
concurrent publishers and consumers while maintaining low latency and fault
tolerance. VerneMQ is the reliable message hub for your IoT platform or smart
products.

[VerneMQ](https://vernemq.com/) is an Apache2 licensed distributed MQTT broker, developed in Erlang.

## TL;DR;

```console
$ helm install vernemq/vernemq
```

## Introduction

This chart bootstraps a [VerneMQ](https://vernemq.com/) deployment on a [Kubernetes](https://kubernetes.io/) cluster using the [Helm](https://helm.sh/) package manager.

## Prerequisites

- Kubernetes 1.9, of 1.5 with Beta features enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release vernemq/vernemq
```

The command deploys VerneMQ on the Kubernetes cluster in the default configuration. The configuration section lists the parameters that can be configured during installation.

> **Tip**: List all releases using helm list

## Uninstalling the Chart

To uninstall/delete the my-release deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the VerneMQ chart and their default values.

Parameter | Description | Default
--------- | ----------- | -------
`additionalEnv` | additional environment variables | see [values.yaml](values.yaml)
`image.pullPolicy` | container image pull policy | `IfNotPresent`
`image.repository` | container image repository | `erlio/docker-vernemq`
`image.tag` | container image tag | the current versions (e.g. `1.7.1`)
`nodeSelector` | node labels for pod assignment | `{}`
`persistentVolume.accessModes` | data Persistent Volume access modes | `[ReadWriteOnce]`
`persistentVolume.annotations` | annotations for Persistent Volume Claim | `{}`
`persistentVolume.enabled` | if true, create a Persistent Volume Claim | `true`
`persistentVolume.size` | data Persistent Volume size | `5Gi`
`persistentVolume.storageClass` | data Persistent Volume Storage Class | `unset`
`podAntiAffinity` | pod anti affinity, `soft` for trying not to run pods on the same nodes, `hard` to force kubernetes not to run 2 pods on the same node | `soft`
`rbac.create` | if true, create & use RBAC resources | `true`
`rbac.serviceAccount.create` | if true, create a serviceAccount | `true`
`rbac.serviceAccount.name` | name of the service account to use or create | `{{ include "vernemq.fullname" . }}`
`replicaCount` | desired number of nodes | `1`
`resources` | resource requests and limits (YAML) | `{}`
`securityContext` | securityContext for containers in pod | `{}`
`service.annotations` | service annotations | `{}`
`service.clusterIP` | custom cluster IP when `service.type` is `ClusterIP` | `none`
`service.externalIPs` | optional service external IPs | `none`
`service.labels` | additional service labels | `{}`
`service.loadBalancerIP` | optional load balancer IP when `service.type` is `LoadBalancer` | `none`
`service.loadBalancerSourceRanges` | optional load balancer source ranges when `service.type` is `LoadBalancer` | `none`
`service.mqtt.enabled` | whether to expose MQTT port | `true`
`service.mqtt.nodePort` | the MQTT port exposed by the node when `service.type` is `NodePort` | `1883`
`service.mqtt.port` | the MQTT port exposed by the service | `1883`
`service.mqtts.enabled` | whether to expose MQTTS port | `false`
`service.mqtts.nodePort` | the MQTTS port exposed by the node when `service.type` is `NodePort` | `8883`
`service.mqtts.port` | the MQTTS port exposed by the service | `8883`
`service.type` | type of service to create | `ClusterIP`
`service.ws.enabled` | whether to expose WebSocket port | `false`
`service.ws.nodePort` | the WebSocket port exposed by the node when `service.type` is `NodePort` | `8080`
`service.ws.port` | the WebSocket port exposed by the service | `8080`
`statefulset.annotations` | additional annotations to the StatefulSet | `{}`
`statefulset.labels` | additional labels on the StatefulSet | `{}`
`statefulset.podAnnotations` | additional pod annotations | `{}`
`statefulset.podManagementPolicy` | start and stop pods in Parallel or OrderedReady (one-by-one.)  **Note** - Cannot change after first release. | `OrderedReady`
`statefulset.terminationGracePeriodSeconds` | configure how much time VerneMQ takes to move offline queues to other nodes | `60`
`statefulset.updateStrategy` | Statefulset updateStrategy | `RollingUpdate`

Specify each parameter using the `--set key=value[,key=value]` argument to helm install. For example,

```console
$ helm install vernemq/vernemq --name my-release --set replicaCount=3
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install vernemq/vernemq --name my-release -f values.yaml
```

> **Tip**: You can use the default [values.yaml](values.yaml)

### RBAC Configuration

Roles and RoleBindings resources will be created automatically.

To manually setup RBAC you need to set the parameter `rbac.create=false` and specify the service account to be used for each service by setting the parameters: `serviceAccounts.create` to `false` and `serviceAccounts.name` to the name of a pre-existing service account.
