#!/bin/bash

cd /opt/app-root/src/frontend

# TODO remove this workaround for
#
#   ERROR in Missing binding /opt/app-root/src/frontend/node_modules/node-sass/vendor/linux-x64-46/binding.node
#   Node Sass could not find a binding for your current environment: Linux 64-bit with Node.js 4.x
#
# When running webpack
scl enable rh-nodejs4 'npm rebuild node-sass'

scl enable rh-nodejs4 'npm run build:prod:ci'

ls -al

cd /opt/app-root/src

mkdir -p public
mv frontend/dist/* public