#!/bin/bash
command=$1
if [[ -z "$command" ]];then
  command="/update.sh"
fi

sha=$(docker build . -q)
docker run --rm \
  -e COMPANION_GEODATE_DIRPATH=/build/geodata \
  -e COMPANION_I18N_DIRPATH=/usr/src/app/node_modules/i18n-iso-countries/langs \
  -e COMPANION_DOCKER_AUTO_RESTART=true \
  -e COMPANION_DOCKER_CONTAINER_NAME=immich \
  -e COMPANION_CRON_EXPRESSION="* * * * *" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ./i18n-iso-countries:/usr/src/app/node_modules/i18n-iso-countries/langs \
  -v ./geodata:/build/geodata \
  $sha \
  "$command"
