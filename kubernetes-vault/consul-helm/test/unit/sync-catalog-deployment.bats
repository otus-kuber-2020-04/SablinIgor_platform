#!/usr/bin/env bats

load _helpers

@test "syncCatalog/Deployment: disabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: enable with global.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'global.enabled=false' \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: disable with syncCatalog.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: disable with global.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'global.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

#--------------------------------------------------------------------
# image

@test "syncCatalog/Deployment: image defaults to global.imageK8S" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'global.imageK8S=bar' \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "syncCatalog/Deployment: image can be overridden with server.image" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'global.imageK8S=foo' \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.image=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

#--------------------------------------------------------------------
# default sync

@test "syncCatalog/Deployment: default sync is true by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].command | any(contains("-k8s-default-sync=true"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: default sync can be turned off" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.default=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].command | any(contains("-k8s-default-sync=false"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# toConsul and toK8S

@test "syncCatalog/Deployment: bidirectional by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-consul"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-k8s"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: to-k8s only" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.toConsul=false' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-consul=false"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.toConsul=false' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-k8s"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: to-consul only" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.toK8S=false' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-k8s=false"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.toK8S=false' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-consul"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

#--------------------------------------------------------------------
# k8sPrefix

@test "syncCatalog/Deployment: no k8sPrefix by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-k8s-service-prefix"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: can specify k8sPrefix" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.k8sPrefix=foo-' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-k8s-service-prefix=\"foo-\""))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# consulPrefix

@test "syncCatalog/Deployment: no consulPrefix by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-consul-service-prefix"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: can specify consulPrefix" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.consulPrefix=foo-' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-consul-service-prefix=\"foo-\""))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# k8sTag

@test "syncCatalog/Deployment: no k8sTag flag by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-consul-k8s-tag"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: can specify k8sTag" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.k8sTag=clusterB' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-consul-k8s-tag=clusterB"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# serviceAccount

@test "syncCatalog/Deployment: serviceAccount set when sync enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.serviceAccountName | contains("sync-catalog")' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# nodePortSyncType

@test "syncCatalog/Deployment: nodePortSyncType defaults to ExternalFirst" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-node-port-sync-type=ExternalFirst"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: can set nodePortSyncType to InternalOnly" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.nodePortSyncType=InternalOnly' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-node-port-sync-type=InternalOnly"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: can set nodePortSyncType to ExternalOnly" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.nodePortSyncType=ExternalOnly' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-node-port-sync-type=ExternalOnly"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# aclSyncToken

@test "syncCatalog/Deployment: aclSyncToken disabled when secretName is missing" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.aclSyncToken.secretKey=bar' \
      . | tee /dev/stderr |
      yq '[.spec.template.spec.containers[0].env[].name] | any(contains("CONSUL_HTTP_TOKEN"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: aclSyncToken disabled when secretKey is missing" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.aclSyncToken.secretName=foo' \
      . | tee /dev/stderr |
      yq '[.spec.template.spec.containers[0].env[].name] | any(contains("CONSUL_HTTP_TOKEN"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: aclSyncToken enabled when secretName and secretKey is provided" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.aclSyncToken.secretName=foo' \
      --set 'syncCatalog.aclSyncToken.secretKey=bar' \
      . | tee /dev/stderr |
      yq '[.spec.template.spec.containers[0].env[].name] | any(contains("CONSUL_HTTP_TOKEN"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# nodeSelector

@test "syncCatalog/Deployment: nodeSelector is not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      . | tee /dev/stderr |
      yq '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "syncCatalog/Deployment: nodeSelector is not set by default with sync enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "syncCatalog/Deployment: specified nodeSelector" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.nodeSelector=testing' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "testing" ]
}

#--------------------------------------------------------------------
# global.acls.manageSystemACLs

