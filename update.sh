#!/bin/bash
###################################
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
#
# Environment Variables:
#   COMPANION_DEBUG: Enable debug mode (ANY VALUE, default: not set)
#   COMPANION_GHPROXY_PREFIX: Prefix for GHPROXY. this will works on all HTTP requests with Github (default: )
#   COMPANION_RELEASE_API: API URL to fetch the latest release information (default: https://api.github.com/repos/ZingLix/immich-geodata-cn/releases/latest)
#   COMPANION_GEODATE_DIRPATH: Directory path for geodata (required)
#   COMPANION_I18N_DIRPATH: Directory path for i18n (required)
#   COMPANION_GEODATE_ASSET_NAME: Name of the geodata asset (default: geodata.zip)
#   COMPANION_I18N_ASSET_NAME: Name of the i18n asset (default: i18n-iso-countries.zip)
#   COMPANION_PERMISSION_FIX: Enable permission fix (true/false, default: )
#   COMPANION_UID: User ID for file ownership (default: 1000)
#   COMPANION_GID: Group ID for file ownership (default: 1000)
#   COMPANION_PERMISSION_MASK: Permission mask for files (default: 640)
#   COMPANION_DOCKER_AUTO_RESTART: Enable Docker auto restart (true/false, default: false)
#   COMPANION_DOCKER_CONTAINER_NAME: Name of the Docker container to restart if updates are found (required if COMPANION_DOCKER_AUTO_RESTART is true, default: immich)
#   COMPANION_DOCKER_API: Docker API socket path (default: /var/run/docker.sock)
#
###################################

if [[ -z "$COMPANION_DEBUG" ]]; then
    set -e
fi

WORK_DIR=/work

###################################

# check COMPANION_RELEASE_API
if [[ -z "$COMPANION_RELEASE_API" ]]; then COMPANION_RELEASE_API="https://api.github.com/repos/ZingLix/immich-geodata-cn/releases/latest"; fi

# check COMPANION_GEODATE_DIRPATH
if [[ -z "$COMPANION_GEODATE_DIRPATH" ]]; then
    echo "COMPANION_GEODATE_DIRPATH is not set"
    exit 1
fi

if [[ ! -d "$COMPANION_GEODATE_DIRPATH" ]]; then
    echo "Error: I18N directory does not exist at $COMPANION_GEODATE_DIRPATH"
    exit 1
fi

# check COMPANION_I18N_DIRPATH
if [[ -z "$COMPANION_I18N_DIRPATH" ]]; then
    echo "Error: COMPANION_I18N_DIRPATH is not set"
    exit 1
fi

if [[ ! -d "$COMPANION_I18N_DIRPATH" ]]; then
    echo "Error: I18N directory does not exist at $COMPANION_I18N_DIRPATH"
    exit 1
fi

# check COMPANION_GHPROXY_PREFIX, if set and postfix with slash, remove the slash
if [[ -n "$COMPANION_GHPROXY_PREFIX" ]]; then
    if [[ "$COMPANION_GHPROXY_PREFIX" =~ /$ ]]; then
        COMPANION_GHPROXY_PREFIX="${COMPANION_GHPROXY_PREFIX%/}"
    fi
else
    COMPANION_GHPROXY_PREFIX=""
fi

# check COMPANION_UID
if [[ -z "$COMPANION_UID" ]]; then
    COMPANION_UID=1000
fi

# check COMPANION_GID
if [[ -z "$COMPANION_GID" ]]; then
    COMPANION_GID=1000
fi

# check COMPANION_PERMISSION_MASK
if [[ -z "$COMPANION_PERMISSION_MASK" ]]; then
    COMPANION_PERMISSION_MASK="640"
fi

# check COMPANION_GEODATE_ASSET_NAME
if [[ -z "$COMPANION_GEODATE_ASSET_NAME" ]]; then
    COMPANION_GEODATE_ASSET_NAME="geodata.zip"
fi

# check COMPANION_I18N_ASSET_NAME
if [[ -z "$COMPANION_I18N_ASSET_NAME" ]]; then
    COMPANION_I18N_ASSET_NAME="i18n-iso-countries.zip"
fi

# check Docker Restart Env
if [[ "$COMPANION_DOCKER_AUTO_RESTART" == "true" ]]; then
    COMPANION_DOCKER_AUTO_RESTART=0
    if [[ -z "$COMPANION_DOCKER_CONTAINER_NAME" ]]; then
        COMPANION_DOCKER_CONTAINER_NAME="immich"
    fi
    if [[ -z "$COMPANION_DOCKER_API" ]]; then
        COMPANION_DOCKER_API="/var/run/docker.sock"
    fi
else
    COMPANION_DOCKER_AUTO_RESTART=1
fi

# clean up work directory
if [[ -d "$WORK_DIR" ]]; then
    echo "Work directory $WORK_DIR already exists."
    rm -rf "$WORK_DIR/*"
else
    echo "Creating work directory $WORK_DIR"
    mkdir -p "$WORK_DIR"
fi

# download release information from COMPANION_RELEASE_API

