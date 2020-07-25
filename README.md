# Выполнено ДЗ №12
# Kubernetes Hashicorp Vault

 - [x] Основное ДЗ

## В процессе сделано:

**Создан StorageClass для CSI Host Path Driver**

Working directory: kubernetes-storage/hw

Скачен репозиторий 
```bash
git clone git@github.com:kubernetes-csi/csi-driver-host-path.git
```

Установлены VolumeSnapshot CRDs и snapshot controller
```
SNAPSHOTTER_VERSION=v2.0.1

kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml 
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml  
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
```

Выполнена, собственно, установка драйвера
```bash
deploy/kubernetes-1.18/deploy.sh 
```

Check pods
```bash
>>> kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
csi-hostpath-attacher-0      1/1     Running   0          3m27s
csi-hostpath-provisioner-0   1/1     Running   0          3m21s
csi-hostpath-resizer-0       1/1     Running   0          3m19s
csi-hostpath-snapshotter-0   1/1     Running   0          3m18s
csi-hostpath-socat-0         1/1     Running   0          3m16s
csi-hostpathplugin-0         3/3     Running   0          3m23s
```

Check storageclass
```bash
>>> kubectl get sc                   
NAME              PROVISIONER           RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-hostpath-sc   hostpath.csi.k8s.io   Delete          Immediate           true                   33m
```

Deploy application
```bash
for i in csi-storageclass.yaml csi-pvc.yaml csi-app.yaml; do kubectl apply -f $i; done
```
Check pv
```bash
>>> kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS      REASON   AGE
pvc-f1c42761-ba10-4133-94a6-b0b329360991   1Gi        RWO            Delete           Bound    default/storage-pvc   csi-hostpath-sc            12s

```

Check pvc
```bash
>>> kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
storage-pvc   Bound    pvc-f1c42761-ba10-4133-94a6-b0b329360991   1Gi        RWO            csi-hostpath-sc   60s
```

Inspect application pod
```bash
>>> kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
storage-pvc   Bound    pvc-f1c42761-ba10-4133-94a6-b0b329360991   1Gi        RWO            csi-hostpath-sc   60s

>>> kubectl describe pods/storage-pod
Name:         storage-pod
Namespace:    default
Priority:     0
Node:         sb-k8s-node03/10.20.0.15
Start Time:   Sat, 25 Jul 2020 09:56:26 +0300
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"name":"storage-pod","namespace":"default"},"spec":{"containers":[{"command":...
Status:       Running
IP:           10.233.110.36
Containers:
  my-frontend:
    Container ID:  docker://08238e4ccb2fd09ae163679cef2da92bf6e29580f8347f374aa971cbf4705541
    Image:         busybox
    Image ID:      docker-pullable://busybox@sha256:9ddee63a712cea977267342e8750ecbc60d3aab25f04ceacfa795e6fce341793
    Port:          <none>
    Host Port:     <none>
    Command:
      sleep
      1000000
    State:          Running
      Started:      Sat, 25 Jul 2020 09:56:37 +0300
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /data from my-csi-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-jprmq (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  my-csi-volume:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  storage-pvc
    ReadOnly:   false
  default-token-jprmq:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-jprmq
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason                  Age        From                     Message
  ----    ------                  ----       ----                     -------
  Normal  Scheduled               <unknown>  default-scheduler        Successfully assigned default/storage-pod to sb-k8s-node03
  Normal  SuccessfulAttachVolume  2m19s      attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-f1c42761-ba10-4133-94a6-b0b329360991"
  Normal  Pulling                 2m9s       kubelet, sb-k8s-node03   Pulling image "busybox"
  Normal  Pulled                  2m7s       kubelet, sb-k8s-node03   Successfully pulled image "busybox"
  Normal  Created                 2m7s       kubelet, sb-k8s-node03   Created container my-frontend
  Normal  Started                 2m7s       kubelet, sb-k8s-node03   Started container my-frontend
```

Looking for
```bash
...
    Mounts:
      /data from my-csi-volume (rw)
...
Volumes:
  my-csi-volume:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  storage-pvc
    ReadOnly:   false
...
Events:
  Type    Reason                  Age        From                     Message
  ----    ------                  ----       ----                     -------
  Normal  SuccessfulAttachVolume  2m19s      attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-f1c42761-ba10-4133-94a6-b0b329360991"
...
```

Additional check
```bash
>>> kubectl describe volumeattachment
Name:         csi-bd7d992031cdf140ef1f322e5e4c0de064041d7b36cc807a1c944c5ad7b9e03c
Namespace:    
Labels:       <none>
Annotations:  <none>
API Version:  storage.k8s.io/v1
Kind:         VolumeAttachment
Metadata:
  Creation Timestamp:  2020-07-25T06:56:25Z
  Managed Fields:
    API Version:  storage.k8s.io/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        f:attached:
    Manager:      csi-attacher
    Operation:    Update
    Time:         2020-07-25T06:56:25Z
    API Version:  storage.k8s.io/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:spec:
        f:attacher:
        f:nodeName:
        f:source:
          f:persistentVolumeName:
    Manager:         kube-controller-manager
    Operation:       Update
    Time:            2020-07-25T06:56:25Z
  Resource Version:  12487809
  Self Link:         /apis/storage.k8s.io/v1/volumeattachments/csi-bd7d992031cdf140ef1f322e5e4c0de064041d7b36cc807a1c944c5ad7b9e03c
  UID:               c40612ea-3a8c-40cc-828f-6fce516112c4
Spec:
  Attacher:   hostpath.csi.k8s.io
  Node Name:  sb-k8s-node03
  Source:
    Persistent Volume Name:  pvc-f1c42761-ba10-4133-94a6-b0b329360991
Status:
  Attached:  true
Events:      <none>
```

**Snapshot**

Create file
```bash
>>> kubectl exec storage-pod -- touch /data/test.txt

>>> kubectl exec storage-pod -- ls -lah /data       
total 0      
drwxr-xr-x    2 root     root          22 Jul 25 07:50 .
drwxr-xr-x    1 root     root          29 Jul 25 06:56 ..
-rw-r--r--    1 root     root           0 Jul 25 07:50 test.txt
```

Create snapshot
```bash
>>> kubectl apply -f csi-snapshot-v1beta1.yaml  
volumesnapshot.snapshot.storage.k8s.io/storage-snapshot created
```

Check
```bash
>>> kubectl get volumesnapshot     
NAME               AGE
storage-snapshot   72s
```

```bash
>>> kubectl get volumesnapshotcontent
NAME                                               AGE
snapcontent-8c25adc0-2797-4142-b2bc-ec4b62a88b09   118s
```

```bash
>>> kubectl describe volumesnapshot
Name:         storage-snapshot
Namespace:    default
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"snapshot.storage.k8s.io/v1beta1","kind":"VolumeSnapshot","metadata":{"annotations":{},"name":"storage-snapshot","namespace"...
API Version:  snapshot.storage.k8s.io/v1beta1
Kind:         VolumeSnapshot
Metadata:
  Creation Timestamp:  2020-07-25T07:55:47Z
  Finalizers:
    snapshot.storage.kubernetes.io/volumesnapshot-as-source-protection
    snapshot.storage.kubernetes.io/volumesnapshot-bound-protection
  Generation:  1
  Managed Fields:
    API Version:  snapshot.storage.k8s.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        f:creationTime:
        f:readyToUse:
        f:restoreSize:
    Manager:         snapshot-controller
    Operation:       Update
    Time:            2020-07-25T07:56:12Z
  Resource Version:  12500869
  Self Link:         /apis/snapshot.storage.k8s.io/v1beta1/namespaces/default/volumesnapshots/storage-snapshot
  UID:               8c25adc0-2797-4142-b2bc-ec4b62a88b09
Spec:
  Source:
    Persistent Volume Claim Name:  storage-pvc
  Volume Snapshot Class Name:      csi-hostpath-snapclass
Status:
  Bound Volume Snapshot Content Name:  snapcontent-8c25adc0-2797-4142-b2bc-ec4b62a88b09
  Creation Time:                       2020-07-25T07:56:12Z
  Ready To Use:                        true
  Restore Size:                        1Gi
Events:                                <none>
```

```bash
>>> kubectl describe volumesnapshotcontent
Name:         snapcontent-8c25adc0-2797-4142-b2bc-ec4b62a88b09
Namespace:    
Labels:       <none>
Annotations:  <none>
API Version:  snapshot.storage.k8s.io/v1beta1
Kind:         VolumeSnapshotContent
Metadata:
  Creation Timestamp:  2020-07-25T07:55:48Z
  Finalizers:
    snapshot.storage.kubernetes.io/volumesnapshotcontent-bound-protection
  Generation:  1
  Managed Fields:
    API Version:  snapshot.storage.k8s.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:finalizers:
          .:
          v:"snapshot.storage.kubernetes.io/volumesnapshotcontent-bound-protection":
    Manager:      snapshot-controller
    Operation:    Update
    Time:         2020-07-25T07:55:48Z
    API Version:  snapshot.storage.k8s.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        .:
        f:creationTime:
        f:readyToUse:
        f:restoreSize:
        f:snapshotHandle:
    Manager:         csi-snapshotter
    Operation:       Update
    Time:            2020-07-25T07:56:12Z
  Resource Version:  12500868
  Self Link:         /apis/snapshot.storage.k8s.io/v1beta1/volumesnapshotcontents/snapcontent-8c25adc0-2797-4142-b2bc-ec4b62a88b09
  UID:               c93d0268-045a-4847-b516-6659f3c81ae9
Spec:
  Deletion Policy:  Delete
  Driver:           hostpath.csi.k8s.io
  Source:
    Volume Handle:             f517442a-ce43-11ea-87de-920cdd3e65a3
  Volume Snapshot Class Name:  csi-hostpath-snapclass
  Volume Snapshot Ref:
    API Version:       snapshot.storage.k8s.io/v1beta1
    Kind:              VolumeSnapshot
    Name:              storage-snapshot
    Namespace:         default
    Resource Version:  12500768
    UID:               8c25adc0-2797-4142-b2bc-ec4b62a88b09
Status:
  Creation Time:    1595663772762935300
  Ready To Use:     true
  Restore Size:     1073741824
  Snapshot Handle:  4f11df4f-ce4c-11ea-87de-920cdd3e65a3
Events:             <none>
```

Look at snapshot on node
```bash
[root@sb-k8s-node03 ~]# ll /var/lib/csi-hostpath-data/
total 4
-rw-r--r--. 1 root root 121 Jul 25 09:56 4f11df4f-ce4c-11ea-87de-920cdd3e65a3.snap
drwxr-xr-x. 2 root root  22 Jul 25 09:50 f517442a-ce43-11ea-87de-920cdd3e65a3
[root@sb-k8s-node03 ~]# ll /var/lib/csi-hostpath-data/f517442a-ce43-11ea-87de-920cdd3e65a3/
total 0
-rw-r--r--. 1 root root 0 Jul 25 09:50 test.txt
```

Delete data
```bash
>>> kubectl delete po storage-pod         
pod "storage-pod" deleted

>>> kubectl delete pvc storage-pvc 
persistentvolumeclaim "storage-pvc" deleted
```

Look at node again
```bash
[root@sb-k8s-node03 ~]# ll /var/lib/csi-hostpath-data/
total 4
-rw-r--r--. 1 root root 121 Jul 25 09:56 4f11df4f-ce4c-11ea-87de-920cdd3e65a3.snap
```

Only snapshot exists

Restore pvc
```bash
>>> kubectl apply -f csi-restore.yaml         
persistentvolumeclaim/storage-pvc created
```

Look at node again
```bash
[root@sb-k8s-node03 ~]# ll /var/lib/csi-hostpath-data/
total 4
-rw-r--r--. 1 root root 121 Jul 25 09:56 4f11df4f-ce4c-11ea-87de-920cdd3e65a3.snap
drwxr-xr-x. 2 root root  22 Jul 25 10:14 d3e99e8a-ce4e-11ea-87de-920cdd3e65a3

[root@sb-k8s-node03 ~]# ll /var/lib/csi-hostpath-data/d3e99e8a-ce4e-11ea-87de-920cdd3e65a3/
total 0
-rw-r--r--. 1 root root 0 Jul 25 09:50 test.txt
```

Restore pod
```bash
>>> kubectl apply -f csi-app.yaml    
pod/storage-pod created
```

Check data in pod
```bash
>>> kubectl exec storage-pod -- ls -lah /data
total 0      
drwxr-xr-x    2 root     root          22 Jul 25 08:14 .
drwxr-xr-x    1 root     root          29 Jul 25 08:16 ..
-rw-r--r--    1 root     root           0 Jul 25 07:50 test.txt
```

# Выполнено ДЗ №11
# Kubernetes GitOps

 - [x] Основное ДЗ
 
**Репозиторий с кодом приложения**
https://gitlab.com/SablinIgor/microservices-demo.git
 
**Подготовка кластра**

