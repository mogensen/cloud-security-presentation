# Terraform code scanning

```bash
tfsec

docker run -v $(pwd):/data accurics/terrascan scan -d /data
```
