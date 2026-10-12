This folder contains the Helm charts used by the EOAP dev platforms

The coder chart retains `code-server-pvc` and, when enabled, `calrissian-claim`
on Helm uninstall using `helm.sh/resource-policy: keep`. Reinstalling the same
release in the same namespace reuses those claims. User workspace files remain
on these volumes; remove the claims explicitly only when their contents can be
discarded. A retained claim keeps its existing capacity and storage class.
Module SeaweedFS data uses separate disposable storage and is not retained by
this policy.
