#!/bin/sh
if [ $# -lt 1 ]; then
    echo "Please specify the path to your fork of 'https://github.com/typst/packages'."
    exit 1
fi

version=${OXIFMT_VERSION:-"$(grep "version = " typst.toml | sed -e 's/^version = "\|"$//g')"}
orig_dir="$(realpath "$(dirname "$0")/..")"
dest_dir="$1/packages/preview/oxifmt/${version}"
mkdir -p "${dest_dir}"
IFS=$' '
for file in LICENSE LICENSE-MIT LICENSE-APACHE README.md oxifmt.typ lib.typ typst.toml
do
    cp "${orig_dir}/${file}" -t "${dest_dir}"
done

echo "Copied files to ${dest_dir}"
