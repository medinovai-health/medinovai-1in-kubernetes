# Configuration Files
Generated: Fri Sep 26 08:23:20 EDT 2025

## Docker Configuration
```
{
  "auths": {},
  "credsStore": "osxkeychain",
  "experimental": false,
  "features": {
    "buildkit": true
  },
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "proxies": {
    "default": {
      "httpProxy": "",
      "httpsProxy": "",
      "noProxy": ""
    }
  }
}
```

## Kubernetes Configuration
```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://127.0.0.1:26443
  name: orbstack
contexts:
- context:
    cluster: orbstack
    user: orbstack
  name: orbstack
current-context: orbstack
kind: Config
preferences: {}
users:
- name: orbstack
  user:
    client-certificate-data: DATA+OMITTED
    client-key-data: DATA+OMITTED
```

## Shell Configuration
```
export OLLAMA_MODELS="/Users/dev1/ollama-models-2tb"
```

## Homebrew Installed Packages
```
helm
istioctl
k3d
ollama
```
