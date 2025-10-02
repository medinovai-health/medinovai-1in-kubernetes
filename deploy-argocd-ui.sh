#!/bin/bash
# Deploy ArgoCD UI for Infrastructure Management

set -e

echo "🚀 Deploying ArgoCD GitOps UI for Infrastructure Management..."

# Create argocd namespace
echo "📦 Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "📦 Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods to be ready
echo "⏳ Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get initial admin password
echo "🔐 Getting initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Patch ArgoCD service to use NodePort for easy access
echo "🌐 Configuring ArgoCD service for local access..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# Get the NodePort
ARGOCD_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

# Setup port-forward in background for localhost access
echo "🌐 Setting up port-forward for easy access..."
kubectl port-forward svc/argocd-server -n argocd 8888:443 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!

echo ""
echo "✅ ArgoCD Deployment Complete!"
echo ""
echo "🌐 Access ArgoCD UI:"
echo "   URL: https://localhost:8888"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "⚠️  Accept the self-signed certificate warning in your browser"
echo ""
echo "📊 ArgoCD will provide:"
echo "   - GitOps deployment visualization"
echo "   - Application sync status"
echo "   - Resource health monitoring"
echo "   - Deployment history"
echo "   - Configuration management"
echo ""
echo "🔄 Port-forward PID: $PORT_FORWARD_PID"
echo "   (Stop with: kill $PORT_FORWARD_PID)"
echo ""

# Save credentials
cat > /tmp/argocd-credentials.txt <<EOF
ArgoCD GitOps UI Access
========================
URL: https://localhost:8888
Username: admin
Password: $ARGOCD_PASSWORD

Alternative Access (NodePort):
URL: https://localhost:$ARGOCD_PORT
Username: admin
Password: $ARGOCD_PASSWORD

Port-forward PID: $PORT_FORWARD_PID
Stop with: kill $PORT_FORWARD_PID

Restart port-forward:
kubectl port-forward svc/argocd-server -n argocd 8888:443 &

Access via CLI:
argocd login localhost:8888 --username admin --password $ARGOCD_PASSWORD --insecure
EOF

echo "💾 Credentials saved to: /tmp/argocd-credentials.txt"
echo ""
echo "🎉 ArgoCD is ready! Open https://localhost:8888 in your browser!"