@test "syncCatalog/Deployment: CONSUL_HTTP_TOKEN env variable created when global.acls.manageSystemACLs=true" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml \
      --set 'syncCatalog.enabled=true' \
      --set 'global.acls.manageSystemACLs=true' \
      . | tee /dev/stderr |
      yq '[.spec.template.spec.containers[0].env[].name] | any(contains("CONSUL_HTTP_TOKEN"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: init container is created when global.acls.manageSystemACLs=true" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/sync-catalog-deployment.yaml \
      --set 'syncCatalog.enabled=true' \
      --set 'global.acls.manageSystemACLs=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.initContainers[0]' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.name' | tee /dev/stderr)
  [ "${actual}" = "sync-acl-init" ]

  local actual=$(echo $object |
      yq -r '.command | any(contains("consul-k8s acl-init"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# addK8SNamespaceSuffix

@test "syncCatalog/Deployment: k8s namespace suffix enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-add-k8s-namespace-suffix"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: can set addK8SNamespaceSuffix to false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.addK8SNamespaceSuffix=false' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-add-k8s-namespace-suffix"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

#--------------------------------------------------------------------
# global.tls.enabled

@test "syncCatalog/Deployment: sets Consul environment variables when global.tls.enabled" {
  cd `chart_dir`
  local env=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'global.tls.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env[]' | tee /dev/stderr)

  local actual
  actual=$(echo $env | jq -r '. | select(.name == "CONSUL_HTTP_ADDR") | .value' | tee /dev/stderr)
  [ "${actual}" = 'https://$(HOST_IP):8501' ]

  actual=$(echo $env | jq -r '. | select(.name == "CONSUL_CACERT") | .value' | tee /dev/stderr)
    [ "${actual}" = "/consul/tls/ca/tls.crt" ]
}

@test "syncCatalog/Deployment: can overwrite CA secret with the provided one" {
  cd `chart_dir`
  local ca_cert_volume=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'global.tls.enabled=true' \
      --set 'global.tls.caCert.secretName=foo-ca-cert' \
      --set 'global.tls.caCert.secretKey=key' \
      --set 'global.tls.caKey.secretName=foo-ca-key' \
      --set 'global.tls.caKey.secretKey=key' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.volumes[] | select(.name=="consul-ca-cert")' | tee /dev/stderr)

  # check that the provided ca cert secret is attached as a volume
  local actual
  actual=$(echo $ca_cert_volume | jq -r '.secret.secretName' | tee /dev/stderr)
  [ "${actual}" = "foo-ca-cert" ]

  # check that the volume uses the provided secret key
  actual=$(echo $ca_cert_volume | jq -r '.secret.items[0].key' | tee /dev/stderr)
  [ "${actual}" = "key" ]
}

@test "syncCatalog/Deployment: consul-auto-encrypt-ca-cert volume is added when TLS with auto-encrypt is enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'global.tls.enabled=true' \
      --set 'global.tls.enableAutoEncrypt=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.volumes[] | select(.name == "consul-auto-encrypt-ca-cert") | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: consul-auto-encrypt-ca-cert volumeMount is added when TLS with auto-encrypt is enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'global.tls.enabled=true' \
      --set 'global.tls.enableAutoEncrypt=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "consul-auto-encrypt-ca-cert") | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: get-auto-encrypt-client-ca init container is created when TLS with auto-encrypt is enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'global.tls.enabled=true' \
      --set 'global.tls.enableAutoEncrypt=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.initContainers[] | select(.name == "get-auto-encrypt-client-ca") | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: adds both init containers when TLS with auto-encrypt and ACLs are enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'global.acls.manageSystemACLs=true' \
      --set 'global.tls.enabled=true' \
      --set 'global.tls.enableAutoEncrypt=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.initContainers | length == 2' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: consul-ca-cert volume is not added if externalServers.enabled=true and externalServers.useSystemRoots=true" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'global.tls.enabled=true' \
      --set 'global.tls.enableAutoEncrypt=true' \
      --set 'externalServers.enabled=true' \
      --set 'externalServers.hosts[0]=foo.com' \
      --set 'externalServers.useSystemRoots=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.volumes[] | select(.name == "consul-ca-cert")' | tee /dev/stderr)
  [ "${actual}" = "" ]
}

#--------------------------------------------------------------------
# k8sAllowNamespaces & k8sDenyNamespaces

