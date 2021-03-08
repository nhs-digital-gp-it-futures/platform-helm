# How to: Run AC test suites against local cluster

## Prerequisites

- have completed basic setup steps for local cluster

## Steps

1) Checkout latest master branch the  [plaform-helm repository](https://github.com/nhs-digital-gp-it-futures/platform-helm)

2) Navigate to `/selenium-grid`

3) Run `launch-selenium-grid.sh|ps1`

4) Open the repo in the editor of your choice

5) Open `local-overrides.yaml`

6) Set `pb-ac-tests`, `mp-ac-tests` and/or `admin-ac-tests` `enabled` flag to `true` (see below)

```yaml
pb-ac-tests:
    enabled: true
```

7) Set `allure` `enabled` flag to true

8) Browse to ./src/scripts/<OS> and Run `launch-or-update-local.sh|ps1`

9) Open Allure (<https://host.docker.internal/allure-docker-service/projects/default/reports/latest/index.html> on Windows, <https://docker.for.mac.localhost/allure-docker-service/projects/default/reports/latest/index.html> on Mac)

10) When all results are in, navigate to `/selenium-grid` and run `tear-down-selenium-grid.sh|ps1`

_Note - These tests only run when the front end application sharing the same prefix (`pb`, `mp`, and `admin` are running inside the cluster)_
