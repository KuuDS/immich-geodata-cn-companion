# README 文档

本项目用于在容器中自动化部署更新[Immich 反向地理编码汉化](https://github.com/ZingLix/immich-geodata-cn)

## 功能描述

该项目包含两个主要的脚本：

1. **`update.sh`**
   - 用于从指定的 GitHub Release API 拉取最新的地理数据（Geodata）和国际化数据（I18N），并将其解压到指定的目录中。
   - 支持检查更新版本的 Release ID，避免重复下载。
   - 可选支持自动重启指定的 Docker 容器（如 Immich）以应用更新。
   - 提供文件权限管理和所有权设置。

1. **`entrypoints.sh`**
   - 配置并启动一个基于 `cron` 的定时任务，定期运行 `update.sh` 脚本。
   - 定时任务的时间表达式由环境变量 `COMPONION_CRON_EXPRESSION` 控制。

## 环境变量用法

以下是脚本支持的环境变量及其用途：

### **通用环境变量**

| 变量名                     | 说明                                         | 必填 | 默认值                                      |
|----------------------------|--------------------------------------------|----|---------------------------------------------|
| `COMPANION_DEBUG`          | 启用调试模式（设置任意值即可启用）               | 否       | 未启用                                      |
| `COMPANION_RELEASE_API`    | 指定用于获取最新 Release 信息的 GitHub API URL | 否       | `https://api.github.com/repos/ZingLix/immich-geodata-cn/releases/latest` |
| `COMPANION_GEODATE_DIRPATH`| Geodata 的存储目录路径                        | 是       | 无                                          |
| `COMPANION_I18N_DIRPATH`   | 国际化数据（I18N）的存储目录路径                | 是       | 无                                          |
| `COMPANION_GEODATE_ASSET_NAME` | 需要下载的 Geodata 的文件名               | 否       | `geodata.zip`                               |
| `COMPANION_I18N_ASSET_NAME`| 国际化数据资产的文件名                         | 否       | `i18n-iso-countries.zip`                    |
| `COMPANION_UID`            | 文件所有者的用户 ID                           | 否       | `1000`                                      |
| `COMPANION_GID`            | 文件所有者的组 ID                         | 否       | `1000`                                      |
| `COMPANION_PERMISSION_MASK`| 文件权限掩码                              | 否       | `640`                                       |

### **Docker 自动重启相关环境变量**

| 变量名                        | 说明                                                                 | 必填 | 默认值                      |
|-------------------------------|----------------------------------------------------------------------|-----|-----------------------------|
| `COMPANION_DOCKER_AUTO_RESTART` | 是否启用 Docker 容器自动重启功能（`true` 或 `false`）                 | 否       | `false`                     |
| `COMPANION_DOCKER_CONTAINER_NAME` | 需要重启的 Docker 容器名称（当 `COMPANION_DOCKER_AUTO_RESTART` 为 `true` 时必填） | 否       | `immich`                    |
| `COMPANION_DOCKER_API`         | Docker API 的 Unix Socket 路径                                       | 否       | `/var/run/docker.sock`      |

### **定时任务相关环境变量**

| 变量名                     | 说明                                                                 | 必填 | 默认值                      |
|----------------------------|----------------------------------------------------------------------|----|-----------------------------|
| `COMPONION_CRON_EXPRESSION`| 定时任务的 Cron 表达式，用于控制 `update.sh` 的运行频率。              | 否       | `0 0 * * *`                |

## 使用示例

### 手动执行一次

```bash
docker run --rm \
  --name immich-companion \
  -e COMPANION_GEODATE_DIRPATH=/data/geodata \
  -e COMPANION_I18N_DIRPATH=/data/i18n \
  -e COMPANION_DOCKER_AUTO_RESTART=true \
  -e COMPANION_DOCKER_CONTAINER_NAME=immich \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /path/to/geodata:/data/geodata \
  -v /path/to/i18n:/data/i18n \
  ghcr.io/kuuds/immich-companion:latest \
  bash update.sh
```

### **Docker**

以下是直接运行 Docker 容器的示例：

```bash
docker run -d \
  --restart=unless-stopped \
  --name immich-companion \
  -e COMPANION_GEODATE_DIRPATH=/data/geodata \
  -e COMPANION_I18N_DIRPATH=/data/i18n \
  -e COMPANION_DOCKER_AUTO_RESTART=true \
  -e COMPANION_DOCKER_CONTAINER_NAME=immich \
  -e COMPONION_CRON_EXPRESSION="0 0 * * *" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data:/data \
  immich-companion:latest
```

### 使用 Docker Compose

以下是使用 Docker Compose 的示例配置,请确保文件挂载路径正确：

```yaml
services:
  immich:
    image: ghcr.io/immich-app/immich-server:latest
    container_name: immich
    # ....
  immich-companion:
    image: ghcr.io/kuuds/immich-geodata-cn-companion:latest
    container_name: immich-companion
    restart: unless-stopped
    environment:
      COMPANION_GEODATE_DIRPATH: /data/geodata
      COMPANION_I18N_DIRPATH: /data/i18n
      COMPANION_DOCKER_AUTO_RESTART: "true"
      COMPANION_DOCKER_CONTAINER_NAME: immich
      COMPONION_CRON_EXPRESSION: "0 2 * * *"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /path/to/i18n:/data/i18n
      - /path/to/geodata:/data/geodata
    depends_on:
      - immich

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
