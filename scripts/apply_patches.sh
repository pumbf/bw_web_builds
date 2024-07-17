#!/usr/bin/env bash
set -o pipefail -o errexit

function replace_embedded_svg_icon() {
if [ ! -f $1 ]; then echo "$1 does not exist"; exit -1; fi
if [ ! -f $2 ]; then echo "$2 does not exist"; exit -1; fi

echo "'$1' -> '$2'"

first='`$'
last='^`'
sed -i "/$first/,/$last/{ /$first/{p; r $1
}; /$last/p; d }" $2
}

# If a patch was not provided, try to choose one
if [[ -z ${PATCH_NAME} ]]; then
    # If a patch with the same name as the ref exists, use it
    if [ -f "../patches/${VAULT_VERSION}.patch" ]; then
        echo "Exact patch file found, using that"
        PATCH_NAME="${VAULT_VERSION}.patch"
    elif [ -f "../patches/legacy/${VAULT_VERSION}.patch" ]; then
        echo "Exact legacy patch file found, using that"
        echo "NOTE: This is a Legacy patch file for an older web-vault version!"
        # Sleep 10 seconds so this note might be noticed a bit better
        sleep 10
        PATCH_NAME="legacy/${VAULT_VERSION}.patch"
    else
        echo "No exact patch file not found, using latest"
        # If not, use the latest one
        PATCH_NAME="$(find ../patches/ -type f -print0 | xargs -0 basename -a | sort -V | tail -n1)"
    fi
fi

# Final check if the patch file exists, if not, exit
if [[ ! -f "../patches/${PATCH_NAME}" ]]; then
    echo "Patch file '${PATCH_NAME}' not found in the patches directory!"
    exit 1
fi

echo "Patching images"
cp -vfR ../resources/src/* ./apps/web/src/

echo "Patching logos"
replace_embedded_svg_icon \
	../resources/vaultwarden-admin-console-logo.svg \
	./apps/web/src/app/admin-console/icons/admin-console-logo.ts
replace_embedded_svg_icon \
	../resources/vaultwarden-password-manager-logo.svg \
	./apps/web/src/app/layouts/password-manager-logo.ts

echo "Using patch: ${PATCH_NAME}"
cp ../patches/$PATCH_NAME ../patches/$PATCH_NAME.apply
# 兼容之前版本
sed -i "s|\((Powered by Vaultwarden)\)|\1<br/><a href='https://beian.miit.gov.cn/' style='color: inherit;' target='_blank'>粤ICP备2021027141号</a><br/><a target='_blank' href='http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=44011202001765' style='color: inherit;' >粤公网安备 44011202001765号</a>|g" "../patches/$PATCH_NAME.apply"
# 后续版本
git apply "../patches/$PATCH_NAME.apply" --reject

echo "Patching successful!"
