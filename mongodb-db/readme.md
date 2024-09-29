# Commands

## Generate a keyfile for the replica set:
```bash
openssl rand -base64 756 > mongo-keyfile
chmod 600 mongo-keyfile
```