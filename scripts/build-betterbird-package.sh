#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repository_dir=$(cd -- "$script_dir/.." && pwd)
config_file=${BETTERBIRD_BUILD_CONFIG:-$repository_dir/build/betterbird.env}
output_dir=${OUTPUT_DIR:-$repository_dir/dist}
work_dir=${WORK_DIR:-$repository_dir/.build/betterbird}

if [[ ! -f $config_file ]]; then
    echo "Build configuration not found: $config_file" >&2
    exit 1
fi

set -a
# shellcheck disable=SC1090
source "$config_file"
set +a

required_variables=(
    BETTERBIRD_VERSION
    BETTERBIRD_PATCH_SERIES
    BETTERBIRD_PATCH_REVISION
    THUNDERBIRD_SOURCE_VERSION
    THUNDERBIRD_SOURCE_URL
    THUNDERBIRD_SOURCE_SHA256
    RUST_VERSION
    LLVM_VERSION
    CBINDGEN_VERSION
    SOURCE_DATE_EPOCH
)

if [[ $work_dir == / || $work_dir == "$repository_dir" ]]; then
    echo "Unsafe work directory: $work_dir" >&2
    exit 1
fi

for variable_name in "${required_variables[@]}"; do
    if [[ -z ${!variable_name:-} ]]; then
        echo "Required variable is empty: $variable_name" >&2
        exit 1
    fi
done

for command_name in cargo clang curl file find git node patch python3 rustup sed sha256sum tar wget xz; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command not found: $command_name" >&2
        exit 1
    fi
done

case "$(uname -m)" in
    x86_64)
        architecture=amd64
        target_triple=x86_64-pc-linux-gnu
        expected_elf='x86-64'
        ;;
    aarch64 | arm64)
        architecture=arm64
        target_triple=aarch64-unknown-linux-gnu
        expected_elf='ARM aarch64'
        ;;
    *)
        echo "Unsupported native architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

if [[ -n ${BUILD_ARCH:-} && $BUILD_ARCH != "$architecture" ]]; then
    echo "BUILD_ARCH=$BUILD_ARCH does not match native architecture $architecture" >&2
    exit 1
fi

patches_dir=$work_dir/thunderbird-patches
source_archive=$work_dir/$(basename "$THUNDERBIRD_SOURCE_URL")
source_dir=$work_dir/mozilla-esr${BETTERBIRD_PATCH_SERIES}
package_name=betterbird-${BETTERBIRD_VERSION}.en-US.linux-${architecture}.tar.xz
package_path=$output_dir/$package_name
provenance_path=$output_dir/${package_name%.tar.xz}.provenance.json
stage_dir=$work_dir/package-stage

rm -rf "$work_dir"
mkdir -p "$work_dir" "$output_dir"

git -C "$work_dir" init thunderbird-patches
git -C "$patches_dir" remote add origin https://github.com/Betterbird/thunderbird-patches.git
git -C "$patches_dir" fetch --depth=1 origin "$BETTERBIRD_PATCH_REVISION"
git -C "$patches_dir" checkout --detach FETCH_HEAD

curl --fail --location --retry 3 --output "$source_archive" "$THUNDERBIRD_SOURCE_URL"
echo "$THUNDERBIRD_SOURCE_SHA256  $source_archive" | sha256sum --check --strict

mkdir -p "$source_dir"
tar -xf "$source_archive" --strip-components=1 -C "$source_dir"

