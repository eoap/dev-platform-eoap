#!/bin/bash
set -e

echo "🧹 Complete cluster cleanup..."

# 1. Stop skaffold if running
echo "⏹️  Stopping skaffold..."
pkill -f "skaffold dev" || true
sleep 2

# 2. Remove Helm releases (without waiting)
echo "🗑️  Removing Helm releases..."
helm uninstall zoo-project-dru -n eoap-zoo-project --no-hooks --timeout 10s 2>/dev/null || true
helm uninstall eoap-zoo-project-coder -n eoap-zoo-project --no-hooks --timeout 10s 2>/dev/null || true
helm uninstall eoap-zoo-project-localstack -n eoap-zoo-project --no-hooks --timeout 10s 2>/dev/null || true
helm uninstall kyverno -n kyverno-system --no-hooks --timeout 10s 2>/dev/null || true

# 3. Remove Kyverno webhooks
echo "🔌 Remove Kyverno webhooks..."
kubectl delete validatingwebhookconfigurations -l app.kubernetes.io/part-of=kyverno --ignore-not-found --wait=false || true
kubectl delete mutatingwebhookconfigurations -l app.kubernetes.io/part-of=kyverno --ignore-not-found --wait=false || true

# 4. Remove residual KEDA resources
echo "🧽 Removing residual KEDA resources..."
for r in $(kubectl get scaledobjects.keda.sh -A -o name 2>/dev/null); do
  kubectl patch "$r" --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
  kubectl delete "$r" --wait=false 2>/dev/null || true
done

for r in $(kubectl get triggerauthentications.keda.sh -A -o name 2>/dev/null); do
  kubectl patch "$r" --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
  kubectl delete "$r" --wait=false 2>/dev/null || true
done

# 4b. Remove residual Argo Workflows resources
echo "🧽 Removing residual Argo Workflows resources..."
for r in $(kubectl get workflows.argoproj.io -A -o name 2>/dev/null); do
  kubectl patch "$r" --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
  kubectl delete "$r" --wait=false 2>/dev/null || true
done

for r in $(kubectl get workflowtemplates.argoproj.io -A -o name 2>/dev/null); do
  kubectl patch "$r" --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
  kubectl delete "$r" --wait=false 2>/dev/null || true
done

for r in $(kubectl get cronworkflows.argoproj.io -A -o name 2>/dev/null); do
  kubectl patch "$r" --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
  kubectl delete "$r" --wait=false 2>/dev/null || true
done

# 5. Remove CRDs with finalizers
echo "🗂️  Removing KEDA, Kyverno, and Argo CRDs..."

# First remove the resource-policy annotation that prevents deletion
for crd in workflows.argoproj.io workflowtemplates.argoproj.io cronworkflows.argoproj.io clusterworkflowtemplates.argoproj.io workfloweventbindings.argoproj.io workflowartifactgctasks.argoproj.io workflowtasksets.argoproj.io workflowtaskresults.argoproj.io; do
  if kubectl get crd "$crd" >/dev/null 2>&1; then
    kubectl annotate crd "$crd" helm.sh/resource-policy- 2>/dev/null || true
    kubectl patch crd "$crd" --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || true
    kubectl delete crd "$crd" --ignore-not-found 2>/dev/null || true
  fi
done

for c in $(kubectl get crd -o name 2>/dev/null | grep -E 'keda.sh|kyverno.io'); do
  kubectl patch "$c" --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || true
  kubectl delete "$c" --wait=false 2>/dev/null || true
done

sleep 3

# 6. Remove pods and PVCs
echo "💾 Removing pods and PVCs..."
kubectl delete pods -n eoap-zoo-project --all --force --grace-period=0 2>/dev/null || true
sleep 2

# Remove PVCs with finalizers
for pvc in $(kubectl get pvc -n eoap-zoo-project -o name 2>/dev/null); do
  kubectl patch -n eoap-zoo-project "$pvc" --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || true
  kubectl delete -n eoap-zoo-project "$pvc" --wait=false 2>/dev/null || true
done

sleep 2

# Remove ALL PVs (not just those with eoap-zoo-project in the name)
for pv in $(kubectl get pv -o name 2>/dev/null); do
  kubectl patch "$pv" --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || true
  kubectl delete "$pv" --wait=false 2>/dev/null || true
done

# 7. Remove namespaces
echo "🗑️  Removing namespaces..."
kubectl delete ns eoap-zoo-project --wait=false 2>/dev/null || true
kubectl delete ns kyverno-system --wait=false 2>/dev/null || true

# 8. Force finalization of stuck namespaces
echo "⚡ Forcing finalization of namespaces..."
for ns in eoap-zoo-project kyverno-system; do
  if kubectl get ns "$ns" >/dev/null 2>&1; then
    kubectl get ns "$ns" -o json | jq '.spec.finalizers=[]' | kubectl replace --raw "/api/v1/namespaces/$ns/finalize" -f - 2>/dev/null || true
  fi
done

# 9. Wait for everything to be cleaned up
echo "⏳ Waiting for complete cleanup..."
sleep 10

# 10. Check final status
echo "✅ Checking cluster status..."
echo ""
echo "Remaining namespaces:"
kubectl get ns | grep -E 'kyverno-system|eoap-zoo-project' || echo "  ✓ Namespaces cleaned up"

echo ""
echo "Remaining CRDs:"
kubectl get crd 2>/dev/null | grep -E 'keda.sh|kyverno.io|argoproj.io' || echo "  ✓ CRDs cleaned up"
echo ""
echo "Remaining PVs:"
kubectl get pv 2>/dev/null || echo "  ✓ No PVs"

echo ""
echo "✨ Cleanup complete!"
echo ""
echo "To deploy, run:"
echo "  skaffold dev -p keda"
