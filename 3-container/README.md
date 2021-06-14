# Docker image Scanning

```bash
trivy nginx:latest
trivy nginx:alpine

docker build -t nginx:demo .

trivy nginx:demo

docker run -it --rm nginx:latest whoami
docker run -it --rm nginxinc/nginx-unprivileged:stable-alpine whoami
```
