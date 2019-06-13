## Harbor
Install by running script deploy-harbor.

Initial login when starting harbor is `username=admin` `password=Harbor12345` this should
be changed in the gui when first deployed.

## TODO
* Missing persistent storage and auth. 
* Using untrusted cert for registries and ingress. This causes the cluster to not
be able to pull image.


## Pushing a image to the registry.
1. Create registry from gui. 
2. Download certificate from gui in the registry tab.
3. `mv ca.crt /etc/docker/core.harbor.demo.compliantk8s.com/ca.crt`
4. `docker login`
5. `docker tag <image> core.harbor.demo.compliantk8s.com/<REGISTRY_NAME>/<IMAGE>[:tag]`
6. `docker push core.harbor.demo.compliantk8s.com/<REGISTRY_NAME>/<IMAGE>[:tag]`
