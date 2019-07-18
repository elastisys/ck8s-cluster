#!/bin/sh
if [ -z $BACKEND_NAMESPACE ]; then
  export BACKEND_NAMESPACE="default"
fi

if [ -z $BACKEND_SERVICE ]; then
  export BACKEND_SERVICE="sample-backend"
fi
echo "namespace = $BACKEND_NAMESPACE"
echo "service = $BACKEND_SERVICE"

envsubst '\$BACKEND_SERVICE \$BACKEND_NAMESPACE' < nginx.template > /etc/nginx/conf.d/default.conf
echo "$(cat /etc/nginx/conf.d/default.conf)"
nginx -g "daemon off;"
