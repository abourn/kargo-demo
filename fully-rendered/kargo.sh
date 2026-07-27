cat <<EOF | kubectl apply -f -
apiVersion: kargo.akuity.io/v1alpha1
kind: Project
metadata:
  name: fully-rendered
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: kargo-demo-repo
  namespace: fully-rendered
  labels:
    kargo.akuity.io/cred-type: git
stringData:
  repoURL: ${GITOPS_REPO_URL}
  username: ${GITHUB_USERNAME}
  password: ${GITHUB_PAT}
---
apiVersion: kargo.akuity.io/v1alpha1
kind: Warehouse
metadata:
  name: fully-rendered
  namespace: fully-rendered
spec:
  subscriptions:
  - image:
      repoURL: gcr.io/google-samples/gb-frontend
      imageSelectionStrategy: Lexical
      discoveryLimit: 5
---
apiVersion: kargo.akuity.io/v1alpha1
kind: PromotionTask
metadata:
  name: fully-rendered-promo-process
  namespace: fully-rendered
spec:
  vars:
  - name: gitopsRepo
    value: ${GITOPS_REPO_URL}
  - name: imageRepo
    value: gcr.io/google-samples/gb-frontend
  steps:
  - uses: git-clone
    config:
      repoURL: \${{ vars.gitopsRepo }}
      checkout:
      - branch: main
        path: ./src
      - branch: stage/\${{ ctx.stage }}
        create: true
        path: ./out
  - uses: git-clear
    config:
      path: ./out  
  - uses: helm-template
    config:
      path: ./src/fully-rendered/charts/helm-guestbook
      outPath: ./out/fully-rendered/manifests      
      releaseName: guestbook-\${{ ctx.stage }}
      useReleaseName: true
      setValues:
        - key: image.tag
          value: \${{ imageFrom(vars.imageRepo).Tag }} 
  - uses: git-commit
    as: commit
    config:
      path: ./out
      message: "Update image to \${{ imageFrom(vars.imageRepo).Tag }}"
  - uses: git-push
    config:
      path: ./out
  - uses: argocd-update
    config:
      apps:
      - name: guestbook-\${{ ctx.stage }}
        sources:
        - repoURL: \${{ vars.gitopsRepo }}
          desiredRevision: \${{ task.outputs.commit.commit }}
---
apiVersion: kargo.akuity.io/v1alpha1
kind: Stage
metadata:
  name: dev
  namespace: fully-rendered
spec:
  requestedFreight:
  - origin:
      kind: Warehouse
      name: fully-rendered
    sources:
      direct: true
  promotionTemplate:
    spec:
      steps:
      - task:
          name: fully-rendered-promo-process
        as: promo-process
---
apiVersion: kargo.akuity.io/v1alpha1
kind: Stage
metadata:
  name: critical
  namespace: fully-rendered
spec:
  requestedFreight:
  - origin:
      kind: Warehouse
      name: fully-rendered
    sources:
      stages:
      - dev
  promotionTemplate:
    spec:
      steps:
      - task:
          name: fully-rendered-promo-process
        as: promo-process
EOF