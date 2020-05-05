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
