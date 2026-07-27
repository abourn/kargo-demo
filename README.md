# Kargo Demo

This repository is a fork of https://github.com/akuity/kargo-demo and was made following the Kargo Quickstart guide: https://docs.kargo.io/quickstart

## Setup

As a demonstration environment, this repository followed the quickstart guide for Kind clusters.

For being able to conveniently spin up and tear down the environment, a [kind-install.sh](./kind-install.sh) script is included, which is a slightly modified version of the installation script that the Kargo Quickstart provides.  In particular, it creates the ApplicationSet and Kargo resources that are created manually during the quickstart guide. It also assumes that you have set `GITOPS_REPO_URL`, `GITHUB_USERNAME`, and `GITHUB_PAT` in your environment.  It is suggested you store these locally in a envfile such as `kargo.env`.

## Teardown

All that is needed to cleanup is to teardown the Kind cluster:

```bash
kind delete cluster --name kargo-quickstart
```