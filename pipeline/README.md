## Pipeline
The pipeline is now using a ubuntu based docker image now located at dockerhub on
`vanneback/exoscale-pipeline`. 

The pipeline first executes an init script `init.sh`. This scripts sets all the variables
needed. The script should not need to be altered and all the variables can be changed from
bitbucket https://bitbucket.org/elastisys/a1-demo/admin/addon/admin/pipelines/repository-variables.

The rest of the pipeline can be altered from the file `bitbucket-pipelines.yml`. the line `pull-requests`
defines when the pipeline should run. Now it is configured to run when something is merged to the master branch.
This definition can be replaced to allow the pipeline to run on other condintions. See https://confluence.atlassian.com/bitbucket/configure-bitbucket-pipelines-yml-792298910.html.

## Dockerfile
The docker image now has the following dependecies.

* Terraform (with the exoscale plugin)
* RKE cli
* Kubectl cli
* helm (with the helm diff plugin)
* helmfile

If any other dependencies are inserted in the project they will need to be added to the Dockerfile
and the image will need to be rebuilt.

## TODO
simply remove the comment on the `deploy-ss/c.sh` line.
* Rebuild image to another location which is not a user specific public registry.
* Add checks that the cluster is actually functioning correctly, not just installed.
