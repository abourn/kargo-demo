# Kargo Demo

This repository is a fork of https://github.com/akuity/kargo-demo and was made following the Kargo Quickstart guide: https://docs.kargo.io/quickstart

## Setup

As a demonstration environment, this repository followed the quickstart guide for Kind clusters.

For being able to conveniently spin up and tear down the environment, a [kind-install.sh](./kind-install.sh) script is included, which is a slightly modified version of the installation script that the Kargo Quickstart provides.  In particular, it creates the ApplicationSet and Kargo resources that are created manually during the quickstart guide. It also assumes that you have set `GITOPS_REPO_URL`, `GITHUB_USERNAME`, and `GITHUB_PAT` in your environment.  It is suggested you store these locally in a envfile such as `kargo.env`.

## Rendered Manifests Pattern

Besides the basic Kargo example provided from the upstream repository, this repository includes an example of the [rendered manifests](https://akuity.io/blog/the-rendered-manifests-pattern) pattern under the [fully-rendered](./fully-rendered/) directory.

To deploy this example, first create the ApplicationSet at [`./fully-rendered/ApplicationSet.yaml`](fully-rendered/ApplicationSet.yaml).  This will create two Applications representing two different environment deployments of the "guestbook" application. At first, ArgoCD will not be able to sync these Applications, as the `targetRevision` points to stage branches that Kargo will create.

Then, you'll deploy the Kargo resources to implement a promotion pipeline for the Deployment's image tag. These resources can be deployed with the [`./fully-rendered/kargo.sh`](./fully-rendered/kargo.sh) script. These resources are applied with a script in order to substitute environment variables into the manifests. This script assumes that you have `GITOPS_REPO_URL`, `GITHUB_USERNAME`, and `GITHUB_PAT` set in your environment.

Once the ApplicationSet and Kargo resources are deployed, you can begin promoting the image `Freight` to the various `Stages` (`staging` and `production`).

The `PromotionTask` for this example is centered around the `helm-template` promotion step.  In particular, this step takes the updated `Freight` from the `Warehouse` for the gb-frontend image and inflates the [`./fully-rendered/charts/helm-guestbook`](./fully-rendered/charts/helm-guestbook) Helm Chart with the `image.tag` value set to the `Freight`/image tag being promoted.  The `PromotionTask` then commits the rendered manifests to GitHub on the staging branch and triggers a sync of the corresponding ArgoCD Application.

## Teardown

All that is needed to cleanup is to teardown the Kind cluster:

```bash
kind delete cluster --name kargo-quickstart
```