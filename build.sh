#!/bin/bash
export CONT_LATEST="${REGISTRY}/${IMAGE}"
export DEBIAN_FRONTEND=noninteractive
export STORAGE_DRIVER=vfs
export BUILDAH_ISOLATION=chroot
cd $(dirname "$0")
sudo apt-get update && sudo apt-get -y --no-install-recommends install git ca-certificates curl buildah netavark jq && \
VERS=$(curl -fsm4 https://raw.githubusercontent.com/zwave-js/zwave-js-ui/refs/heads/master/package.json | jq -r .version) && \
git clone --depth=1  -c advice.detachedHead=false --single-branch --branch "v${VERS}"  https://github.com/zwave-js/zwave-js-ui.git && cd zwave-js-ui && \
npm config set min-release-age=7 && \
buildah --storage-driver "$STORAGE_DRIVER" --isolation "$BUILDAH_ISOLATION" bud -t "$CONT_LATEST" --pull=missing \
        --build-arg NODE_VERSION=24 -f docker/dockerfile && \
buildah --storage-driver "$STORAGE_DRIVER" from --pull=never --name version-checker "$CONT_LATEST" && \
NODE_VER=$(buildah --storage-driver "$STORAGE_DRIVER" --isolation "$BUILDAH_ISOLATION" run version-checker node -v) && \
CONT_VER="${VERS}_${NODE_VER}" && \
CONT_WITH_VER="${CONT_LATEST%%:*}:${CONT_VER//[+~]/_}" && \
echo "Container version: ${CONT_WITH_VER}" && \
buildah --storage-driver "$STORAGE_DRIVER" tag "$CONT_LATEST" "$CONT_WITH_VER" && \
buildah --storage-driver "$STORAGE_DRIVER" images && \
echo "${REGISTRY_PACKAGE_RW}" | buildah login --password-stdin -u "${ACTOR}" "${REGISTRY}" && \
buildah --storage-driver $STORAGE_DRIVER push "${CONT_LATEST}" && \
buildah --storage-driver $STORAGE_DRIVER push "${CONT_WITH_VER}"