release_api_url="$COMPANION_RELEASE_API"
if [[ "$release_api_url" =~ ^https?://github\.com && -n "$COMPANION_GHPROXY_PREFIX" ]]; then
    api_url="$COMPANION_GHPROXY_PREFIX/$api_url"
    echo "Using GHPROXY: $release_api_url"
fi
release_file="$WORK_DIR/release.json"
resp=$(curl -s $release_api_url -o "$release_file" -w "%{http_code}")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to fetch release information from $COMPANION_RELEASE_API"
    exit 1
fi

release_id=$(cat "$release_file" | jq -r '.id')

# if release_id is null or empty, exit
if [[ -z "$release_id" || "$release_id" == "null" ]]; then
    echo "Error: No valid release found in the response."
fi

# update GEODATE
geodata_asset_name="$COMPANION_GEODATE_ASSET_NAME"
geodata_asset_url=$(cat "$release_file" | jq -r ".assets[] | select(.name | test(\"$geodata_asset_name\$\")) | .browser_download_url")
geodata_file="$WORK_DIR/$geodata_asset_name"
geodata_release_id=$(cat "$COMPANION_GEODATE_DIRPATH/.release_id" || echo "")

geodata_update_flag=1

# download geodata asset and unzip to COMPANION_GEODATE_DIRPATH
if [[ -z "$geodata_asset_url" ]]; then
    echo "No geodata asset found in the release."
    # check .release_id in COMPANION_GEODATE_DIRPATH
elif [[ "$geodata_release_id" == "$release_id" ]]; then
    echo "No new geodata release found. Current release ID: $geodata_release_id"
else
    if [[ "$geodata_asset_url" =~ ^https?://github\.com && -n "$COMPANION_GHPROXY_PREFIX" ]]; then
        geodata_asset_url="$COMPANION_GHPROXY_PREFIX/$geodata_asset_url"
        echo "Using GHPROXY: $geodata_asset_url"
    fi

    echo "Downloading geodata asset from $geodata_asset_url"
    curl -L -o "$geodata_file" "$geodata_asset_url" || {
        echo "Error: Failed to download geodata asset"
    }
    if [[ -f "$geodata_file" ]]; then
        echo "extracting geodata asset to $COMPANION_GEODATE_DIRPATH"
        unzip -o "$geodata_file" -d "$WORK_DIR"
        cp -a $WORK_DIR/geodata/* "$COMPANION_GEODATE_DIRPATH"
        echo "remove temporary geodata file $geodata_filename"
        rm -f "$geodata_file"
        # create .release_id file in COMPANION_GEODATE_DIRPATH
        echo "$release_id" >"$COMPANION_GEODATE_DIRPATH/.release_id"
        # update flag
        geodata_update_flag=0
    fi
fi

# update I18N
i18n_asset_name="i18n-iso-countries.zip"
i18n_asset_url=$(cat "$release_file" | jq -r ".assets[] | select(.name | test(\"$i18n_asset_name\$\")) | .browser_download_url")
i18n_filename="$WORK_DIR/$i18n_asset_name"
i18n_release_id=$(cat "$COMPANION_I18N_DIRPATH/.release_id" || echo "")

i18n_update_flag=1

# download i18n asset and unzip to COMPANION_I18N_DIRPATH
if [[ -z "$i18n_asset_url" ]]; then
    echo "No i18n asset found in the release."
# check .release_id in COMPANION_I18N_DIRPATH
elif [[ "$i18n_release_id" == "$release_id" ]]; then
    echo "No new i18n release found. Current release ID: $i18n_release_id"
else
    if [[ "$i18n_asset_url" =~ ^https?://github\.com && -n "$COMPANION_GHPROXY_PREFIX" ]]; then
        i18n_asset_url="$COMPANION_GHPROXY_PREFIX/$i18n_asset_url"
        echo "Using GHPROXY: $i18n_asset_url"
    fi

    echo "Downloading i18n asset from $i18n_asset_url"
    curl -L -o "$i18n_filename" "$i18n_asset_url" || {
        echo "Error: Failed to download i18n asset"
    }

    if [[ -f "$i18n_filename" ]]; then
        echo "extracting i18n asset to $COMPANION_I18N_DIRPATH"
        unzip -o "$i18n_filename" -d "$WORK_DIR"
        rm -f "$18n_filename"
        cp $WORK_DIR/i18n-iso-countries/langs/* "$COMPANION_I18N_DIRPATH/"
        # create .release_id file in COMPANION_I18N_DIRPATH
        echo "$release_id" >"$COMPANION_I18N_DIRPATH/.release_id"
        i18n_update_flag=0
    fi
fi

# auto restart Docker container if updates are found
# if either geodata or i18n was updated , and docker auto restart is enabled, then restart the docker container
if [[ $COMPANION_DOCKER_AUTO_RESTART -ne 0 ]]; then
    echo "Docker auto restart is disabled."
    exit 0
fi

if [[ $geodata_update_flag -ne 0 && $i18n_update_flag -ne 0 ]]; then
    echo "No updates found for geodata or i18n."
    exit 0
fi

# do docker restart
echo "Restarting Docker container $COMPANION_DOCKER_CONTAINER_NAME"
docker_resp_body="$WORK_DIR/docker_response"
docker_resp_code=$(curl -s -o "$docker_resp_body" -w "%{http_code}" --unix-socket "$COMPANION_DOCKER_API" -X POST "http://localhost/containers/$COMPANION_DOCKER_CONTAINER_NAME/restart")

if [[ -f "$docker_resp_body" && -s "$docker_resp_body" ]]; then
    echo "response from docker: $(cat "$docker_resp_body")"
fi

if [[ $docker_resp_code -ge 400 ]]; then
    echo "Error: Failed to restart Docker container $COMPANION_DOCKER_CONTAINER_NAME"
else
    echo "Docker container $COMPANION_DOCKER_CONTAINER_NAME restarted successfully."
fi
