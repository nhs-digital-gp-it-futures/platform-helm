# Buying Catalogue Helm Charts

This directory contains helm charts for the buying catalogue.

The buying catalogue umbrella chart represents a version of the entire system. It can easily be run locally to aid development, and is also used to deploy to the cloud. It aggregates the different charts used for each component, providing the ability to configure for the different environments.

To work with the cluster in development, follow the instructions [here](docs/run-local.md). Once all of the tasks have been completed the URL to access the local cluster is [host.docker.internal](https://host.docker.internal/).

Branches of this repository are automatically deployed to the dev environment in azure.
Each change of this repository is considered a new release, which can then be released via the release pipeline to test and then production. Instructions on how to work with the cluster in cloud can be found [here](docs/run-azure.md).

The build pipeline creates a dynamic environment for each branch with the prefix 'feature/', this can then be elevated to test any changes made in PRs, but also to allow for [BA horns on dynamic environments](docs/dynamic-env-ba-horn.md) in the cloud. 

The APIs in dev environment expose Swagger interface, to access it, please follow these [instructions](docs/port-forwarding-to-cloud-env.md).

On deployment in the cloud environments, the AC tests are automatically run against the system. Find more information [here](docs/selenium-grid.md)

To see the results of these tests, have a look at the [Allure Dashboard](https://host.docker.internal/allure-docker-service/projects/default/reports/latest/index.html).

## Configuration overview

|                             Service                                                                           |       Port        |                           Ingress                           |
| :-----------------------------------------------------------------------------------------------------------: | :---------------: | :---------------------------------------------------------: |
|              [BAPI](http://localhost:5100/swagger)                                                            |       5100        |                                                             |
|                               DB                                                                              |       1450        |                                                             |
|              [DAPI](http://localhost:5101/swagger)                                                            |       5101        |                                                             |
|                             AZURITE                                                                           | 10000,10001,10002 |                                                             |
|              [ISAPI](http://localhost:5102/swagger)                                                           |       5102        |             [ISAPI](https://host.docker.internal/identity)              |
|                   [OAPI](http://localhost:5103)                                                               |       5103        |                                                             |
|                  [ORDAPI](http://localhost:5104)                                                              |       5104        |                                                             |
| [MP](http://localhost:3002/supplier/solution/100000-001/preview)                                              |       3002        | [MP](https://host.docker.internal/supplier/solution/100000-001/preview) |
|                   [PB](http://localhost:3000)                                                                 |       3000        |                   [PB](https://host.docker.internal)                    |
|                 [ADMIN](http://localhost:3005)                                                                |       3005        |              [ADMIN](https://host.docker.internal/admin)                |
|                   [OF](http://localhost:3006)                                                                 |       3006        |                 [OF](https://host.docker.internal/order)                |
|                  [EMAIL](http://localhost:1080)                                                               |      1080,587     |          [EMAIL](https://host.docker.internal/email)        |
|                             REDIS                                                                             |       6379        |                                                             |
|             [REDIS COMMANDER](http://localhost:8181)                                                          |       8181        |                                                             |
|             [ALLURE](http://localhost:5050/allure-docker-service/projects/default/reports/latest/index.html)  |       5050        | [ALLURE](https://host.docker.internal/allure-docker-service/projects/default/reports/latest/index.html) |
