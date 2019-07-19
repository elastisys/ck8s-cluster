FROM node:alpine as react-build
USER node
RUN mkdir -p /home/node/app
WORKDIR /home/node/app
copy . /home/node/app
RUN npm install
expose 3001
CMD ["node", "server.js"]
