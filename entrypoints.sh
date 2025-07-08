#!/bin/bash
# This file is part of immich-geodata-cn-companion.
#
# immich-geodata-cn-companion is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  immich-geodata-cn-companion is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with immich-geodata-cn-companion. If not, see <https://www.gnu.org/licenses/>.

set -u

if [[ ! -d /etc/cron ]]; then
    mkdir -p /etc/cron
fi

if [[ ! -z $COMPONION_CRON_EXPRESSION ]]; then
    echo "COMPONION_CRON_EXPRESSION is not set, using default value: '0 0 * * *'"
    COMPONION_CRON_EXPRESSION="0 0 * * *"
fi

cat <<EOF >/etc/cron/crontab
$COMPONION_CRON_EXPRESSION bash /update.sh
# empty line
EOF

crontab /etc/cron/crontab
crond -f
