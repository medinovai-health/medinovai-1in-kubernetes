path "medinovai-secrets/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/health" {
  capabilities = ["read"]
}

path "sys/policies/acl/*" {
  capabilities = ["read", "list"]
}

path "auth/*" {
  capabilities = ["read", "list"]
}
