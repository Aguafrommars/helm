# TheIdServer Redis Chart
## Configuration

The following table lists configurable parameters of the Redis chart and their default values.

|Parameter|Description|Default|Remarks|
|-|-|-|-|
|`replicaCount`|Number of pod to create when autoscalling is disabled|`1`||
|`image.repository`|Image repository|`redis`||
|`image.pullPolicy`|Image pull policy|`IfNotPresent`||
|`image.tag`|Image tag|`6.0.8-alpine`|Possible values listed [here](https://hub.docker.com/_/redis?tab=tags)|
|`imagePullSecrets`|Docker registry secret names as an array|`[]`||
|`nameOverride`|String to partially override fullname template with a string (will prepend the release name)|`nil`||
|`fullnameOverride`|String to fully override fullname template with a string|`nil`||
|`serviceAccount.create`|Specifies whether a ServiceAccount should be created|`true`||
|`serviceAccount.annotations`|Annotations to add to the service account|`{}`||
|`serviceAccount.name`|The name of the service account to use|`nil`|If not set and create is true, a name is generated using the fullname template|
|`podAnnotations`|Annotations to add to pods|`{}`||
|`podSecurityContext`|Pods security context|`{}`||
|`securityContext`|Containers security context|`ClusterIP`||
|`service.port`|Redis service ports|`6379`||
|`resources`|CPU/Memory resource requests/limits|`{}`||
|`autoscaling.enabled`|Specifies whether to enable autoscaling|`false`||
|`autoscaling.minReplicas`|Minimum number of workers when using autoscaling|`1`||
|`autoscaling.maxReplicas`|Maximum number of workers when using autoscaling|`100`||
|`autoscaling.targetCPUUtilizationPercentage`|Target CPU utilisation percentage to scale|`80`||
|`nodeSelector`|Node selector labels for pod assignment|`{}`||
|`tolerations`|Toleration for pod assignment|`{}`||