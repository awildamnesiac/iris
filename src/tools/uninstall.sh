#!/usr/bin/env bash
################################################################################
# <START METADATA>
# @file_name: uninstall.sh
# @version: 0.0.1
# @project_name: iris
# @brief: uninstaller for iris
#
# @save_tasks:
#  automated_versioning: true
#
# @author: Jamie Dobbs (mschf)
# @author_contact: jamie.dobbs@mschf.dev
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2022, Jamie Dobbs
# All rights reserved.
# <END METADATA>
# shellcheck disable=2154
################################################################################

################################################################################
# @description: checks for sudo and bash version
# @return_code: 1 user is not root/sudo
################################################################################
uninstall::check(){
  [[ $(whoami) != "root" ]] && printf -- "error[1]: uninstaller requires root/sudo\n" && exit 1
}

################################################################################
# @description: installs iris
################################################################################
uninstall::iris(){
  declare _src_path; _src_path="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"; _src_path="${_src_path%/*}"; _src_path="${_src_path%/*}"
  while read -r user; do
    if [[ $(echo "${user}" | cut -f7 -d:) == "/bin/bash" ]]; then
      declare homedir
      homedir=$(echo "${user}" | cut -f6 -d:)
      if [[ -f "${homedir}/.bashrc.bak" ]]; then
        mv -f "${homedir}/.bashrc.bak" "${homedir}/.bashrc"
      else
        cp -f "/etc/skel/.bashrc.bak" "${homedir}/.bashrc"
      fi
      rm -rf "${homedir}/.config/iris/"
    fi
  done < <(getent passwd)
  rm -rf "/etc/skel/.config/iris"
  mv -f "/etc/skel/.bashrc.bak" "/etc/skel/.bashrc"
  unlink "/usr/local/bin/iris"
  rm -rf "${_src_path}"
  exec bash
}

################################################################################
# @description: calls functions in required order
################################################################################
uninstall::check
uninstall::iris