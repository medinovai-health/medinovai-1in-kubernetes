# policies/k8s-security.rego
package load_balancing.admission

# Deny privileged containers
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.metadata.labels.app == "load-balancing"
    input.request.object.spec.containers[_].securityContext.privileged == true
    msg := "Load Balancing service cannot run privileged containers"
}

# Deny root user
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.metadata.labels.app == "load-balancing"
    input.request.object.spec.containers[_].securityContext.runAsUser == 0
    msg := "Load Balancing service cannot run as root"
}

# Require resource limits
deny[msg] {
    input.request.kind.kind == "Deployment"
    input.request.object.metadata.labels.app == "load-balancing"
    not input.request.object.spec.template.spec.containers[_].resources.limits
    msg := "Load Balancing service must have resource limits"
}

# Require network policy
deny[msg] {
    input.request.kind.kind == "Deployment"
    input.request.object.metadata.labels.app == "load-balancing"
    not input.networkPolicy
    msg := "Load Balancing service must have network policy"
}
