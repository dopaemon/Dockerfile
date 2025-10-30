```bash
docker build -t h5ai .
```
```bash
docker run -d --name h5ai --restart unless-stopped -p 80:80 -v $(pwd):/h5ai h5ai:latest
```
