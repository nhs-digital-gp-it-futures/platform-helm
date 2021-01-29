# Selenium grid

This repository contains directory [selenium-grid](../selenium-grid) which hosts scripts to launch the selenium grid.

By default, [the script](../selenium-grid/launch-selenium-grid.sh) installs the [selenium grid helm chart](https://github.com/helm/charts/tree/master/stable/selenium) in 'selenium-grid' namespace, which will then contain 5 pods - 1x hub and 4x chrome node. This can be customised, for more info on how to, please run the script with the -h or --help flag `launch-selenium-grid.sh --help`

**NOTE** in order for things to work as intended, please run the script from within the [selenium-grid](../selenium-grid) directory.

The selenium grid is then used to run:

- [Public Browse AC tests](https://github.com/nhs-digital-gp-it-futures/PublicBrowseAcceptanceTests)
- [Marketing Page AC tests](https://github.com/nhs-digital-gp-it-futures/MarketingPageAcceptanceTests)
- [Admin AC tests](https://github.com/nhs-digital-gp-it-futures/AdminAcceptanceTests)
- [Order form AC tests](https://github.com/nhs-digital-gp-it-futures/OrderFormAcceptanceTests)

as jobs in the AKS (dev | test) cluster

## Running AC tests locally

---

The AC tests are not enabled to run locally by default. If you wish to run the AC tests against your local dev cluster, you'll need to launch the selenium grid and enable the tests

### Setting the grid up

from the root of this repository:

`cd selenium-grid && ./launch-selenium-grid.sh | ps1`

**NOTE** this only needs to be done once.

If you wish to stop the selenium grid, run `kubectl delete ns selenium-grid`

### Enabling the tests

in local-overrides.yaml, set the *-ac-tests.enabled to `true`:

*enabling the public browse ac tests*

```yaml
pb-ac-tests:
  enabled: true
```

## DNS work-around

---

Due to the fact that our dynamically created environments are not added to any domain registrar, we have to manually maintain the grid's DNS records by using Kubernetes [hostAliases](https://kubernetes.io/docs/concepts/services-networking/add-entries-to-pod-etc-hosts-with-host-aliases/#adding-additional-entries-with-hostaliases). Every time we create a new environment agaisnt which we intend to run the tests, we need to add a new entry to the /etc/hosts file in our chrome nodes, in order to reach them. This is done using the -a | --add option on the launch script. As that will append the given hostname to the list of hostAliases for all the nodes.

**NOTE** This part of the script can be scrapped once the DNS issues are resolved.