apply_patch_series() {
    local source_root=$1
    local series_file=$2
    local line
    local patch_name
    local patch_file
    local token
    local patch_url

    while IFS= read -r line || [[ -n $line ]]; do
        patch_name=${line%%#*}
        patch_name=${patch_name%"${patch_name##*[![:space:]]}"}
        patch_name=${patch_name#"${patch_name%%[![:space:]]*}"}
        [[ -n $patch_name ]] || continue

        patch_file=$patches_dir/$BETTERBIRD_PATCH_SERIES/$patch_name
        if [[ ! -f $patch_file ]]; then
            patch_url=
            for token in ${line#*#}; do
                if [[ $token == https://* || $token == http://* ]]; then
                    patch_url=$token
                    break
                fi
            done
            patch_url=${patch_url/\/rev\//\/raw-rev\/}
            if [[ -z $patch_url ]]; then
                echo "Patch not found: $patch_name" >&2
                exit 1
            fi

            mkdir -p "$(dirname "$patch_file")"
            curl --fail --location --retry 3 --output "$patch_file" "$patch_url"
        fi

        printf 'Applying %s\n' "$patch_name"
        git -C "$source_root" apply --allow-empty --whitespace=nowarn "$patch_file"
    done <"$series_file"
}

apply_patch_series \
    "$source_dir" \
    "$patches_dir/$BETTERBIRD_PATCH_SERIES/series-moz"
apply_patch_series \
    "$source_dir/comm" \
    "$patches_dir/$BETTERBIRD_PATCH_SERIES/series"

sed \
    -e '/^ac_add_options --enable-tests$/d' \
    -e '/^mk_add_options MOZ_MAKE_FLAGS=/d' \
    "$patches_dir/$BETTERBIRD_PATCH_SERIES/mozconfig-Linux" \
    >"$source_dir/mozconfig"
cat >>"$source_dir/mozconfig" <<EOF

#### docker-betterbird package configuration
ac_add_options --disable-tests
ac_add_options --disable-debug
ac_add_options --disable-debug-symbols
ac_add_options --enable-optimize
mk_add_options AUTOCLOBBER=1
mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj-${target_triple}
EOF

if command -v sccache >/dev/null 2>&1; then
    echo 'ac_add_options --with-ccache=sccache' >>"$source_dir/mozconfig"
fi

if [[ $architecture == arm64 ]]; then
    cat >>"$source_dir/mozconfig" <<'EOF'
ac_add_options --target=aarch64-unknown-linux-gnu
ac_add_options --host=aarch64-unknown-linux-gnu
EOF
fi

export SOURCE_DATE_EPOCH
export MOZ_BUILD_DATE
MOZ_BUILD_DATE=$(python3 - <<'PY'
import datetime
import os

value = int(os.environ["SOURCE_DATE_EPOCH"])
print(datetime.datetime.fromtimestamp(value, datetime.UTC).strftime("%Y%m%d%H%M%S"))
PY
)

rustup override set --path "$source_dir" "$RUST_VERSION"

clang_version=$(clang --version | sed -n '1p')
if [[ $clang_version != *"version $LLVM_VERSION."* ]]; then
    echo "Unexpected Clang version: $clang_version" >&2
    exit 1
fi

export CC=clang
export CXX=clang++

(
    cd "$source_dir"
    ./mach build
    ./mach package
)

mapfile -t upstream_packages < <(find "$source_dir/obj-$target_triple/dist" -maxdepth 1 -type f -name '*.tar.bz2' -print)
if [[ ${#upstream_packages[@]} -ne 1 ]]; then
    echo "Expected one Betterbird package, found ${#upstream_packages[@]}" >&2
    printf '%s\n' "${upstream_packages[@]}" >&2
    exit 1
fi

rm -rf "$stage_dir"
mkdir -p "$stage_dir"
tar -xjf "${upstream_packages[0]}" -C "$stage_dir"

binary_path=$stage_dir/betterbird/betterbird-bin
if [[ ! -x $binary_path ]]; then
    echo "Packaged Betterbird binary not found: $binary_path" >&2
    exit 1
fi

binary_description=$(file -b "$binary_path")
if [[ $binary_description != *"$expected_elf"* ]]; then
    echo "Unexpected Betterbird binary architecture: $binary_description" >&2
    exit 1
fi

version_output=$($binary_path --version)
if [[ $version_output != *"$BETTERBIRD_VERSION"* ]]; then
    echo "Unexpected Betterbird version: $version_output" >&2
    exit 1
fi

tar \
    --sort=name \
    --mtime="@$SOURCE_DATE_EPOCH" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    -cJf "$package_path" \
    -C "$stage_dir" \
    betterbird
(
    cd "$output_dir"
    sha256sum "$package_name" >"$package_name.sha256"
)

export architecture package_name target_triple provenance_path
python3 - <<'PY'
import json
import os
from pathlib import Path

provenance = {
    "architecture": os.environ["architecture"],
    "betterbirdPatchRevision": os.environ["BETTERBIRD_PATCH_REVISION"],
    "betterbirdVersion": os.environ["BETTERBIRD_VERSION"],
    "githubRepository": os.environ.get("GITHUB_REPOSITORY"),
    "githubRevision": os.environ.get("GITHUB_SHA"),
    "cbindgenVersion": os.environ["CBINDGEN_VERSION"],
    "githubRunId": os.environ.get("GITHUB_RUN_ID"),
    "package": os.environ["package_name"],
    "llvmVersion": os.environ["LLVM_VERSION"],
    "rustVersion": os.environ["RUST_VERSION"],
    "sourceDateEpoch": int(os.environ["SOURCE_DATE_EPOCH"]),
    "target": os.environ["target_triple"],
    "thunderbirdSourceSha256": os.environ["THUNDERBIRD_SOURCE_SHA256"],
    "thunderbirdSourceUrl": os.environ["THUNDERBIRD_SOURCE_URL"],
    "thunderbirdSourceVersion": os.environ["THUNDERBIRD_SOURCE_VERSION"],
}

path = Path(os.environ["provenance_path"])
path.write_text(json.dumps(provenance, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

printf 'Created %s\n' "$package_path"
