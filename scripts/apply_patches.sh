#!/usr/bin/env bash
set -o pipefail -o errexit

# If a patch was not provided, try to choose one
if [[ -z ${PATCH_NAME} ]]; then
    # If a patch with the same name as the ref exists, use it
    if [ -f "../patches/${VAULT_VERSION}.patch" ]; then
        echo "Exact patch file found, using that"
        PATCH_NAME="${VAULT_VERSION}.patch"
    else
        echo "Patch file not found, using latest"
        # If not, use the latest one
        PATCH_NAME="$(find ../patches -type f -print0 | xargs -0 basename -a | sort -V | tail -n1)"
    fi
fi

echo "Patching images"
cp -vfR ../resources/src/* ./apps/web/src/

echo "Using patch: ${PATCH_NAME}"
cp ../patches/$PATCH_NAME ../patches/$PATCH_NAME.apply
# 兼容之前版本
sed -i "s|\((Powered by Vaultwarden)\)|\1<br/><a href='https://beian.miit.gov.cn/' style='color: inherit;' target='_blank'>粤ICP备2021027141号</a><br/><a target='_blank' href='http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=44011202001765' style='color: inherit;' >粤公网安备 44011202001765号</a>|g" "../patches/$PATCH_NAME.apply"
# 后续版本
git apply "../patches/$PATCH_NAME.apply" --reject

echo "Patching successful!"
