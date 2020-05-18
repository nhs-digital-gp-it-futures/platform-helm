#!/bin/bash
namespace="buyingcatalogue-master"
basePath="$namespace.dev.buyingcatalogue.digital.nhs.uk"
baseUrl="https://$basePath"
baseIdentityUrl="$baseUrl/identity"

helm upgrade bc gpitfuturesdevacr/buyingcatalogue -n $namespace -i -f environments/azure.yaml --debug \
  --set dbPassword=DisruptTheMarket1! \
  --set clientSecret=SampleClientSecret \
  --set appBaseUrl=$baseUrl \
  --set baseIsapiEnabledUrl=$baseIdentityUrl \
  --set isapi.clients[0].redirectUrls[0]=$baseUrl/oauth/callback \
  --set isapi.clients[0].redirectUrls[1]=$baseUrl/admin/oauth/callback \
  --set isapi.clients[0].redirectUrls[2]=$baseUrl/order/oauth/callback \
  --set isapi.clients[0].postLogoutRedirectUrls[0]=$baseUrl/signout-callback-oidc \
  --set isapi.clients[0].postLogoutRedirectUrls[1]=$baseUrl/admin/signout-callback-oidc \
  --set isapi.clients[0].postLogoutRedirectUrls[2]=$baseUrl/order/signout-callback-oidc \
  --set isapi.ingress.hosts[0].host=$basePath \
  --set email.ingress.hosts[0].host=$basePath \
  --set mp.ingress.hosts[0].host=$basePath \
  --set pb.ingress.hosts[0].host=$basePath \
  --set pb.baseUri=$baseUrl \
  --set admin.ingress.hosts[0].host=$basePath \
  --set of.ingress.hosts[0].host=$basePath \
  --set redis-commander.ingress.hosts[0].host=$basePath \