@test "syncCatalog/Deployment: default is allow `*`, deny kube-system and kube-public" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command' | tee /dev/stderr)

  local actual=$(echo $object |
    yq 'map(select(test("allow-k8s-namespace"))) | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(echo $object |
    yq 'any(contains("allow-k8s-namespace=\"*\""))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("deny-k8s-namespace=\"kube-system\""))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("deny-k8s-namespace=\"kube-public\""))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: can set allow and deny namespaces {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.k8sAllowNamespaces[0]=allowNamespace' \
      --set 'syncCatalog.k8sDenyNamespaces[0]=denyNamespace' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command' | tee /dev/stderr)

  local actual=$(echo $object |
    yq 'map(select(test("allow-k8s-namespace"))) | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(echo $object |
    yq 'map(select(test("deny-k8s-namespace"))) | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(echo $object |
    yq 'any(contains("allow-k8s-namespace=\"allowNamespace\""))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("deny-k8s-namespace=\"denyNamespace\""))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# namespaces

@test "syncCatalog/Deployment: namespace options disabled by default" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command' | tee /dev/stderr)

  local actual=$(echo $object |
    yq 'any(contains("enable-namespaces"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(echo $object |
    yq 'any(contains("consul-destination-namespace"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(echo $object |
    yq 'any(contains("enable-k8s-namespace-mirroring"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(echo $object |
    yq 'any(contains("k8s-namespace-mirroring-prefix"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: namespace options set with .global.enableConsulNamespaces=true" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'global.enableConsulNamespaces=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command' | tee /dev/stderr)

  local actual=$(echo $object |
    yq 'any(contains("enable-namespaces=true"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("consul-destination-namespace=default"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("enable-k8s-namespace-mirroring"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(echo $object |
    yq 'any(contains("k8s-namespace-mirroring-prefix"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: mirroring options set with .syncCatalog.consulNamespaces.mirroringK8S=true" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'global.enableConsulNamespaces=true' \
      --set 'syncCatalog.consulNamespaces.mirroringK8S=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command' | tee /dev/stderr)

  local actual=$(echo $object |
    yq 'any(contains("enable-namespaces=true"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("consul-destination-namespace=default"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("enable-k8s-namespace-mirroring=true"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("k8s-namespace-mirroring-prefix"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: prefix can be set with .syncCatalog.consulNamespaces.mirroringK8SPrefix" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'global.enableConsulNamespaces=true' \
      --set 'syncCatalog.consulNamespaces.mirroringK8S=true' \
      --set 'syncCatalog.consulNamespaces.mirroringK8SPrefix=k8s-' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command' | tee /dev/stderr)

  local actual=$(echo $object |
    yq 'any(contains("enable-namespaces=true"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("consul-destination-namespace=default"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("enable-k8s-namespace-mirroring=true"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
    yq 'any(contains("k8s-namespace-mirroring-prefix=k8s-"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# namespaces + global.acls.manageSystemACLs

@test "syncCatalog/Deployment: cross namespace policy is not added when global.acls.manageSystemACLs=false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml \
      --set 'syncCatalog.enabled=true' \
      --set 'global.enableConsulNamespaces=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-consul-cross-namespace-acl-policy"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: cross namespace policy is added when global.acls.manageSystemACLs=true" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml \
      --set 'syncCatalog.enabled=true' \
      --set 'global.enableConsulNamespaces=true' \
      --set 'global.acls.manageSystemACLs=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-consul-cross-namespace-acl-policy"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# resources

@test "syncCatalog/Deployment: default resources" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq -rc '.spec.template.spec.containers[0].resources' | tee /dev/stderr)
  [ "${actual}" = '{"limits":{"cpu":"50m","memory":"50Mi"},"requests":{"cpu":"50m","memory":"50Mi"}}' ]
}

@test "syncCatalog/Deployment: can set resources" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.resources.requests.memory=100Mi' \
      --set 'syncCatalog.resources.requests.cpu=100m' \
      --set 'syncCatalog.resources.limits.memory=200Mi' \
      --set 'syncCatalog.resources.limits.cpu=200m' \
      . | tee /dev/stderr |
      yq -rc '.spec.template.spec.containers[0].resources' | tee /dev/stderr)
  [ "${actual}" = '{"limits":{"cpu":"200m","memory":"200Mi"},"requests":{"cpu":"100m","memory":"100Mi"}}' ]
}