#!/bin/bash

juvix_release="https://github.com/anoma/juvix-nightly-builds/releases/download/nightly-2025-05-09-0.6.10-9692fe8/juvix-darwin-aarch64.tar.gz"
# juvix_release="https://github.com/anoma/juvix-nightly-builds/releases/download/nightly-2025-03-25-0.6.9-d903721/juvix-darwin-aarch64.tar.gz"
juvix_release="https://github.com/anoma/juvix-nightly-builds/releases/download/nightly-2025-05-23-0.6.10-be6f5f3/juvix-darwin-aarch64.tar.gz"
anoma_branch="origin/m1dnight/kudos-examples"
anoma_branch="a49610b8"

# run all commands in the root directory of this repository
root_dir=$(dirname $(dirname -- "$(readlink -f -- "$BASH_SOURCE")"))
cd "${root_dir}"


#-----------------------------------------------------------
# Install the proper Juvix compiler

# This script downloads and installs the juvix compiler in this folder.
wget "${juvix_release}"
tar -xzf juvix-darwin-aarch64.tar.gz
rm -f juvix-darwin-aarch64.tar.gz

mkdir -p bin
mv juvix bin/juvix

#-----------------------------------------------------------
# Clone an Anoma version

git -C anoma checkout "${anoma_branch}" || git clone https://github.com/anoma/anoma.git anoma

cd anoma                       && \
git checkout "${anoma_branch}" && \
mix deps.get                   && \
mix compile
