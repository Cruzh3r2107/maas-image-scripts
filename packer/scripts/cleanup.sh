#!/bin/bash -ex
#
# cleanup.sh - Remove cache and install artifacts
#
# Author: Alexsander de Souza <alexsander.souza@canonical.com>
#
# Copyright (C) 2021 Canonical
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
export DEBIAN_FRONTEND=noninteractive

# Reset cloud-init, so that it can run again when MAAS deploy the image.
cloud-init clean --logs

# cloud-init put networking in place on initial boot. Let's remove that, to
# allow MAAS to configure the networking on deploy.
rm /etc/netplan/50-cloud-init.yaml
rm /etc/ssh/sshd_config.d/50-cloud-init.conf

# Everything in /run/packer_backup should be restored.
find /run/packer_backup
cp --preserve -r /run/packer_backup/ /
rm -rf /run/packer_backup

# We had to allow root to ssh for the image setup. Let's try to revert that.
sed -i s/^root:[^:]*/root:*/ /etc/shadow
rm -r /root/.ssh
rm -r /root/.cache
rm -r /etc/ssh/ssh_host_*

apt-get autoremove --purge -yq
apt-get clean -yq