В GKE поднят кластер с 4-я узлами (по 2 CPU) и включенным Istio on GKE add-on.

```
>>> kubectl get nodes
NAME                                  STATUS   ROLES    AGE     VERSION
gke-otus-default-pool-e0df26ce-bz9f   Ready    <none>   6m58s   v1.16.9-gke.6
gke-otus-default-pool-e0df26ce-h439   Ready    <none>   6m58s   v1.16.9-gke.6
gke-otus-default-pool-e0df26ce-nbpm   Ready    <none>   6m58s   v1.16.9-gke.6
gke-otus-default-pool-e0df26ce-vf3q   Ready    <none>   6m58s   v1.16.9-gke.6

>>> kubectl get ns
NAME              STATUS   AGE
default           Active   8m23s
istio-system      Active   8m1s
kube-node-lease   Active   8m24s
kube-public       Active   8m24s
kube-system       Active   8m25s
```

**Flux**

Процесс установки Flux-а
```
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml
helm repo add fluxcd https://charts.fluxcd.io
kubectl create namespace flux
helm upgrade --install flux fluxcd/flux -f flux.values.yaml --namespace flux
helm upgrade --install helm-operator fluxcd/helm-operator -f helm-operator.values.yaml --namespace flux
```

На рабочей станции необходимо установить консольную утилиту
```
brew install fluxctl
```

SSH-ключ, при помощи которого Flux будет обращаться к репозиторию с кодом получаем так:
```
fluxctl identity --k8s-fwd-ns flux
```

Лог процесса создания namespace-а
```
ts=2020-06-27T11:20:24.815973455Z caller=loop.go:133 component=sync-loop event=refreshed url=ssh://git@gitlab.com/SablinIgor/microservices-demo.git branch=master HEAD=5e881d641bd5792e614b115af3c02eb16a778c44
ts=2020-06-27T11:20:24.959491754Z caller=sync.go:73 component=daemon info="trying to sync git changes to the cluster" old=587b2c1a6cd9e28d61a44d3a5806d8db8728dc6e new=5e881d641bd5792e614b115af3c02eb16a778c44
ts=2020-06-27T11:20:25.589993123Z caller=sync.go:539 method=Sync cmd=apply args= count=1
ts=2020-06-27T11:20:26.213618928Z caller=sync.go:605 method=Sync cmd="kubectl apply -f -" took=623.550785ms err=null output="namespace/microservices-demo created"
ts=2020-06-27T11:20:26.223370348Z caller=daemon.go:701 component=daemon event="Sync: 5e881d6, <cluster>:namespace/microservices-demo" logupstream=false
```

При обнаружении к docker-registry новой версии сервиса Flux устанавливает его и обновляет информацию в релизном манифесте.
```
Commit c0c956f0  authored 3 minutes ago by Weave Flux's avatar Weave Flux
Auto-release soaron/frontend:0.0.3
[ci skip]
      repository: soaron/frontend
-     tag: 0.0.2
+     tag: 0.0.3
```

Изменение состояния чарта (к примеру мы поменяли имя у Deployment-а) приводит к тому, helm-operator обнаруживает это изменение и вносит соответствующие правки в состояние релиза.
```
ts=2020-06-27T15:05:58.27533823Z caller=helm.go:69 component=helm version=v3 info="Created a new Deployment called \"frontend-hipster\" in microservices-demo\n" targetNamespace=microservices-demo release=frontend
```

Добавляем сайдкар-контейнер istio к нашим сервисам (pod-ы удаляем, чтобы вновь созданные получили сайдкары)
```
>>> cat deploy/namespaces/microservices-demo.yaml 
apiVersion: v1
kind: Namespace
metadata:
  name: microservices-demo
  labels:
    istio-injection: enabled%

kubectl describe pod -l app=frontend -n microservices-demo
```

Доступность приложения по внешнему IP Istio
```
>>> curl http://34.66.132.197/                                                                                                    

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=no">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Online Boutique</title>
...
```

**Flagger**

Собственно установка
```
helm repo add flagger https://flagger.app
kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml
helm upgrade --install flagger flagger/flagger --namespace=istio-system --set crd.create=false --set meshProvider=istio --set metricsServer=http://prometheus.monitoring:9090
```

```
frontend-hipster-5bd4bcb8cc-bvn7f           2/2     Running   0          60s -> image: soaron/frontend:0.0.4
frontend-hipster-primary-79f5d97854-m9ks9   2/2     Running   0          40m -> image: soaron/frontend:0.0.3
```

Однако обновление canary не проходило, так как flagger не получал от Prometheus-а данные о проходящем трафике.

Проверка работоспособности canary шла на другом кластере

**Istio + flux + flugger + canary release**

Репозиторий с кодом: https://gitlab.com/SablinIgor/canary-demo.git

Кубернетес кластер развернут в Yandex.Cloud.

Установка Istio
```
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.6.3
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo
✔ Istio core installed
✔ Istiod installed
✔ Egress gateways installed
✔ Ingress gateways installed
✔ Addons installed
✔ Installation complete
```

Проверим работоспособность Istio на демо приложении Bookinfo
```
kubectl label namespace default istio-injection=enabled
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

>>> kubectl get pods
NAME                              READY   STATUS    RESTARTS   AGE
details-v1-78db589446-8kmxl       2/2     Running   0          73s
productpage-v1-7f4cc988c6-wlpd2   2/2     Running   0          70s
ratings-v1-756b788d54-8mtp6       2/2     Running   0          71s
reviews-v1-849fcdfd8b-jsx5h       2/2     Running   0          71s
reviews-v2-5b6fb6c4fb-xxgt8       1/2     Running   0          71s
reviews-v3-7d94d58566-56glb       2/2     Running   0          71s

>>> kubectl get services
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
details       ClusterIP   10.96.187.33    <none>        9080/TCP   104s
kubernetes    ClusterIP   10.96.128.1     <none>        443/TCP    14h
productpage   ClusterIP   10.96.134.103   <none>        9080/TCP   102s
ratings       ClusterIP   10.96.142.139   <none>        9080/TCP   104s
reviews       ClusterIP   10.96.209.65    <none>        9080/TCP   102s
```

```
>>> kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
```

Установим gateway и virtual service для обращения к приложению внутри кластера:
```
>>> kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
gateway.networking.istio.io/bookinfo-gateway created
virtualservice.networking.istio.io/bookinfo created
```

Проверим все ли корректно.
Если какой-то pod не имеет sidecar-а, то получим соответствующее уведомление.
```
>>> istioctl analyze
Warn [IST0103] (Pod nginx.default) The pod is missing the Istio proxy. This can often be resolved by restarting or redeploying the workload.
Error: Analyzers found issues when analyzing namespace: defaul
```

Если все корректно, то получим следующий результат:
```
>>> istioctl analyze
✔ No validation issues found when analyzing namespace: default.
```

Determining the ingress IP and ports
```
>>> kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                      AGE
istio-ingressgateway   LoadBalancer   10.96.140.145   130.193.51.127   15020:31234/TCP,80:31685/TCP,443:30089/TCP,31400:31365/TCP,15443:30716/TCP   14m
```

