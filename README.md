<!-- TOC -->
- [Usage](#usage)
- [Installation](#installation)
  - [install release](#install-release)
  - [install from source](#install-from-source)
  - [install local with nix](#install-local-with-nix)
  - [install via nix home-manager](#install-via-nix-home-manager)
- [Development](#development)
  - [create a release](#create-a-release)
  - [create a release now](#create-a-release-now)
- [benchmarks](#benchmarks)
  - [gh cli](#gh-cli)
  - [bash script](#bash-script)
  - [act](#act)
<!-- TOC -->

Searches upwards for git root directory and opens the corresponding github actions page.

This comes in handy, when pushing changes and want to check if the github actions
pipeline is successful.

# Usage
```shell
act
```

# Installation

## install release
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/sejoharp/act/refs/heads/main/scripts/install.sh)"
```

## install from source
```shell
# install rust
brew install rustup-init

# build and install act
make install
```

## install local with nix
```shell
nix build
```

## install via nix home-manager
```bash
# move to home-manager config. e.g.:
cd ~/.config/home-manager

# add this as input;
    actpkg = {
      url = "github:sejoharp/act";
    };

# optional: update index
nix flake lock --update-input actpkg

# add this to packages:
inputs.reposyncpkg.packages.${pkgs.stdenv.system}.default

# build generation
nh home build .

# switch generation
nh home switch .
```

# Development

## create a release
1. make a commit 
2. push it
3. github actions will create a release

## create a release now
TODO: create github actions pipeline create a release on new tag
1. bump version
2. commit
3. set tag
4. push

# benchmarks
## gh cli
Result: feels really slow.
```bash
time $(open $(gh browse -n)/actions)
0.01s user 0.01s system 24% cpu 0.089 total
```

## bash script
Result: not bad
```bash
time my_act.sh
0.01s user 0.02s system 21% cpu 0.139 total
```

## act
Result: blazingly fast
```bash
time act
0.01s user 0.01s system 23% cpu 0.074 total
```
