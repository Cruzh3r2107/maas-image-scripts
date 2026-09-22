# maas-image-scripts

Templates and fixes to turn a raw Ubuntu Classic image (built with `ubuntu-image` by the OEM
`build-classic.sh`) into a MAAS-deployable `.dd.gz` with Packer. Companion to the `build-custom-image.md`
how-to in iot-field-docs.

`project-name` / `<project>` / `<team>` are placeholders. Rename the files and replace the placeholders in
`build-setup-project-name.yaml`, `yaml/server-amd64.yaml.in` and the two env templates.

Builds on `lp:~<team>/<project>/+git/iot-image-builds` (branch `classic`: `build-classic.sh`, `hooks/`,
`yaml/`) and the Packer reference on its `maas` branch, derived from https://github.com/canonical/packer-maas.

## Contents

| File | Purpose |
|---|---|
| `project-name.pkr.hcl` | Packer template: QEMU builder boots the raw image, runs the provisioners, compresses to `custom-project-name.dd.gz` |
| `variables.pkr.hcl` | Packer variables (qemu plugin pin relaxed to `>= 1.1.0`) |
| `project-name-customize.sh` | MAAS customisation inside the Packer VM: networkd renderer, NetworkManager installed but disabled, empty machine-id, no SSH host keys, MAAS datasource, `cloud-init clean` |
| `project-name-customization.env` | Variables passed to the customize script (locale, keyboard, timezone, Pro token, GRUB user/password). Fill in; the real file is git-ignored |
| `project-name-local_build_env` | Variables for the raw build (`BUILD_ID`, `PPA_ACCESS_TOKEN_n`, project/team). Copy to `local_build_env`, fill in, export before building |
| `user-data-project-name`, `meta-data` | NoCloud seed so Packer can SSH into the build VM as root (password `ubuntu`, build-time only; locked again by `cleanup.sh`) |
| `build-setup-project-name.yaml` | Build setup for the MAAS/server variant: project, team, gadget repo, PPAs, tool channels |
| `yaml/server-amd64.yaml.in` | Image definition: server base + `network-manager` instead of `ubuntu-desktop-minimal` |
| `packer/scripts/` | `curtin.sh` (resolver + `apt-get update` added), `networking.sh`, `cleanup.sh`, `curtin-hooks` (with `do_apt_config` so MAAS Package Repos reach the deployed machine) |
| `hooks/` | ubuntu-image hooks used by the raw build |
| `patches/build-classic.sh-add-build-maas-image.patch` | Adds the `build-maas-image` function to the `classic` branch script (unpacks the xz'd raw image, writes the checksum, runs Packer) |

## Usage

```bash
git clone -b classic git+ssh://git.launchpad.net/~<team>/<project>/+git/iot-image-builds image-builds
cd image-builds
cp -r <this-repo>/{packer,hooks,yaml,meta-data,variables.pkr.hcl} .
cp <this-repo>/project-name.pkr.hcl            <project>.pkr.hcl
cp <this-repo>/project-name-customize.sh       <project>-customize.sh
cp <this-repo>/user-data-project-name          user-data-<project>
cp <this-repo>/build-setup-project-name.yaml   build-setup-<project>.yaml
cp <this-repo>/project-name-customization.env  <project>-customization.env
cp <this-repo>/project-name-local_build_env    local_build_env
sed -i 's/project-name/<project>/g' <project>.pkr.hcl <project>-customize.sh meta-data variables.pkr.hcl
patch -p1 < <this-repo>/patches/build-classic.sh-add-build-maas-image.patch
# fill in the placeholders in build-setup-<project>.yaml, yaml/server-amd64.yaml.in, the two env files

set -a; source local_build_env; set +a
./build-classic.sh --lib-path=./build-classic-function.sh --yaml=build-setup-<project>.yaml --output-dir=$(pwd)/deploy
ls deploy/   # <project>-classic-<series>-<date>-<id>.img.xz, filesystem.manifest, custom-<project>.dd.gz
```

Build VM: `snapcraft`, `ubuntu-image`, `packer` + `github.com/hashicorp/qemu` plugin,
`qemu-system-x86 qemu-utils ovmf cloud-image-utils`, user in the `kvm` group, ≥100 GB disk.
If a stage fails, delete its `.done_*` marker before re-running.
