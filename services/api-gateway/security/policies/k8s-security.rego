# policies/k8s-security.rego
package api_gateway.admission

# Deny privileged containers
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.metadata.labels.app == "api-gateway"
    input.request.object.spec.containers[_].securityContext.privileged == true
    msg := "Api Gateway service cannot run privileged containers"
}

# Deny root user
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.metadata.labels.app == "api-gateway"
    input.request.object.spec.containers[_].securityContext.runAsUser == 0
    msg := "Api Gateway service cannot run as root"
}

# Require resource limits
deny[msg] {
    input.request.kind.kind == "Deployment"
    input.request.object.metadata.labels.app == "api-gateway"
    not input.request.object.spec.template.spec.containers[_].resources.limits
    msg := "Api Gateway service must have resource limits"
}

# Require network policy
deny[msg] {
    input.request.kind.kind == "Deployment"
    input.request.object.metadata.labels.app == "api-gateway"
    not input.networkPolicy
    msg := "Api Gateway service must have network policy"
}
