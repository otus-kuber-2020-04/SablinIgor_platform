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
