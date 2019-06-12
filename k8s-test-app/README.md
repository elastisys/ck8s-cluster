# k8s-test-app

A simple test application for kubernetes.

## Quick start kubernetes
Prereq helm installed in kubernetes cluster.

`helm install --name test-app-chart`


## Quick start locally

Prereq:

The default npm version in ubuntu is quite old and does not work well with react-scripts.
You can use nvm to easily handle node versions: https://github.com/creationix/nvm
Install it with `curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash`
and then install the latest node version: `nvm install node`.
At this point, you may have to start a new terminal or log out and in again to get the correct version.


1. Install node modules in `client` and `backend`: `npm install`
2. Start database in container: `docker run --rm -p 27017:27017 mongo`
3. Start backend: `node server.js`
4. Start frontend: `npm start`

To build an optimized version of the (static) frontend, run `npm run build`.

