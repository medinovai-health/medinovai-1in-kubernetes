# policies/k8s-security.rego
package service_mesh.admission

# Deny privileged containers
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.metadata.labels.app == "service-mesh"
    input.request.object.spec.containers[_].securityContext.privileged == true
    msg := "Service Mesh service cannot run privileged containers"
}

# Deny root user
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.metadata.labels.app == "service-mesh"
    input.request.object.spec.containers[_].securityContext.runAsUser == 0
    msg := "Service Mesh service cannot run as root"
}

# Require resource limits
deny[msg] {
    input.request.kind.kind == "Deployment"
    input.request.object.metadata.labels.app == "service-mesh"
    not input.request.object.spec.template.spec.containers[_].resources.limits
    msg := "Service Mesh service must have resource limits"
}

# Require network policy
deny[msg] {
    input.request.kind.kind == "Deployment"
    input.request.object.metadata.labels.app == "service-mesh"
    not input.networkPolicy
    msg := "Service Mesh service must have network policy"
}