Обратимся к приложению:
![ProductPage](https://images-si.s3.eu-west-3.amazonaws.com/product_page.png)


Откроем доступ к Grafana dashboard
```
>>> kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
```

Посмотрим http://localhost:3000/dashboard/db/istio-mesh-dashboard
![Grafana dashboard](https://images-si.s3.eu-west-3.amazonaws.com/grafana_dashboard.png)

Для генерации трафика воспольземся инструментом Yandex.Tank
Use Yandex-tank to produce trafic

Зайдем в контейнер и запустим команду yandex-tank
```
docker run \
    -v $(pwd):/var/loadtest \
    -v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent \
    --net host \
    -it \
    --entrypoint /bin/bash \
    direvius/yandex-tank

[tank]root@linuxkit-025000000001: yandex-tank
```

Example load.yaml
```
phantom:
  address: 130.193.51.127:80
  load_profile:
    load_type: rps
    schedule: line(1, 10, 10m)
  header_http: "1.1"
  headers:
    - "[Host: 130.193.51.127]"
    - "[Connection: close]"
  uris:
    - "/productpage"
console:
  enabled: true # enable console output
telegraf:
  enabled: false # let's disable telegraf monitoring for the first time
```

На дашборде будем наблюдать следующую картину:
![Service under pressure](https://images-si.s3.eu-west-3.amazonaws.com/grafana_dashboard_yandex_tank.png)

Итак, вы убедились в работоспособности Istion (хотя бы в основных моментах), перейдем к проверке деплоя методом Canary.

Для этого сначала установим Flex
```
helm repo add fluxcd https://charts.fluxcd.io
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml
kubectl create namespace flux

helm upgrade -i flux fluxcd/flux \
--set git.url=git@gitlab.com:SablinIgor/canary-demo.git \
--namespace flux

helm upgrade -i helm-operator fluxcd/helm-operator \
--set git.ssh.secretName=flux-git-deploy \
--set helm.versions=v3 \
--namespace flux

fluxctl identity --k8s-fwd-ns flux
```

Полученный при помощи последней команды ключ укажем в профиле пользователя на Gitlab.

В репозитории https://gitlab.com/SablinIgor/canary-demo.git находятся манифесты создания Namespace (microservices-canary-demo) и чарт установки приложения MooIt.

Проверим, что Flex обнаружил эти манифесты
```
>>> kubectl get ns
NAME                        STATUS   AGE
default                     Active   31h
flux                        Active   9h
istio-system                Active   17h
kube-node-lease             Active   31h
kube-public                 Active   31h
kube-system                 Active   31h
microservices-canary-demo   Active   9h

>>> kubectl get helmrelease -n microservices-canary-demo
NAME    RELEASE   PHASE       STATUS     MESSAGE                                                                           AGE
mooit   mooit     Succeeded   deployed   Release was successful for Helm release 'mooit' in 'microservices-canary-demo'.   6m10s
```

Проверим доступность приложения по созданной DNS записи, указывающей на IP istio-ingressgateway - http://mooit.sablin.de/

Далее установим Flagger, при помощи которого и будем выполнять canary-деплой:
```
helm repo add flagger https://flagger.app
kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml

helm upgrade -i flagger flagger/flagger \
--namespace=istio-system \
--set crd.create=false \
--set meshProvider=istio \
--set metricsServer=http://prometheus:9090

helm upgrade -i flagger-grafana flagger/grafana \
--namespace=istio-system \
--set url=http://prometheus.istio-system:9090 \
--set user=admin \
--set password=admin
```

Заодно поставили и графану, содержащую дашборды, удобные для мониторинга трафика.

Убедимся, что у нас все хорошо с canary-ресурсом:
```
>>> kubectl get canary -n microservices-canary-demo
NAME    STATUS      WEIGHT   LASTTRANSITIONTIME
mooit   Succeeded   0        2020-06-28T20:47:31Z
```

Подадим нагрузку на приложение при помощи Yandex.Tank.

И выпустим вторую версию приложения с тэгом 0.0.2
https://gitlab.com/SablinIgor/canary-demo/-/jobs/614778050

В логе Flagger-а мы видим обнаружение новой версии приложения и начало установки canary-деплоя.
![Canary begins](https://images-si.s3.eu-west-3.amazonaws.com/Canary-begins.png)

По прошествии некоторого кол-ва времени в логе видно, что трафик на "канарейке" обрабатывается без ошибок и значит можно переводить основное приложение на новую версию
![Canary ends](https://images-si.s3.eu-west-3.amazonaws.com/Canary-ends.png)

В графане мы можем наблюдать за потоками трафика на основную и canary-версии приложения
![Grafana canary](https://images-si.s3.eu-west-3.amazonaws.com/Grafana-canary.png)

Обратим так же внимание, как Flagger создает дополнительные сервисы (-canary и -primary) для приложения и изменяет VirtualServive
```
>>> kubectl get svc -n microservices-canary-demo
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
mooit           ClusterIP   10.96.194.75    <none>        5000/TCP   9h
mooit-canary    ClusterIP   10.96.242.204   <none>        5000/TCP   7h58m
mooit-primary   ClusterIP   10.96.150.139   <none>        5000/TCP   7h58m

>>> kubectl describe virtualservices.networking.istio.io mooit -n microservices-canary-demo
Name:         mooit
Namespace:    microservices-canary-demo
Labels:       <none>
Annotations:  flagger.kubernetes.io/original-configuration:
                {"hosts":["mooit.sablin.de"],"gateways":["mooit-gateway"],"http":[{"route":[{"destination":{"host":"mooit","port":{"number":5000}},"weight...
              helm.fluxcd.io/antecedent: microservices-canary-demo:helmrelease/mooit
API Version:  networking.istio.io/v1beta1
Kind:         VirtualService
Metadata:
  Creation Timestamp:  2020-06-28T19:45:15Z
  Generation:          6
  Resource Version:    345440
  Self Link:           /apis/networking.istio.io/v1beta1/namespaces/microservices-canary-demo/virtualservices/mooit
  UID:                 5f9df13a-1aaf-49d0-adb0-5facf314ab54
Spec:
  Gateways:
    mooit-gateway
  Hosts:
    mooit.sablin.de
    mooit
  Http:
    Retries:
      Attempts:         3
      Per Try Timeout:  1s
      Retry On:         gateway-error,connect-failure,refused-stream
    Route:
      Destination:
        Host:  mooit-primary
      Weight:  100
      Destination:
        Host:  mooit-canary
      Weight:  0
Events:        <none>
```

Вторую версию приложения можно наблюдать по тому же адресу: http://mooit.sablin.de/

# Выполнено ДЗ №10
# Kubernetes Hashicorp Vault

 - [x] Основное ДЗ

## В процессе сделано:

**Установка консула**
```
git clone https://github.com/hashicorp/consul-helm.git
helm install consul consul-helm
```

**Установка Vault**
```
git clone https://github.com/hashicorp/vault-helm.git
```

```
server:
  standalone:
    enabled: false

  ha:
    enabled: true

ui:
  enabled: true
```

```
helm install vault vault-helm
helm status vault
NAME: vault
LAST DEPLOYED: Thu Jun 11 17:01:44 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get vault

kubectl get po -l app.kubernetes.io/instance=vault
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 0/1     Running   0          3m42s
vault-1                                 0/1     Running   0          3m42s
vault-2                                 0/1     Running   0          3m42s
vault-agent-injector-7898f4df86-stgg4   1/1     Running   0          3m42s
```

Поды с хранилищем не перешли в состоянии Running, так как мы еще не распечатали хранилище.

**Инициализация Vault**
```
kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
Unseal Key 1: 3z376mdMD29cIKst92keOLDA6Bhul3xP65UNoyQjTC8=

Initial Root Token: s.JdZAKyBiGeWcvjKODIf9IbrX
```

--key-shares - отвечает за общее кол-во ключей
--key-threshold - определяет сколько их них необходимо для распечатывания хранилища

Состояние отдельного хранилища можно посмотреть командой
```
kubectl exec -it vault-0 -- vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.4.2
HA Enabled         true
```

**Распечатывание хранилище (используем ключ, полученный ранее - Unseal Key)**
```
kubectl exec -it vault-0 -- vault operator unseal '3z376mdMD29cIKst92keOLDA6Bhul3xP65UNoyQjTC8='
kubectl exec -it vault-1 -- vault operator unseal '3z376mdMD29cIKst92keOLDA6Bhul3xP65UNoyQjTC8='
kubectl exec -it vault-2 -- vault operator unseal '3z376mdMD29cIKst92keOLDA6Bhul3xP65UNoyQjTC8='
```

Обратим внимание, что в статусе хранилища изменилось состояние поля Sealed
```
kubectl exec -it vault-0 -- vault status
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.4.2
Cluster Name    vault-cluster-bea4d1af
Cluster ID      0b4fb285-09ed-3c8c-279e-7996650eee4e
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
```

**Логин в Vault (используем токен, полученный ранее - Initial Root Token)**
```
kubectl exec -it vault-0 -- vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.JdZAKyBiGeWcvjKODIf9IbrX
token_accessor       1yRsgNedcvnzTZQd7BeOTrtX
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

Список текущих авторизации можно посмотеть командой
```
kubectl exec -it vault-0 -- vault auth list
Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_84670741    token based credentials
```

**Работа с секретами**

Подготовим хранение секрета вида key/value c именем otus
```
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
Success! Enabled the kv secrets engine at: otus/
```

Посмотрим на общий список секретов, который у нас есть к этому времени
```
kubectl exec -it vault-0 -- vault secrets list --detailed
Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----
cubbyhole/    cubbyhole    cubbyhole_e409aaf3    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           d4cc849f-ec14-6d64-fa28-4c7fa0d2e7ea
identity/     identity     identity_32ba8418     system         system     false             replicated     false        false                      map[]      identity store                                             465b8010-da2c-a798-ebfa-affa4754dbe3
otus/         kv           kv_b57f45fa           system         system     false             replicated     false        false                      map[]      n/a                                                        59d84039-61a8-6916-baa7-7a3fba829d62
sys/          system       system_813dd989       n/a            n/a        false             replicated     false        false                      map[]      system endpoints used for control, policy and debugging    3eada08b-67fd-1d31-9e5a-2fa4486a4193
```

Добавим пару секретов в otus
```
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus-ro' password='asajkjkahs'
kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus-rw' password='asajkjkahs'
```

Прочитаем значения секретов парой способов
```
kubectl exec -it vault-0 -- vault read otus/otus-ro/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus-ro

kubectl exec -it vault-0 -- vault read otus/otus-rw/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus-rw

kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus-rw

kubectl exec -it vault-0 -- vault kv get otus/otus-ro/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus-ro
```

**Авторизация через K8S**
```
kubectl exec -it vault-0 -- vault auth enable kubernetes
kubectl exec -it vault-0 -- vault auth list
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_da54bbd9    n/a
token/         token         auth_token_84670741         token based credentials
```

Создадим сервисный акаунт для Vault-а
```
kubectl create serviceaccount vault-auth
```

И свяжем его с ролью 
```
tee vault-auth-service-account.yml <<EOF 
---
apiVersion: rbac.authorization.k8s.io/v1beta1 
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io 
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: default
EOF

kubectl apply --filename vault-auth-service-account.yml
```

Подготовим переменные окружения. Они нам пригодятся.
(!)Обратим внимание, что в последнем случае используется gsed - ибо OS X.
```
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}' | gsed 's/\x1b\[[0-9;]*m//g' )
```

Загрузим конфиг авторизации в Vault
```
kubectl exec -it vault-0 -- vault write auth/kubernetes/config \ token_reviewer_jwt="$SA_JWT_TOKEN" \
kubernetes_host="$K8S_HOST" \
kubernetes_ca_cert="$SA_CA_CRT"
Success! Data written to: auth/kubernetes/config
```

Создадим политики, определяющие доступ к секретам
```
tee otus-policy.hcl <<EOF 
path "otus/otus-ro/*" {
    capabilities = ["read", "list"] 
}

path "otus/otus-rw/*" {
    capabilities = ["read", "create", "list"]
} 
EOF
```

Загрузим политики в хранилище и свяжем их с ролью
```
kubectl cp otus-policy.hcl vault-0:./tmp

kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl

kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus bound_service_account_names=vault-auth bound_service_account_namespaces=default policies=otus-policy ttl=24h
```

Убедимся, что авторизация через K8S работает - создадим под, привязанный с сервисной учетке, которую мы создали ранее и посмотрим будет ли у нас доступ к секретам
```
kubectl run tmp --image=alpine:3.7 --restart=Never --rm -i --tty

apk add curl jq
VAULT_ADDR=http://vault:8200
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "test"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')
```

С полученным токеном обратимся к секретам.
Прочитаем их.
```
curl --silent --header "X-Vault-Token:s.UjQxw8hPEIpM18RI3Fg3sD5X" $VAULT_ADDR/v1/otus/otus-ro/config | jq
{
  "request_id": "e0426934-dbc7-2391-7d20-b5c3ab63e1d1",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus-ro"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}

curl --silent --header "X-Vault-Token:s.UjQxw8hPEIpM18RI3Fg3sD5X" $VAULT_ADDR/v1/otus/otus-rw/config | jq
{
  "request_id": "74df9031-2d2c-3966-a7e7-b6ccac769fb0",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus-rw"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

И попробуем изменить, используя otus-rw
```
curl --silent --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.UjQxw8hPEIpM18RI3Fg3sD5X" $VAULT_ADDR/v1/otus/otus-ro/config1

curl --silent --header "X-Vault-Token:s.UjQxw8hPEIpM18RI3Fg3sD5X" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq
{
  "request_id": "6e482c80-a891-4928-c68e-fe1ccd53c2bc",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

А что с config...
```
curl --silent --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.UjQxw8hPEIpM18RI3Fg3sD5X" $VAULT_ADDR/v1/otus/otus-ro/config
{
  "errors": [
    "1 error occurred:\n\t* permission denied\n\n"
  ]
}
```

Изменить не получилось, так как в политиках для otus-rw по позволили только read, list и create.
Т.е. у нас получилось создать новую запись - /otus/otus-rw/config1, но мы не смогли изменить уже существующую - /otus/otus-rw/config
Чтобы мы могли это делать дополним политики правом на update
```
tee otus-policy.hcl <<EOF 
path "otus/otus-ro/*" {
    capabilities = ["read", "list"] 
}

path "otus/otus-rw/*" {
    capabilities = ["read", "create", "update", "list"]
} 
EOF
```

Обновим их
```
kubectl cp otus-policy.hcl vault-0:./tmp
kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
```

И снова попробуем выполнить запись
```
curl --silent --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.UjQxw8hPEIpM18RI3Fg3sD5X" $VAULT_ADDR/v1/otus/otus-rw/config

curl --silent --header "X-Vault-Token:s.UjQxw8hPEIpM18RI3Fg3sD5X" $VAULT_ADDR/v1/otus/otus-rw/config | jq
{
  "request_id": "a02577dd-a254-84f3-b57b-a6afe7bb55e3",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

Теперь запись проходит успешно.

**Передача секретов в приложение**

Используем технологию Agent Sidecar Injector.

Добавим в манифест приложения аннотации
```
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-status: "update"
        vault.hashicorp.com/role: "otus"
        vault.hashicorp.com/agent-inject-secret-index.html: "otus/otus-ro/config"
        vault.hashicorp.com/secret-volume-path: /usr/share/nginx/html
        vault.hashicorp.com/agent-inject-template-index.html: |
          <html>
          <body>
          <p>Some secrets:</p>
          {{- with secret "otus/otus-ro/config" -}}
          <ul>
              <li><pre>username: {{ .Data.username }}</pre></li>
              <li><pre>password: {{ .Data.password }}</pre></li>
          </ul>
          {{- end }}
          </body>
          </html>
```

- vault.hashicorp.com/agent-inject - включает механизм сайдкар-агента Vault-а
- vault.hashicorp.com/agent-inject-status - после успешного внедрения агента у пода появится соотвествующая аннотация со значением injected
- vault.hashicorp.com/role -  роль Vault-а, используемая для auto-auth метода
- vault.hashicorp.com/agent-inject-secret-index.html - файл (index.html), куда будут выложены секреты
- vault.hashicorp.com/secret-volume-path - переопределение пути, по которому будет выложен файл с секретами
- vault.hashicorp.com/agent-inject-template-index.html - шаблон файла с секретами

После применение манифеста, мы видим, что его описание стало сильно разннообразнее по сравнению с тем, что мы указали
```
kubectl get po nginx-5796cd6b48-4rtvj -o yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubernetes.io/limit-ranger: 'LimitRanger plugin set: cpu request for container
      nginx'
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/agent-inject-secret-index.html: otus/otus-ro/config
    vault.hashicorp.com/agent-inject-status: injected
    vault.hashicorp.com/agent-inject-template-index.html: |
      <html>
      <body>
      <p>Some secrets:</p>
      {{- with secret "otus/otus-ro/config" -}}
      <ul>
          <li><pre>username: {{ .Data.username }}</pre></li>
          <li><pre>password: {{ .Data.password }}</pre></li>
      </ul>
      {{- end }}
      </body>
      </html>
    vault.hashicorp.com/role: otus
    vault.hashicorp.com/secret-volume-path: /usr/share/nginx/html
  creationTimestamp: "2020-06-12T20:12:02Z"
  generateName: nginx-5796cd6b48-
  labels:
    app: nginx
    pod-template-hash: 5796cd6b48
  name: nginx-5796cd6b48-4rtvj
  namespace: default
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: nginx-5796cd6b48
    uid: d9ffe4a0-ede8-462b-89ca-f231e8114052
  resourceVersion: "2378861"
  selfLink: /api/v1/namespaces/default/pods/nginx-5796cd6b48-4rtvj
  uid: 6859b6c5-dd92-423d-92c7-c37b86394cf3
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: nginx
    ports:
    - containerPort: 80
      protocol: TCP
    resources:
      requests:
        cpu: 100m
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: vault-auth-token-cv4w9
      readOnly: true
    - mountPath: /usr/share/nginx/html
      name: vault-secrets
  - args:
    - echo ${VAULT_CONFIG?} | base64 -d > /tmp/config.json && vault agent -config=/tmp/config.json
    command:
    - /bin/sh
    - -ec
    env:
    - name: VAULT_LOG_LEVEL
      value: info
    - name: VAULT_CONFIG
      value: eyJhdXRvX2F1dGgiOnsibWV0aG9kIjp7InR5cGUiOiJrdWJlcm5ldGVzIiwibW91bnRfcGF0aCI6ImF1dGgva3ViZXJuZXRlcyIsImNvbmZpZyI6eyJyb2xlIjoib3R1cyJ9fSwic2luayI6W3sidHlwZSI6ImZpbGUiLCJjb25maWciOnsicGF0aCI6Ii9ob21lL3ZhdWx0Ly52YXVsdC10b2tlbiJ9fV19LCJleGl0X2FmdGVyX2F1dGgiOmZhbHNlLCJwaWRfZmlsZSI6Ii9ob21lL3ZhdWx0Ly5waWQiLCJ2YXVsdCI6eyJhZGRyZXNzIjoiaHR0cDovL3ZhdWx0LmRlZmF1bHQuc3ZjOjgyMDAifSwidGVtcGxhdGUiOlt7ImRlc3RpbmF0aW9uIjoiL3Vzci9zaGFyZS9uZ2lueC9odG1sL2luZGV4Lmh0bWwiLCJjb250ZW50cyI6Ilx1MDAzY2h0bWxcdTAwM2Vcblx1MDAzY2JvZHlcdTAwM2Vcblx1MDAzY3BcdTAwM2VTb21lIHNlY3JldHM6XHUwMDNjL3BcdTAwM2Vcbnt7LSB3aXRoIHNlY3JldCBcIm90dXMvb3R1cy1yby9jb25maWdcIiAtfX1cblx1MDAzY3VsXHUwMDNlXG4gICAgXHUwMDNjbGlcdTAwM2VcdTAwM2NwcmVcdTAwM2V1c2VybmFtZToge3sgLkRhdGEudXNlcm5hbWUgfX1cdTAwM2MvcHJlXHUwMDNlXHUwMDNjL2xpXHUwMDNlXG4gICAgXHUwMDNjbGlcdTAwM2VcdTAwM2NwcmVcdTAwM2VwYXNzd29yZDoge3sgLkRhdGEucGFzc3dvcmQgfX1cdTAwM2MvcHJlXHUwMDNlXHUwMDNjL2xpXHUwMDNlXG5cdTAwM2MvdWxcdTAwM2Vcbnt7LSBlbmQgfX1cblx1MDAzYy9ib2R5XHUwMDNlXG5cdTAwM2MvaHRtbFx1MDAzZVxuIiwibGVmdF9kZWxpbWl0ZXIiOiJ7eyIsInJpZ2h0X2RlbGltaXRlciI6In19In1dfQ==
    image: vault:1.4.2
    imagePullPolicy: IfNotPresent
    lifecycle: {}
    name: vault-agent
    resources:
      limits:
        cpu: 500m
        memory: 128Mi
      requests:
        cpu: 250m
        memory: 64Mi
    securityContext:
      runAsGroup: 1000
      runAsNonRoot: true
      runAsUser: 100
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: vault-auth-token-cv4w9
      readOnly: true
    - mountPath: /home/vault
      name: home
    - mountPath: /usr/share/nginx/html
      name: vault-secrets
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  initContainers:
  - args:
    - echo ${VAULT_CONFIG?} | base64 -d > /tmp/config.json && vault agent -config=/tmp/config.json
    command:
    - /bin/sh
    - -ec
    env:
    - name: VAULT_LOG_LEVEL
      value: info
    - name: VAULT_CONFIG
      value: eyJhdXRvX2F1dGgiOnsibWV0aG9kIjp7InR5cGUiOiJrdWJlcm5ldGVzIiwibW91bnRfcGF0aCI6ImF1dGgva3ViZXJuZXRlcyIsImNvbmZpZyI6eyJyb2xlIjoib3R1cyJ9fSwic2luayI6W3sidHlwZSI6ImZpbGUiLCJjb25maWciOnsicGF0aCI6Ii9ob21lL3ZhdWx0Ly52YXVsdC10b2tlbiJ9fV19LCJleGl0X2FmdGVyX2F1dGgiOnRydWUsInBpZF9maWxlIjoiL2hvbWUvdmF1bHQvLnBpZCIsInZhdWx0Ijp7ImFkZHJlc3MiOiJodHRwOi8vdmF1bHQuZGVmYXVsdC5zdmM6ODIwMCJ9LCJ0ZW1wbGF0ZSI6W3siZGVzdGluYXRpb24iOiIvdXNyL3NoYXJlL25naW54L2h0bWwvaW5kZXguaHRtbCIsImNvbnRlbnRzIjoiXHUwMDNjaHRtbFx1MDAzZVxuXHUwMDNjYm9keVx1MDAzZVxuXHUwMDNjcFx1MDAzZVNvbWUgc2VjcmV0czpcdTAwM2MvcFx1MDAzZVxue3stIHdpdGggc2VjcmV0IFwib3R1cy9vdHVzLXJvL2NvbmZpZ1wiIC19fVxuXHUwMDNjdWxcdTAwM2VcbiAgICBcdTAwM2NsaVx1MDAzZVx1MDAzY3ByZVx1MDAzZXVzZXJuYW1lOiB7eyAuRGF0YS51c2VybmFtZSB9fVx1MDAzYy9wcmVcdTAwM2VcdTAwM2MvbGlcdTAwM2VcbiAgICBcdTAwM2NsaVx1MDAzZVx1MDAzY3ByZVx1MDAzZXBhc3N3b3JkOiB7eyAuRGF0YS5wYXNzd29yZCB9fVx1MDAzYy9wcmVcdTAwM2VcdTAwM2MvbGlcdTAwM2Vcblx1MDAzYy91bFx1MDAzZVxue3stIGVuZCB9fVxuXHUwMDNjL2JvZHlcdTAwM2Vcblx1MDAzYy9odG1sXHUwMDNlXG4iLCJsZWZ0X2RlbGltaXRlciI6Int7IiwicmlnaHRfZGVsaW1pdGVyIjoifX0ifV19
    image: vault:1.4.2
    imagePullPolicy: IfNotPresent
    name: vault-agent-init
    resources:
      limits:
        cpu: 500m
        memory: 128Mi
      requests:
        cpu: 250m
        memory: 64Mi
    securityContext:
      runAsGroup: 1000
      runAsNonRoot: true
      runAsUser: 100
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /home/vault
      name: home
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: vault-auth-token-cv4w9
      readOnly: true
    - mountPath: /usr/share/nginx/html
      name: vault-secrets
  nodeName: gke-otus-infra-pool-c1cf63a8-lzk0
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: vault-auth
  serviceAccountName: vault-auth
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: vault-auth-token-cv4w9
    secret:
      defaultMode: 420
      secretName: vault-auth-token-cv4w9
  - emptyDir:
      medium: Memory
    name: home
  - emptyDir:
      medium: Memory
    name: vault-secrets

...

```

Появился инит-контейнер, и контейнер сайдкар-агента. Оба, что характерно, с image: vault:1.4.2

Попробуем обратиться к сервису приложения
```
kubectl get svc -l app=nginx
NAME            TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
service-nginx   NodePort   10.56.2.1    <none>        80:32560/TCP   25m

curl 10.128.0.16:32560
<html>
<body>
<p>Some secrets:</p><ul>
    <li><pre>username: otus-ro</pre></li>
    <li><pre>password: asajkjkahs</pre></li>
</ul>
</body>
</html>
```

Передача секретов в страницу nginx-а прошла успешно.

**Работа с сертификатами**

Для начала включим pki engine, добавим срок действия
```
kubectl exec -it vault-0 -- vault secrets enable pki
Success! Enabled the pki secrets engine at: pki/

kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
Success! Tuned the secrets engine at: pki/

kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="exmaple.ru" ttl=87600h > CA_cert.crt
```

Пропишем урлы для ca и отозванных сертификатов
```
kubectl exec -it vault-0 -- vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"

Success! Data written to: pki/config/urls
```

Cоздадим промежуточный сертификат
```
kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
Success! Enabled the pki secrets engine at: pki_int/

kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
Success! Tuned the secrets engine at: pki_int/

kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
```

Пропишем промежуточный сертификат в vault
```
kubectl cp pki_intermediate.csr vault-0:./tmp/

kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem

kubectl cp intermediate.cert.pem vault-0:./tmp/

kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
Success! Data written to: pki_int/intermediate/set-signed
```

Создадим и отзовем новые сертификаты

Создадим роль для выдачи сертификатов
```
kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"
Success! Data written to: pki_int/roles/example-dot-ru
```

Создадим сертификат
```
kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h"
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUIHJLZ4IDP3NQzGdMBDL+5IIhTacwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDA2MTIyMDU2NDhaFw0yNTA2
MTEyMDU3MThaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOfWBPCdAQ8U
tcfBh37pB5sWCY0whBzoRaiIKFeeqffORZSqUnLFj4eEdr4VrGuJt0UcPw2Lva9+
f6Ni/bDmNVJoyGgwMqGFIZ+EA+Nq7tw9jvdzlibtZll9/TtHxAM72wEEc/W9tXle
znovYJgoxSUznSVJmmR0EvyfJNF1DSczg917ji6miOXxWLDo6QyNxqNKY7oeL4dU
3B5cQ5il9Q3ETWQ/q0zXxlcwJDjqQRDCV0EvF8AAuyIzu6PdFvsHp7NGeAnKuJlT
GSHt9aS8UmPIcu+2rFzxfaxfdN7maDb/1pNOTMUKi+WtiiUEem21RrtaKLa1l2fO
/xeoJzNobr8CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUuv80s8DUixpwYWx39nhmmC9RAW8wHwYDVR0jBBgwFoAU
N9ESWFIWNXC2vjtIB1Dx86HC+vAwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
ppUpbur3F6Lw50dJEfG5KQPo83PiaqEsQV1NpwXA5Qd5V2UthE5wNvkN0dIaDDP5
yVeYflpEsVKXiMW4SZa3iXhQMrO+KKlpWzHLYZlBoNivKB47IQXIe5etl1ePVN9F
ZAAbsfPduk+Md6o7uG74AJ3CvTsVECaDKpmJr5NJRiEinYCFLz1VEAk3J5m1Fhx6
Psfol4mphDM+7pH5VUfaW3PEatjpsa+sSy02hqrou7d2lG3mQ7+Im+mqhUhAkR37
jD6huV+UE8b89r1DFTzyCwICqvs7w6H+7JYQCVUY60n7HMDFtPzfxWsg6E9ndfi8
kISo30bb91+t89xqpmNthw==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZzCCAk+gAwIBAgIUAvt5nJxhICEm0WxqXiJD0CZjnSMwDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIwMDYxMjIxMDI1NloXDTIwMDYxMzIxMDMyNlowHDEaMBgGA1UEAxMRZ2l0
bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDH
PRXcmeOcqD5kTuioFzJk9NutfgA/U+fuZffMaVbny2XpTKCRqFo1uaEWe/tRwq7G
C5S7YzHpHYoCztPQhi/SLrjb+dDFcdVNw0YW6yVTdpX/rZDnSLBgXXE76yHXhN48
vEDspvT6xjhCPdyP44KZrFfLWcnJci1WoJdkFX0S/eUQ/bhaScXU/8+YNAZ/JgDs
kxAhcw3i7IoS6D3/wT64mkTXuwSZBUvrlXmdIy4GnxweYy4HbO/hrdxXcYMGxxZC
KpU6TYeZMbFXYKCVLwLmFRuEV1iusXJKl+w/osy19LOwh0HaZK5NGq5laopnzqOa
G0XkpSJ9zLOGTXNnxD7BAgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUoCmbfImoA2xCLuDh
+KaeEPW2pj8wHwYDVR0jBBgwFoAUuv80s8DUixpwYWx39nhmmC9RAW8wHAYDVR0R
BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBANzwo0+Z
bVaahiFhj4LWk7QDcbVF+I53PPl9XTXWFTYQ+JTXScUVFvD0FF2h8OSLSeRiOGV8
JrrUldfbTktbyyJVtYqrMIcfmiC/GqfpwL1vk9vUsQ2oVqP7uqF46nahrT1IilSH
PsAqNJuLFtzh8NKMUTbgwnbp59O4GT/NeeOEoEvoEs3R2ppJ6rxxurLEtjXUpMJi
t/rRkWYFe8GMOuW7084TwzkgEjDPPNt5G0UbpHg50vnmJPwOi2xFL/wsC2Pqic8d
IXKWddqOeRMritw6e4ED6uZXKQ/fy8r/f4gMdPmvF7rlEJgDF5C4i0eitfouE6WH
FdsTKIs4Ms/LZEM=
-----END CERTIFICATE-----
expiration          1592082206
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUIHJLZ4IDP3NQzGdMBDL+5IIhTacwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDA2MTIyMDU2NDhaFw0yNTA2
MTEyMDU3MThaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOfWBPCdAQ8U
tcfBh37pB5sWCY0whBzoRaiIKFeeqffORZSqUnLFj4eEdr4VrGuJt0UcPw2Lva9+
f6Ni/bDmNVJoyGgwMqGFIZ+EA+Nq7tw9jvdzlibtZll9/TtHxAM72wEEc/W9tXle
znovYJgoxSUznSVJmmR0EvyfJNF1DSczg917ji6miOXxWLDo6QyNxqNKY7oeL4dU
3B5cQ5il9Q3ETWQ/q0zXxlcwJDjqQRDCV0EvF8AAuyIzu6PdFvsHp7NGeAnKuJlT
GSHt9aS8UmPIcu+2rFzxfaxfdN7maDb/1pNOTMUKi+WtiiUEem21RrtaKLa1l2fO
/xeoJzNobr8CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUuv80s8DUixpwYWx39nhmmC9RAW8wHwYDVR0jBBgwFoAU
N9ESWFIWNXC2vjtIB1Dx86HC+vAwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
ppUpbur3F6Lw50dJEfG5KQPo83PiaqEsQV1NpwXA5Qd5V2UthE5wNvkN0dIaDDP5
yVeYflpEsVKXiMW4SZa3iXhQMrO+KKlpWzHLYZlBoNivKB47IQXIe5etl1ePVN9F
ZAAbsfPduk+Md6o7uG74AJ3CvTsVECaDKpmJr5NJRiEinYCFLz1VEAk3J5m1Fhx6
Psfol4mphDM+7pH5VUfaW3PEatjpsa+sSy02hqrou7d2lG3mQ7+Im+mqhUhAkR37
jD6huV+UE8b89r1DFTzyCwICqvs7w6H+7JYQCVUY60n7HMDFtPzfxWsg6E9ndfi8
kISo30bb91+t89xqpmNthw==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAxz0V3JnjnKg+ZE7oqBcyZPTbrX4AP1Pn7mX3zGlW58tl6Uyg
kahaNbmhFnv7UcKuxguUu2Mx6R2KAs7T0IYv0i642/nQxXHVTcNGFuslU3aV/62Q
50iwYF1xO+sh14TePLxA7Kb0+sY4Qj3cj+OCmaxXy1nJyXItVqCXZBV9Ev3lEP24
WknF1P/PmDQGfyYA7JMQIXMN4uyKEug9/8E+uJpE17sEmQVL65V5nSMuBp8cHmMu
B2zv4a3cV3GDBscWQiqVOk2HmTGxV2CglS8C5hUbhFdYrrFySpfsP6LMtfSzsIdB
2mSuTRquZWqKZ86jmhtF5KUifcyzhk1zZ8Q+wQIDAQABAoIBAFmrrIM037RKJIqQ
2TWN+yhk69oRs5rM8L3jNrvRTUPVz3BJBJuJ4c/8U/wCoQITVQXdgHs2EeiRWuQY
okxfmHZIgPrAXK4ApbfyA0GdY5dE8A262FS/6mH0rFoDYZ/WNQ+wyqe4HNohDIED
xpkcFFOFtZ3YM3Fu6ejrLjflU/2PbFHLrijKDqjhM5K2gq8LHHM3SVtliZeqU6Xf
2D0ygDwm8tPtI27bVR9F6hLyLDzvw6c+k2dijDyCKgLF0riIGcqs93Y2ZwblCAtb
vorUceetcSRAeWk9Ha1TUxQVgSg0/+oEvbRuc1Nq4nloyFcOm9XCN4YrL79ZGP1B
bD+TjoECgYEA1oYg4nHl7pXLbLsdOE6Kt9BMC1E5zyeN9+OrpS+0SsMFlm2wDZ4t
Vc0yUxSdeJ3lxzNm+MbQTdhhLg9XcBNeNk+fAxGng2xKQ47/NqrBlOuPvOIktVp/
WjQBgMYmW0ubUz/FF9drHWTAh4DLSY+tSzVpiVGR00yRv7MResrhfFUCgYEA7cJo
vmaMUzqfjWRlbSTArgLm4jZejojtS/xhnwSWc++voVX6GRs1zOwXYyQVyhueUS1Y
C4pv4vbp4+keZpAGvt+IAuP/ZpXrz/UzkkTNsTk5iqO2GGDYZVicHB4bZkGtY8gi
Zp3YGfPS++BthiPSTiYVHnjOYVyeYLXpnEIRpL0CgYBCbcplFKwE03Hou5ByzS97
eA70OjTShwcZSfDu9/S2aemjCVhI/0A+n4oD3BBfN1Xd93bddoMud+Cv6KRE2lqE
KueshZz/v1rHzNIO1ZWYTdF2xfhkCCADiLMmczWRc7onb0nS9iv/MCHGVAWfQ9R/
w4xor0+exMklOYgiJAzq+QKBgFwOnP2zuPt0xFg7miXjSBNYHktSH9RyYea85pNq
dFKZaFhAcOCNr4wTkY6aZzFk9iyaMO/u/xlS3waWuWWeuG3pIMF1w+rVe4N+fiRR
LY9EB+qNLrFLth2vbGpaoeM65Maws9klnomV5YgOwnlgn0oQ5rZwsf/ym4P4i2Ys
EqbFAoGBAJt8hRz3usGwYvVMFSn0AWs0ynReJ1MIDaRSTCp+U+kWoNm1bTZUcZDI
mXenGCxiNRiTZaNGpSXLhUNw7KKLoBORCW1M8aZf2qPJxg2wb7z/i+fssRIeJjoj
ZTfPnVeHOpRCmmjJ8oJDXWf9fUOjq2EwyhTAwrUjLrb6aoPvp93e
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       02:fb:79:9c:9c:61:20:21:26:d1:6c:6a:5e:22:43:d0:26:63:9d:23
```

Как видим, нам выдали всю цепочку сертификатов.

Отзовем сертификат
```
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="02:fb:79:9c:9c:61:20:21:26:d1:6c:6a:5e:22:43:d0:26:63:9d:23"
Key                        Value
---                        -----
revocation_time            1591995898
revocation_time_rfc3339    2020-06-12T21:04:58.63917116Z
```

# Выполнено ДЗ №9
# Kubernetes Logging

 - [x] Основное ДЗ

## В процессе сделано:

Обновляем конфигурацию для kubectl
```
gcloud container clusters get-credentials otus --zone us-central1-c --project sharp-haven-274816
```

Помечаем ноды infra-pool как недоступные для деплоя подов по-умолчанию.
```
kubectl taint nodes gke-otus-infra-pool-c1cf63a8-9srl node-role=infra:NoSchedule
kubectl taint nodes gke-otus-infra-pool-c1cf63a8-lzk0 node-role=infra:NoSchedule
kubectl taint nodes gke-otus-infra-pool-c1cf63a8-r3k1 node-role=infra:NoSchedule
```

### Create namespaces

Сооздаем несколько namespace-ов для развертывания демо-приложения, инфраструктуры для логирования/мониторинга и nginx-ingress-а.
```
kubectl create ns microservices-demo
kubectl create ns observability
kubectl create ns nginx-ingress
```

### Demo app install

Устанавливаем демо-приложение
```
kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo
```

### Nginx controller install

Стамим nginx-ingress
```
helm upgrade --install nginx-ingress stable/nginx-ingress --wait --namespace=nginx-ingress -f nginx-ingress.values.yaml
```

Промеряем доступность дефолтного backend-а 
```
kubectl get svc -n nginx-ingress 

curl 35.188.170.169
```

**Пояснения по values.yaml**

В переменной config указываем желательный формат логирования - json, и набор полей, который мы хотим сохранять в логе (переменные log-format-escape-json и log-format-upstream, соответственно).

Определяем ноды, на которые мы желаем установить контроллер - переменные tolerations и nodeSelector.

При помощи переменной affinity избегаем установки нескольких контроллеров (если мы захотим иметь их больше одного - replicaCount) на одну ноду.

В блоке metrics включаем сбор метрик с любых namespace-ов, где есть ingress-ы (переменная namespaceSelector).

### Prometheus operator

Устанавливаем стек, включающий в себя Prometheus, Grafana (и еще много интересного).
```
helm upgrade --install prometheus-operator stable/prometheus-operator --namespace observability -f prometheus-operator.values.yaml
```

**Пояснения по values.yaml**

Определяем ноды, на которые мы желаем установить компоненты стека - переменные tolerations и nodeSelector.

В соответствующих (alertmanager, grafana, prometheus) блоках определяем igress-ресурсы.

В блоке grafana дополнительно определяем:
- наличие дефолтных дашбордов: defaultDashboardsEnabled
- пароль администратора: adminPassword
- Datasouce для Loki: additionalDataSources. Дополнительно следуем помнить, что определенные тут datasouce-ы нельзя изменять через UI графаны.

В блоке grafana дополнительно определяем в переменной prometheusSpec настройки работы с service monitor-ами, а именно - при помощи serviceMonitorSelectorNilUsesHelmValues отключаем проверку на наличие "...labeled with the same release tag as the prometheus-operator release", и так же указываем на необходимость искать любые мониторы (serviceMonitorSelector) во всех namespace-ах (serviceMonitorNamespaceSelector). 

### ELK stack

Устанавливаем ELK stack при помощи нескольких чартов.
```
helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability -f elasticsearch.values.yaml

helm upgrade --install kibana elastic/kibana --namespace observability -f kibana.values.yaml

helm upgrade --install fluent-bit stable/fluent-bit --namespace observability -f fluent-bit.values.yaml

helm upgrade --install elasticsearch-exporter stable/elasticsearch-exporter --setes.uri=http://elasticsearch-master:9200 --set serviceMonitor.enabled=true --namespace=observability
```

**Пояснения по values.yaml каждого чарта**

**Elasticsearch**

Для экономии ресурсов тестового кластера указываем, что хотим развернуть только один мастер - переменные replicas и minimumMasterNodes.

Определяем ноды, на которые мы желаем провести установку - переменные tolerations и nodeSelector.

**Kibana**

Определяем ноды, на которые мы желаем провести установку - переменные tolerations и nodeSelector.

В переменной ingress определяем соответствующий ingress-ресурс.

**Fluent-bit**

Так как мы хотим собирать логи со всех нод, то определяем переменную tolerations.

В блоке backend указываем, что в качестве бэкенда мы используем Elasticsearch и для хоста определяем имя сервиса эластика.

В блоке rawConfig решаем проблему с дублированием полей time и timestamp путем их удаления. Другие варианты решения проблемы - это, к примеру, переименование полей или добавление к именам полей какого-нибудь дополнительного префикса (mergeLogKey).

### Loki Stack

Устанавливаем из чартов собственно Loki и Promtail
```
helm repo add loki https://grafana.github.io/loki/charts
helm repo update

helm upgrade --install loki loki/loki-stack --namespace observability -f loki.values.yaml
```

В блоке promtail указываем толлерантность к чему угодно - опять же для того, чтобы собирать информацию со всех узлов, даже с тех, где есть метки NoSchedule.

Все остальные приседания выполняем в соответствии с описанием ДЗ.

Дополнительные файлы:
- export.ndjson - дашборд ElasticSearch
- nginx-ingress.json - дашборд Grafana

### Использованные источники

- https://grafana.com/grafana/dashboards/4358
- https://medium.com/zolo-engineering/configuring-prometheus-operator-helm-chart-with-aws-eks-part-2-monitoring-of-external-services-342e352d85f0
- https://fluentbit.io/documentation/0.13/filter/modify.html
- https://tjth.co/reindexing-data-in-elasticsearch-changing-field-type/


# Выполнено ДЗ №8
# Kubernetes Monitiring

 - [x] Основное ДЗ

## В процессе сделано:

В стандартные настройки внесены следующие изменения:
- в блоке ingress указано имя хоста (hostname)
- включен сервис-мониторинг для прометея (serviceMonitor.enabled)

### Дополнительные материалы

Дашборд для Nginx: kubernetes-monitoring/dashboard.json

Скриншот дашборда
![Image of dashboard](https://pasteboard.co/Jc7VS7P.jpg)



# Выполнено ДЗ №7
# Kubernetes Operator

 - [x] Основное ДЗ

## В процессе сделано:

- Определен CustomResourceDefinition

Для указания обязательности поля используется конструкция вида
```
      required:
        - apiVersion
        - kind
        - metadata
```

Собственно валидация полей проводится при помощи блока validation
```
  validation:
    openAPIV3Schema:
      type: object
      properties:
        apiVersion:
          type: string
  ...
```

- развернута база mysql при помощи оператора

- отработали job-ы восстановления и backup-а
```
backup-mysql-instance-job    1/1           2s         3m14s
restore-mysql-instance-job   1/1           5m40s      8m47s
```

- после пересоздания базы (удаление и последующий повторое создание ресурса) содержимое таблиц не пострадало
```
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

# Выполнено ДЗ №6 
# Kubernetes templating
 - [x] Основное ДЗ

## В процессе сделано:

 - установлен Helm 3

 Непосредственно установка
 ```
 wget https://get.helm.sh/helm-v3.2.2-linux-amd64.tar.gz
 tar -zxvf helm-v3.2.2-linux-amd64.tar.gz
 mv linux-amd64/helm /usr/local/bin/helm
 ```

 Добавление репозитория
 ```
 helm repo add stable https://kubernetes-charts.storage.googleapis.com/
 helm search repo stable
 ```
 
 - Установлен cert-manager

 ```
 kubectl create namespace cert-manager
 helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v0.15.1 --set installCRDs=true
 ```

 Так как сертфикат кто-то должен подписать, дополнительно необходимо настоить соответствующий Issuer (в данном случае это Letsencrypt)
 ```
 kubectl apply -f kubernetes-templating/cert-manager/prod_issuer.yaml
 ```

 - Chartmuseum

 ```
 kubectl create ns chartmuseum
 helm upgrade --install chartmuseum stable/chartmuseum --wait --namespace=chartmuseum -f kubernetes-templating/chartmuseum/values.yaml
 ```

 Дополнительно в values.yaml необходимо установить пераметр
 ```
 env:
  open:
    DISABLE_API: false
 ```

 Если этого не сделать - обращение к API будет невозможным.

 Загрузка Chart-а
 ```
 cd hipster-shop
 helm package .
 curl --data-binary "@hipster-shop-0.1.0.tgz" https://chartmuseum.35.202.248.131.nip.io/api/charts
 ```

 Так как "из коробки" мы, фактически, получаем только REST-интерфейс, то при желании воспользоваться web-интерфейсом, потребуется стороннее решение. Например, https://github.com/chartmuseum/ui - позволяющий просматривать и даже загружать чарты через web-интерфейс.

 - установка Harbor

 ```
 helm repo add harbor https://helm.goharbor.io
 helm install --name harbor harbor/harbor -f kubernetes-templating/harbor/value.yaml
 ```

 - kubecfg

 Установка в MacOs
 ```
 brew install kubecfg
 ```

 - kustomize

 Установка в MacOs
 ```
 brew install kustomize
 ```

 Возможная структура каталогов, позволяющая разделить описания по средам установки
 ```
|
|-Some app
| |-base
| | |-kustomization.yaml
| | |-app-deployment.yaml
| | |-app-service.yaml
| |
| |-overrides
|    |-stage
|    | |-kustomization.yaml
|    |
|    |-prod
|      |-kustomization.yaml
|
 ```

Просмотр "рендеринга" манифестов
```
kustomize build overrides/hipster-shop/
```

# Выполнено ДЗ №5

 - [x] Основное ДЗ
 - [x] Задание со *

## В процессе сделано:

 - познакомились с понятием StatefulSet

 - (*) Для хранения MINIO_ACCESS_KEY и MINIO_SECRET_KEY создан объект типа Secret  (см .credentials.yaml).
 Впрочем, учитывая особенности "секретного" хранения данных в кубере стоило бы хранить эти переменные, к примеру, в Hashicorp Vault.

# Выполнено ДЗ №4

 - [x] Основное ДЗ
 - [x] Задание со *

## В процессе сделано:

Перейдем сразу к звездам.

Впрочем, на тему "livenessProbe с прверкой запуска процесса" - технически возможно, но на мой взгляд смыста не имеет, так как, обычно, от процесса требуется чуть больше, чем просто его запуск.

### DNS через MetalLB

Для работы DNS на необходимо обеспечить обращение к назначенному адресу по протоколам TCP и UDP. Так как MetalLB не умеет в мультипротоколы, воспользуемся его возможностью делить один IP между несколькими сервисами.

Это достигается при помощи аннотации:
```
  annotations:
    metallb.universe.tf/allow-shared-ip: dns--primary
```

Если у двух сервисов указывается одиноковый ключ (тут это - dns--primary), то два сервиса получают один и тот же IP.
```
kube-system            out-dns-tcp                          LoadBalancer   10.111.145.71   172.17.255.2   53:30069/TCP                 29h
kube-system            out-dns-udp                          LoadBalancer   10.102.155.94   172.17.255.2   53:30045/UDP                 29h
```

```
$ nslookup kubernetes.default.svc.cluster.local 172.17.255.2
Server:		172.17.255.2
Address:	172.17.255.2#53

Name:	kubernetes.default.svc.cluster.local
Address: 10.96.0.1
```

### Ingress для Dashboard

Так как dashboard-у требуется https, добавим в настройку ingress-а аннотацию:
```
nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
```

Дополнительно добавим блок, отвечающий за корректное формирование адресной строки (нам нужно добавлять к /dashboard, то, что будет динамически сформировано при работе с бордой):
```
    nginx.ingress.kubernetes.io/configuration-snippet: |
      rewrite ^(/dashboard)$ $1/ permanent;
      rewrite "(?i)/dashboard(/|$)(.*)" /$2 break;
```

После чего можем обращаться к dashboard по адресу (не забудем добавить lb-ingress.local в /etc/hosts)
https://lb-ingress.local/dashboard
```
$ curl -kL https://lb-ingress.local/dashboard
<!doctype html>
<html lang="en">

<head>
  <meta charset="utf-8">
  <title>Kubernetes Dashboard</title>
  <link rel="icon"
        type="image/png"
        href="assets/images/kubernetes-logo.png" />
  <meta name="viewport"
        content="width=device-width">
<link rel="stylesheet" href="styles.d8a1833bf9631b49f8ae.css"></head>

<body>
  <kd-root></kd-root>
<script src="runtime.a3c2fb5c390e8fb10577.js" defer></script><script src="polyfills-es5.ddf623b9f96429e29863.js" nomodule defer></script><script src="polyfills.24a7a4821c30c3b30717.js" defer></script><script src="scripts.391d299173602e261418.js" defer></script><script src="main.a0d83b15387cfc420c65.js" defer></script></body>

</html>
```

### Canary для Ingress

Опять же воспользуемся аннотациями, предназначенными именно для распределения потоков трафика.
```
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "50"
```

Проверим, таким ли будет распределение:
```
$ for i in $(seq 1 10); do curl -s http://lb-ingress.local/web/index.html | grep 172; done
172.17.0.5	canary-7ff7869755-m56jm</pre>
172.17.0.6	canary-7ff7869755-2d79v</pre>
172.17.0.5	production-5f968785b5-brjlx</pre>
172.17.0.7	production-5f968785b5-jtkr8</pre>
172.17.0.5	canary-7ff7869755-m56jm</pre>
172.17.0.8	canary-7ff7869755-kfnph</pre>
172.17.0.6	production-5f968785b5-j8b6b</pre>
172.17.0.6	canary-7ff7869755-2d79v</pre>
172.17.0.8	canary-7ff7869755-kfnph</pre>
172.17.0.5	production-5f968785b5-brjlx</pre>
```

В общем - примерно то, что и ожидали. Не забываем, что речь идет о вероятности.

(⎈ |minikube:default)➜  canary git:(kubernetes-networks) ✗ for i in $(seq 1 10); do curl -s http://lb-ingress.local/web/index.html | grep 172; sleep 1; done
172.17.0.8	canary-7ff7869755-kfnph</pre>
172.17.0.6	production-5f968785b5-j8b6b</pre>
172.17.0.5	canary-7ff7869755-m56jm</pre>
172.17.0.6	production-5f968785b5-j8b6b</pre>
172.17.0.6	canary-7ff7869755-2d79v</pre>
172.17.0.7	production-5f968785b5-jtkr8</pre>
172.17.0.5	production-5f968785b5-brjlx</pre>
172.17.0.7	production-5f968785b5-jtkr8</pre>
172.17.0.6	production-5f968785b5-j8b6b</pre>
172.17.0.5	canary-7ff7869755-m56jm</pre>

# Выполнено ДЗ №3

 - [x] Основное ДЗ

## В процессе сделано:
 - создана сервисная учетная запись bob с ролью админ в рамках кластера
 - создана сервисная учетная запись dave без доступа к кластеру (т.е. без прикрепления ролей)
 - создано пространство имен prometheus
 - создана сервисная учетная запись carol в пространстве prometheus
 - всем сервисным учетным записям пространства prometheus прикреплена роль просмотра pod-ов всего кластера
 - создано пространство имен dev
 - создана сервисная учетная запись jane в пространстве dev
 - к учетной сервисной записи jane прикреплена роль admin в рамках пространства dev
 - создана сервисная учетная запись ken в пространстве dev
 - к учетной сервисной записи ken прикреплена роль view в рамках пространства dev


# Выполнено ДЗ №2

 - [x] Основное ДЗ
 - [x] Задание со *
 - [x] Задание со **

## В процессе сделано:
 - запуск pod-а при помощи ReplicaSet
 - горизонтальное масштабирование pod-ов
 - проверка влияния обновления ReplicaSet на обновление pod-ов (спойлер: не влияет)
 - подготовлен манифест ReplicaSet для сервиса paymentService
 - проведено обновление Deployments сервиса paymentService со стратегией Rolling Update (по-умолчанию)
 - откат к предыдущей ревизии Deployments-а
 - реализация стратегии Blue-Green развертывания
 - реализация стратегии Reverse Rolling Update развертывания
 - изучено использование readinessProbe
 - при помощи DaemonSet установлен Node Exporter

## Детальное описание работы

Сервис frontend запускается при помощи контроллера ReplicaSet.
```
$ kubectl apply -f frontend-replicaset.yaml
replicaset.apps/frontend created
```

Масштибировать кол-во pod-ов можно при помощи команды **kubectl scale**
```
$ kubectl scale replicaset frontend --replicas=3
replicaset.extensions/frontend scaled
```

Результат масштабирования
```
$ kubectl get pods -l app=frontend
NAME             READY   STATUS    RESTARTS   AGE
frontend-qc5fs   1/1     Running   0          11s
frontend-rg44k   1/1     Running   0          11s
frontend-wlr4q   1/1     Running   0          2m45s
```

Дополнительную информацию по ReplicaSet-у можно получить командой:
```
$ kubectl get rs frontend
NAME       DESIRED   CURRENT   READY   AGE
frontend   3         3         3       4m47s
```

Теперь удаление pod-а приводит к тому, что заместо удаленных pod-ов поднимаются новые:
```
$ kubectl delete pods -l app=frontend | kubectl get pods -l app=frontend -w
NAME             READY   STATUS              RESTARTS   AGE
frontend-gsxw2   1/1     Running             0          2m14s
frontend-kw575   1/1     Running             0          2m14s
frontend-w878c   1/1     Running             0          2m14s
frontend-gsxw2   1/1     Terminating         0          2m14s
frontend-kw575   1/1     Terminating         0          2m14s
frontend-57wtj   0/1     Pending             0          0s
frontend-w878c   1/1     Terminating         0          2m14s
frontend-57wtj   0/1     Pending             0          0s
frontend-x9dxf   0/1     Pending             0          1s
frontend-57wtj   0/1     ContainerCreating   0          1s
frontend-x9dxf   0/1     Pending             0          1s
frontend-jlp6l   0/1     Pending             0          0s
frontend-jlp6l   0/1     Pending             0          0s
frontend-x9dxf   0/1     ContainerCreating   0          1s
frontend-jlp6l   0/1     ContainerCreating   0          0s
frontend-x9dxf   1/1     Running             0          2s
frontend-57wtj   1/1     Running             0          2s
frontend-jlp6l   1/1     Running             0          2s
```

Необходимое кол-во реплик можно указать и непосредственно в манифесте:
```
spec:
  replicas: 3
```

Обратим внимание, что при применении манифеста с измененной версией образа сервиса, фактически pod-ы не пересоздаются и продолжают работать со старой версией:
```
kubectl get replicaset frontend -o=jsonpath='{.spec.template.spec.containers[0].image}'
soaron/frontend:2.0         

kubectl get pods -l app=frontend -o=jsonpath='{.items[0:3].spec.containers[0].image}'
soaron/frontend:1.0 soaron/frontend:1.0 soaron/frontend:1.0
```

Обновление манифеста ReplicaSet не приводит к обновлению pod-ов, так как в задачи  контроллера ReplicaSet не входит проверка соответствия pod-а указанному шаблону, он мониторит кол-во запущенных pod-ов.

Деплой сервиса при помощи объекта Deployment приводит к образования как соответствующего deployment-а так и подчиненного ему replicaset-а.
```
$ kubectl get po
NAME                              READY   STATUS    RESTARTS   AGE
frontend-9m5fj                    1/1     Running   0          26m
frontend-dl6cl                    1/1     Running   0          26m
frontend-fzflh                    1/1     Running   0          26m
paymentservice-566547965d-267q6   1/1     Running   0          3s
paymentservice-566547965d-n5922   1/1     Running   0          3s
paymentservice-566547965d-p9rnf   1/1     Running   0          3s

$ kubectl get deployments
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
paymentservice   3/3     3            3           25s

$ kubectl get rs         
NAME                        DESIRED   CURRENT   READY   AGE
frontend                    3         3         3       32m
paymentservice-566547965d   3         3         3       32s
```


Обновление версии сервиса в Deployment уже приводит к пересозданию pod-ов:
```
$ kubectl apply -f paymentser
vice-deployment.yaml | kubectl get pods -l app=paymentservice -w
NAME                              READY   STATUS    RESTARTS   AGE
paymentservice-566547965d-267q6   1/1     Running   0          4m26s
paymentservice-566547965d-n5922   1/1     Running   0          4m26s
paymentservice-566547965d-p9rnf   1/1     Running   0          4m26s
paymentservice-699f9865ff-2ppnw   0/1     Pending   0          0s
paymentservice-699f9865ff-2ppnw   0/1     Pending   0          0s
paymentservice-699f9865ff-2ppnw   0/1     ContainerCreating   0          0s
paymentservice-699f9865ff-2ppnw   1/1     Running             0          3s
paymentservice-566547965d-p9rnf   1/1     Terminating         0          4m30s
paymentservice-699f9865ff-4t2vk   0/1     Pending             0          0s
paymentservice-699f9865ff-4t2vk   0/1     Pending             0          0s
paymentservice-699f9865ff-4t2vk   0/1     ContainerCreating   0          0s
paymentservice-699f9865ff-4t2vk   1/1     Running             0          3s
paymentservice-566547965d-n5922   1/1     Terminating         0          4m33s
paymentservice-699f9865ff-ksrg6   0/1     Pending             0          0s
paymentservice-699f9865ff-ksrg6   0/1     Pending             0          0s
paymentservice-699f9865ff-ksrg6   0/1     ContainerCreating   0          0s
paymentservice-699f9865ff-ksrg6   1/1     Running             0          4s
paymentservice-566547965d-267q6   1/1     Terminating         0          4m37s
```

Обратим внимание, что при этом образуется новый replicaset, старый продолжает существовать, но с нулевыми значениями для кол-ва pod-ов.
```
$ kubectl get rs
NAME                        DESIRED   CURRENT   READY   AGE
frontend                    3         3         3       39m
paymentservice-566547965d   0         0         0       7m42s
paymentservice-699f9865ff   3         3         3       3m15s
```

Версии сервисов в replicaset-ах:
```
$ kubectl get replicaset paymentservice-566547965d -o=jsonpath='{.spec.template.spec.containers[0].image}'
soaron/paymentservice:0.0.1

$ kubectl get replicaset paymentservice-699f9865ff -o=jsonpath='{.spec.template.spec.containers[0].image}'
soaron/paymentservice:0.0.2
```

Посмотреть историю deployment-ов можно следующим образом:
```
$ kubectl rollout history deployment paymentservice
deployment.extensions/paymentservice 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

А вернуться к нужной версии так:
```
$ kubectl rollout undo deployment paymentservice --to-revision=1 | kubectl get rs -l app=paymentservice -w
NAME                        DESIRED   CURRENT   READY   AGE
paymentservice-566547965d   0         0         0       12m
paymentservice-699f9865ff   3         3         3       8m3s
paymentservice-566547965d   0         0         0       12m
paymentservice-566547965d   1         0         0       12m
paymentservice-566547965d   1         0         0       12m
paymentservice-566547965d   1         1         0       12m
paymentservice-566547965d   1         1         1       12m
paymentservice-699f9865ff   2         3         3       8m5s
paymentservice-566547965d   2         1         1       12m
paymentservice-699f9865ff   2         3         3       8m5s
paymentservice-699f9865ff   2         2         2       8m5s
paymentservice-566547965d   2         1         1       12m
paymentservice-566547965d   2         2         1       12m
paymentservice-566547965d   2         2         2       12m
paymentservice-699f9865ff   1         2         2       8m7s
paymentservice-566547965d   3         2         2       12m
paymentservice-699f9865ff   1         2         2       8m7s
paymentservice-566547965d   3         2         2       12m
paymentservice-699f9865ff   1         1         1       8m7s
paymentservice-566547965d   3         3         2       12m
paymentservice-566547965d   3         3         3       12m
paymentservice-699f9865ff   0         1         1       8m9s
paymentservice-699f9865ff   0         1         1       8m9s
paymentservice-699f9865ff   0         0         0       8m9s
```

(*) Рассмотрим несколько вариантов деплоя при помощи опций maxSurge и maxUnavailable.

maxSurge - определяет, скольким экземплярам pod-а позволяется существовать выше требуемого количества реплик, настроенного на развертывании. 

maxUnavailable - определяет, сколько экземпляров pod-а может быть недоступно относительно требуемого количества реплик во время обновления. 

Blue/Grean

Для реализации этой стратегии позволим создавать максимальное кол-во новых pod-ов (maxSurge: 100%) и одновременно ограничим до минимума кол-во недоступных pod-ов (maxUnavailable: 0).

Убедимся в достижении требуемого результата:
```
$ kubectl apply -f paymentservice-deployment-bg.yaml | kubectl get pods -l app=paymentservice -w
NAME                              READY   STATUS    RESTARTS   AGE
paymentservice-566547965d-qjr6h   1/1     Running   0          5m29s
paymentservice-566547965d-tkndh   1/1     Running   0          5m29s
paymentservice-566547965d-zc7hs   1/1     Running   0          5m29s
paymentservice-699f9865ff-s4m42   0/1     Pending   0          0s
paymentservice-699f9865ff-s4m42   0/1     Pending   0          1s
paymentservice-699f9865ff-h4jsd   0/1     Pending   0          1s
paymentservice-699f9865ff-n4fbv   0/1     Pending   0          1s
paymentservice-699f9865ff-s4m42   0/1     ContainerCreating   0          1s
paymentservice-699f9865ff-h4jsd   0/1     Pending             0          1s
paymentservice-699f9865ff-n4fbv   0/1     Pending             0          1s
paymentservice-699f9865ff-n4fbv   0/1     ContainerCreating   0          1s
paymentservice-699f9865ff-h4jsd   0/1     ContainerCreating   0          1s
paymentservice-699f9865ff-n4fbv   1/1     Running             0          2s
paymentservice-566547965d-qjr6h   1/1     Terminating         0          5m31s
paymentservice-699f9865ff-s4m42   1/1     Running             0          3s
paymentservice-699f9865ff-h4jsd   1/1     Running             0          3s
paymentservice-566547965d-zc7hs   1/1     Terminating         0          5m32s
paymentservice-566547965d-tkndh   1/1     Terminating         0          5m32s
```


Reverse Rolling Updat

Требуемое поведение:

1. Удаление одного старого pod
2. Создание одного нового pod
3. ...

Для этой стратегии запретим превышать требуемое кол-во pod-ов (maxSurge: 0) и позволим только одному pod-у быть недоступным (maxUnavailable: 1).

Убедимся в достижении требуемого результата:
```
$ kubectl apply -f paymentservice-deployment-reverse.yaml | kubectl get pods -l app=paymentservice -w
NAME                              READY   STATUS    RESTARTS   AGE
paymentservice-566547965d-77t8h   1/1     Running   0          86s
paymentservice-566547965d-hqgxv   1/1     Running   0          84s
paymentservice-566547965d-pbg9v   1/1     Running   0          86s
paymentservice-566547965d-hqgxv   1/1     Terminating   0          84s
paymentservice-699f9865ff-9q48z   0/1     Pending       0          0s
paymentservice-699f9865ff-9q48z   0/1     Pending       0          0s
paymentservice-699f9865ff-9q48z   0/1     ContainerCreating   0          0s
paymentservice-699f9865ff-9q48z   1/1     Running             0          2s
paymentservice-566547965d-pbg9v   1/1     Terminating         0          88s
paymentservice-699f9865ff-9pgcg   0/1     Pending             0          0s
paymentservice-699f9865ff-9pgcg   0/1     Pending             0          0s
paymentservice-699f9865ff-9pgcg   0/1     ContainerCreating   0          0s
paymentservice-699f9865ff-9pgcg   1/1     Running             0          2s
paymentservice-566547965d-77t8h   1/1     Terminating         0          90s
paymentservice-699f9865ff-gd92x   0/1     Pending             0          0s
paymentservice-699f9865ff-gd92x   0/1     Pending             0          0s
paymentservice-699f9865ff-gd92x   0/1     ContainerCreating   0          0s
paymentservice-699f9865ff-gd92x   1/1     Running             0          2s
```

Использование readinessProbe позволяет делать сервис доступным при выполнении указанных условий.

Результат исполнения readinessProbe можно увидеть при выполнении команды **kubectl decsribe po ...**
```
...
Ready:          True
    Restart Count:  0
    Readiness:      http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
```

Если условие readinessProbe не выполняется, то мы видим это как отсутствие pod-а в статусе Ready
```
frontend-5bdffb79ff-nf9gv         0/1     Running   0          35s
```

И явное указание на проблему можно увидеть в описании pod-а
```
$ kubectl describe po frontend-5bdffb79ff-nf9gv
...
  Warning  Unhealthy  4s (x6 over 54s)  kubelet, kind-worker2  Readiness probe failed: HTTP probe failed with statuscode: 404
```

Еще одним полезным контроллером является DaemonSet. Он позволяет автоматически разворачивать pod-ы на всех доступных узлах кластера.

(*) Развернем на всех узлах сервис Node exporter для импорта метрик узлов.

Манифест представляет собой компиляцию из https://github.com/coreos/kube-prometheus/blob/master/manifests/.

Результат развертывания:
```
$ kubectl port-forward node-exporter-cshpr -n monitoring 9100:9100
Forwarding from 127.0.0.1:9100 -> 9100
Forwarding from [::1]:9100 -> 9100
Handling connection for 9100

$ curl localhost:9100/metrics | more
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 12108    0 12108    0     0   125k      0 --:--:-- --:--:-- --:--:--  124k# HELP go_gc_duration_seconds A summary of the GC invocation durations.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0
go_gc_duration_seconds{quantile="0.25"} 0
go_gc_duration_seconds{quantile="0.5"} 0
go_gc_duration_seconds{quantile="0.75"} 0
go_gc_duration_seconds{quantile="1"} 0
go_gc_duration_seconds_sum 0
go_gc_duration_seconds_count 0
```

(**) Обратим внимание, что данный сервис успешно установился и на мастер-узлы, чего обычно для пользовательских pod-ов не происходит.

В данном случае установка на мастер-узлы призошла благодаря спецификации
```
      tolerations:
      - operator: Exists
```

Использование одного только operator: Exists гарантирует иммнунитет к любым ограничениям, включая NoSchedule у мастер-узлов.
```
$ kubectl describe nodes kind-control-plane | grep Taints
Taints:             node-role.kubernetes.io/master:NoSchedule
```

# Выполнено ДЗ №1

 - [x] Основное ДЗ
 - [x] Задание со *

## В процессе сделано:
 - Поднят кластер K8S при помощи kind
 - Настроено автодополнение
 - Проверена способность кластера к самовосстановлению (при принудительном удалении системных pod-ов). Мониторингом основных системных под-ов занимается лично kubelet-агент. Если системыне компоненты установлены как сервисы, то за их здоровьем следит systemd. Поды, которые в манифестах описываются как объекты типа Deployments, восстанавливаются до необходимого кол-ва при помощи deployments-контроллера.
 - Установлен pod с init-контейнером
 - (*) Установлен микросервис frontend демонстрационного проекта Online Boutique (https://github.com/GoogleCloudPlatform/microservices-demo)

## PR checklist:
 - [x] Выставлен label с темой домашнего задания

## Детальное описание работы

Инструкции для добавления автодополнения можно найти тут:
https://kubernetes.io/docs/reference/kubectl/cheatsheet/#kubectl-autocomplete

Для ZSH указания следующие:
```
source <(kubectl completion zsh)  # setup autocomplete in zsh into the current shell
echo "[[ $commands[kubectl] ]] && source <(kubectl completion zsh)" >> ~/.zshrc # add autocomplete permanently to your zsh shell
```

Кластер K8S при помощи kind создается так:
```
$ kind create cluster --config ~/kind-config.yaml
```
После создания кластера заносим в переменную окружения KUBECONFIG данные для доступа к кластеру:
```
$ export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
```
В конфиге kind-а можно описать желаемое кол-в узлов:
```
$ cat ~/kind-config.yaml 
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
- role: control-plane
- role: control-plane
- role: control-plane
- role: worker
- role: worker
- role: worker
```

Общая информация по кластеру, включая endpoint apiserver-а:
```
$ kubectl cluster-info
```

Посмотреть состояние кластера можно и так:
```
$ kubectl get cs
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok                  
controller-manager   Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
```
Процесс убиения системных pod-ов и их возрождение:
```
$ kubectl get po -n kube-system
NAME                                          READY   STATUS    RESTARTS   AGE
coredns-5c98db65d4-nfw25                      1/1     Running   0          13m
coredns-5c98db65d4-qbkqf                      1/1     Running   0          13m
etcd-kind-control-plane                       1/1     Running   0          12m
etcd-kind-control-plane2                      1/1     Running   0          13m
etcd-kind-control-plane3                      1/1     Running   0          12m
kindnet-5hq2s                                 1/1     Running   1          12m
kindnet-8zcqr                                 1/1     Running   1          11m
kindnet-k8jcn                                 1/1     Running   1          13m
kindnet-lkv78                                 1/1     Running   1          11m
kindnet-nvj86                                 1/1     Running   1          11m
kindnet-v5p65                                 1/1     Running   1          13m
kube-apiserver-kind-control-plane             1/1     Running   0          12m
kube-apiserver-kind-control-plane2            1/1     Running   0          13m
kube-apiserver-kind-control-plane3            1/1     Running   0          11m
kube-controller-manager-kind-control-plane    1/1     Running   1          12m
kube-controller-manager-kind-control-plane2   1/1     Running   0          13m
kube-controller-manager-kind-control-plane3   1/1     Running   0          11m
kube-proxy-4bfct                              1/1     Running   0          12m
kube-proxy-8gqs7                              1/1     Running   0          11m
kube-proxy-bgv4f                              1/1     Running   0          13m
kube-proxy-ckmlv                              1/1     Running   0          13m
kube-proxy-fbm99                              1/1     Running   0          11m
kube-proxy-hzbsm                              1/1     Running   0          11m
kube-scheduler-kind-control-plane             1/1     Running   1          12m
kube-scheduler-kind-control-plane2            1/1     Running   0          13m
kube-scheduler-kind-control-plane3            1/1     Running   0          11m
$ kubectl delete pod --all -n kube-system
pod "coredns-5c98db65d4-nfw25" deleted
pod "coredns-5c98db65d4-qbkqf" deleted
pod "etcd-kind-control-plane" deleted
pod "etcd-kind-control-plane2" deleted
pod "etcd-kind-control-plane3" deleted
pod "kindnet-5hq2s" deleted
pod "kindnet-8zcqr" deleted
pod "kindnet-k8jcn" deleted
pod "kindnet-lkv78" deleted
pod "kindnet-nvj86" deleted
pod "kindnet-v5p65" deleted
pod "kube-apiserver-kind-control-plane" deleted
pod "kube-apiserver-kind-control-plane2" deleted
pod "kube-apiserver-kind-control-plane3" deleted
pod "kube-controller-manager-kind-control-plane" deleted
pod "kube-controller-manager-kind-control-plane2" deleted
pod "kube-controller-manager-kind-control-plane3" deleted
pod "kube-proxy-4bfct" deleted
pod "kube-proxy-8gqs7" deleted
pod "kube-proxy-bgv4f" deleted
pod "kube-proxy-ckmlv" deleted
pod "kube-proxy-fbm99" deleted
pod "kube-proxy-hzbsm" deleted
pod "kube-scheduler-kind-control-plane" deleted
pod "kube-scheduler-kind-control-plane2" deleted
pod "kube-scheduler-kind-control-plane3" deleted
$ kubectl get po -n kube-system --watch  
NAME                                          READY   STATUS    RESTARTS   AGE
coredns-5c98db65d4-dh5ll                      1/1     Running   0          30s
coredns-5c98db65d4-mp699                      1/1     Running   0          30s
etcd-kind-control-plane                       1/1     Running   0          30s
etcd-kind-control-plane2                      1/1     Running   0          30s
etcd-kind-control-plane3                      1/1     Running   0          29s
kindnet-9qn56                                 1/1     Running   0          25s
kindnet-b96vd                                 1/1     Running   0          26s
kindnet-dtprc                                 1/1     Running   0          17s
kindnet-kpfnb                                 1/1     Running   0          25s
kindnet-mccp8                                 1/1     Running   0          26s
kindnet-rc24g                                 1/1     Running   0          26s
kube-apiserver-kind-control-plane             1/1     Running   0          28s
kube-apiserver-kind-control-plane2            1/1     Running   0          28s
kube-apiserver-kind-control-plane3            1/1     Running   0          25s
kube-controller-manager-kind-control-plane    1/1     Running   1          28s
kube-controller-manager-kind-control-plane2   1/1     Running   0          27s
kube-controller-manager-kind-control-plane3   1/1     Running   0          27s
kube-proxy-2kqtb                              1/1     Running   0          24s
kube-proxy-bf9cr                              1/1     Running   0          20s
kube-proxy-dxnqf                              1/1     Running   0          19s
kube-proxy-lcrfp                              1/1     Running   0          15s
kube-proxy-qhwh5                              1/1     Running   0          24s
kube-proxy-wh942                              1/1     Running   0          17s
kube-scheduler-kind-control-plane             1/1     Running   1          26s
kube-scheduler-kind-control-plane2            1/1     Running   0          23s
kube-scheduler-kind-control-plane3            1/1     Running   0          26s

$ kubectl get cs
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok                  
controller-manager   Healthy   ok                  
etcd-0               Healthy   {"health":"true"}
```

Причины восстановления

Мониторингом основных системных под-ов занимается лично kubelet-агент.
Если системыне компоненты установлены как сервисы, то за их здоровьем следит systemd.

Поды, которые в манифестах описываются как объекты типа Deployments восстанавливаются до необходимого кол-ва при помощи deployments контроллера.

Кстати, интересная статья про сбор данных для анализа проблем:

https://blogs.vmware.com/cloudnative/2019/11/18/troubleshooting-clusters-with-crash-recovery-and-diagnostics-for-kubernetes/


Сборка докер-образа в каталоге kubernetes-intro/web
```
$ docker build -t web:1.0 .
```

Запустим локально и посмотрим на результат:
```
$ docker run -itd -p 8000:8000 web:1.0 

$ curl localhost:8000/homework.html
<html>
    <h1>
        Hello Otus!
    </h1>
</html>
```

Отправим образ в Docker Hub
```
$ docker tag web:1.0 soaron/web:1.0

$ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: soaron
Password: 
Login Succeeded

$ docker push soaron/web:1.0
```

Установка pod-а в кластер
```
$ kubectl apply -f web-pod.yaml

$ kubectl get po         
NAME   READY   STATUS    RESTARTS   AGE
web    1/1     Running   0          22s
```

Добавим init-контейнер и посмотрим на результат
```
$ kubectl apply -f web-pod.yaml

$ kubectl port-forward --address 0.0.0.0 pod/web 8000:8000

$ curl localhost:8000/index.html
...
Mountpoints
overlay on / type overlay (rw,relatime,lowerdir=/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/21/fs,upperdir=/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/22/fs,workdir=/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/22/work)
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
tmpfs on /dev type tmpfs (rw,nosuid,size=65536k,mode=755)
devpts on /dev/pts type devpts (rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=666)
mqueue on /dev/mqueue type mqueue (rw,nosuid,nodev,noexec,relatime)
sysfs on /sys type sysfs (ro,nosuid,nodev,noexec,relatime)
tmpfs on /sys/fs/cgroup type tmpfs (ro,nosuid,nodev,noexec,relatime,mode=755)
cpuset on /sys/fs/cgroup/cpuset type cgroup (ro,nosuid,nodev,noexec,relatime,cpuset)
cpu on /sys/fs/cgroup/cpu type cgroup (ro,nosuid,nodev,noexec,relatime,cpu)
cpuacct on /sys/fs/cgroup/cpuacct type cgroup (ro,nosuid,nodev,noexec,relatime,cpuacct)
blkio on /sys/fs/cgroup/blkio type cgroup (ro,nosuid,nodev,noexec,relatime,blkio)
memory on /sys/fs/cgroup/memory type cgroup (ro,nosuid,nodev,noexec,relatime,memory)
devices on /sys/fs/cgroup/devices type cgroup (ro,nosuid,nodev,noexec,relatime,devices)
freezer on /sys/fs/cgroup/freezer type cgroup (ro,nosuid,nodev,noexec,relatime,freezer)
net_cls on /sys/fs/cgroup/net_cls type cgroup (ro,nosuid,nodev,noexec,relatime,net_cls)
perf_event on /sys/fs/cgroup/perf_event type cgroup (ro,nosuid,nodev,noexec,relatime,perf_event)
net_prio on /sys/fs/cgroup/net_prio type cgroup (ro,nosuid,nodev,noexec,relatime,net_prio)
hugetlb on /sys/fs/cgroup/hugetlb type cgroup (ro,nosuid,nodev,noexec,relatime,hugetlb)
pids on /sys/fs/cgroup/pids type cgroup (ro,nosuid,nodev,noexec,relatime,pids)
cgroup on /sys/fs/cgroup/systemd type cgroup (ro,nosuid,nodev,noexec,relatime,name=systemd)
overlay on /app type overlay (rw,relatime,lowerdir=/var/lib/docker/overlay2/l/PCJH4MPRWSVYPTT7365VKJIN2U:/var/lib/docker/overlay2/l/KI2VXTLGNQPFTADIPNU2W5AESN:/var/lib/docker/overlay2/l/D6GW574YVFNZP7YYQFD7GCDE4F:/var/lib/docker/overlay2/l/HK7YAEETYLV3BBGNO2YVAG2FBG:/var/lib/docker/overlay2/l/N742JHDYI5CKD5PO7MEBOB2S3O:/var/lib/docker/overlay2/l/BMC7QP45U7ES3PUN4MIYZ5P5IO:/var/lib/docker/overlay2/l/E5GYFPISO3AZATMIF2VB7PWTRL:/var/lib/docker/overlay2/l/UANY6FNMLIHMEB2TJV6YT2XMDV:/var/lib/docker/overlay2/l/2CZ6ZS5Z2PCHMVQNLTOG3GYHMH:/var/lib/docker/overlay2/l/6ODONGFSG4554LYZRF2KICEOTG:/var/lib/docker/overlay2/l/6ZCFMEDO4EMGQILMWBQ5IS5CXF:/var/lib/docker/overlay2/l/XDQW2VRUS76OIJR6WS4HYNZ2YK:/var/lib/docker/overlay2/l/MV4X45DRD5PXFAGL4JX4XYGEL5:/var/lib/docker/overlay2/l/OLEH2DJKYLHOIXRSJRBL6YR323,upperdir=/var/lib/docker/overlay2/58846dffa3c93ca6a8d6216eb8ea457ba144c32092bbda8e542ebfe2bfe42e35/diff,workdir=/var/lib/docker/overlay2/58846dffa3c93ca6a8d6216eb8ea457ba144c32092bbda8e542ebfe2bfe42e35/work)
Environment
export HOME='/root'
export HOSTNAME='web'
export KUBERNETES_PORT='tcp://10.96.0.1:443'
export KUBERNETES_PORT_443_TCP='tcp://10.96.0.1:443'
export KUBERNETES_PORT_443_TCP_ADDR='10.96.0.1'
export KUBERNETES_PORT_443_TCP_PORT='443'
export KUBERNETES_PORT_443_TCP_PROTO='tcp'
export KUBERNETES_SERVICE_HOST='10.96.0.1'
export KUBERNETES_SERVICE_PORT='443'
export KUBERNETES_SERVICE_PORT_HTTPS='443'
export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
export PWD='/'
export SHLVL='2'
Memory info
             total       used       free     shared    buffers     cached
Mem:          3947       3812        135         83        127       1612
-/+ buffers/cache:       2072       1875
Swap:         1023         77        946
DNS resolvers info
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
Static hosts info
# Kubernetes-managed hosts file.
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
fe00::0	ip6-mcastprefix
fe00::1	ip6-allnodes
fe00::2	ip6-allrouters
10.244.5.3	web
```

Troubleshooting 

При попытке установить frontend-сервис, при помощи указанного в ДЗ манифеста, pod переходит в состояние Error.

kubectl describe pod... ничего интересного не показывает.

Но в логах содержится интересная информация:
```
$ kubectl logs frontend       
panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set

goroutine 1 [running]:
main.mustMapEnv(0xc00039c000, 0xb03c4a, 0x1c)
        /go/src/github.com/GoogleCloudPlatform/microservices-demo/src/frontend/main.go:248 +0x10e
main.main()
        /go/src/github.com/GoogleCloudPlatform/microservices-demo/src/frontend/main.go:106 +0x3e9
```

Контейнеру не хватает указанной переменной окружения PRODUCT_CATALOG_SERVICE_ADDR - добавим ее и снова прогоним манифест.

После этого начинает не хватать уже другой переменной:
```
$ kubectl logs frontend             
panic: environment variable "CURRENCY_SERVICE_ADDR" not set
```

Начинаем подозревать, что переменных может быть много.

Идем в код искать весь список...

Что-то находим. Добавим и их.
```
	mustMapEnv(&svc.productCatalogSvcAddr, "PRODUCT_CATALOG_SERVICE_ADDR")
	mustMapEnv(&svc.currencySvcAddr, "CURRENCY_SERVICE_ADDR")
	mustMapEnv(&svc.cartSvcAddr, "CART_SERVICE_ADDR")
	mustMapEnv(&svc.recommendationSvcAddr, "RECOMMENDATION_SERVICE_ADDR")
	mustMapEnv(&svc.checkoutSvcAddr, "CHECKOUT_SERVICE_ADDR")
	mustMapEnv(&svc.shippingSvcAddr, "SHIPPING_SERVICE_ADDR")
	mustMapEnv(&svc.adSvcAddr, "AD_SERVICE_ADDR")
```

После добавления в манифест всех указанных переменных pod остается в статусе Ready.
