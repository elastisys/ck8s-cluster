## Pipeline
The pipeline is now using a ubuntu based docker image now located at dockerhub on
[elastisys/ck8s-ops](https://hub.docker.com/r/elastisys/ck8s-ops). Each run of the
pipeline will generate its own image using the commit hash. Once a release is made
it will also tag a image with the same tag. 

The pipeline will run on pull requests to master and on push to branches named 
`Release-x`. The pipeline workflow is in `.github/workflows` and the scripts used are located in the `pipeline` directory.

## Ops image
The image built from the `Dockerfile` will have all the requirements to set up a new
cluster from scratch. This image might not have all the tools a developer might have
for debugging or working with the cluster. 

In `Dockerfile.dev` these tools can be added to provide an image better suited for developers.
This image will also be built on every release under the name `elastisys/ck8s-ops:<version>-dev`
