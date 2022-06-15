#!/usr/bin/env bash

> ./generated-reverts

while read line; do
    commit=$(echo ${line} | awk -F ' ' '{print $NF}')
    hash=$(nix-prefetch-url https://github.com/ValveSoftware/wine/commit/${commit}.patch)

    echo "patch -RNp1 < \${rev \"$commit\" \"$hash\"}" >> ./generated-reverts

    sleep 0.5
done < ./revert-hashes
