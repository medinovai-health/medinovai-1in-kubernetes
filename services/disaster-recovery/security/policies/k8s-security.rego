# policies/k8s-security.rego
package disaster_recovery.admission

# Deny privileged containers
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.metadata.labels.app == "disaster-recovery"
    input.request.object.spec.containers[_].securityContext.privileged == true
    msg := "Disaster Recovery service cannot run privileged containers"
}

# Deny root user
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.metadata.labels.app == "disaster-recovery"
    input.request.object.spec.containers[_].securityContext.runAsUser == 0
    msg := "Disaster Recovery service cannot run as root"
}

# Require resource limits
deny[msg] {
    input.request.kind.kind == "Deployment"
    input.request.object.metadata.labels.app == "disaster-recovery"
    not input.request.object.spec.template.spec.containers[_].resources.limits
    msg := "Disaster Recovery service must have resource limits"
}

# Require network policy
deny[msg] {
    input.request.kind.kind == "Deployment"
    input.request.object.metadata.labels.app == "disaster-recovery"
    not input.networkPolicy
    msg := "Disaster Recovery service must have network policy"
}
