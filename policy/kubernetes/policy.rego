package kubernetes.baseline

deny[msg] {
  some i
  container := input[i].spec.template.spec.containers[_]
  not container.securityContext.runAsNonRoot
  msg := sprintf("Container %v must runAsNonRoot", [container.name])
}

deny[msg] {
  some i
  container := input[i].spec.template.spec.containers[_]
  not container.securityContext.readOnlyRootFilesystem
  msg := sprintf("Container %v must use readOnlyRootFilesystem", [container.name])
}

deny[msg] {
  some i
  container := input[i].spec.template.spec.containers[_]
  not container.resources.limits
  msg := sprintf("Container %v must set resource limits", [container.name])
}

warn[msg] {
  some i
  container := input[i].spec.template.spec.containers[_]
  not container.livenessProbe
  msg := sprintf("Container %v is missing livenessProbe (warning)", [container.name])
}
