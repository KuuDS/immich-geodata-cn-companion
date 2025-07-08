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

set -e

if [[ ! -d /etc/cron ]]; then
    echo "Creating /etc/cron directory as it does not exist"
    mkdir -p /etc/cron
fi

if [[ -z $COMPANION_CRON_EXPRESSION ]]; then
    echo "COMPANION_CRON_EXPRESSION is not set, using default value: '0 5 * * *'"
    COMPANION_CRON_EXPRESSION="0 5 * * *"
fi

cat <<EOF >/etc/cron/crontab
$COMPANION_CRON_EXPRESSION /update.sh
# empty line
EOF

echo "Setting up cron job with expression: $COMPANION_CRON_EXPRESSION"
crontab /etc/cron/crontab
echo "Crond is running"
crond -f
