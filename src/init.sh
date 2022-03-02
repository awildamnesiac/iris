#!/usr/bin/env bash
################################################################################
# <START METADATA>
# @file_name: init.sh
# @version: 0.0.114
# @project_name: iris
# @brief: initializer for iris
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
# @description: checks and readies environment for iris
# @noargs
# @return_code: 1 unsupported bash version
# @return_code: 2 unable to load default config
# @return_code: 3 unable to load module
# @return_code: 4 unable to load custom module
# shellcheck source=/dev/null
################################################################################
[[ ${BASH_VERSINFO[0]} -lt 4 ]] && printf -- "error[1]: iris requires a bash version of 4 or greater\n" && return 1
_prompt::init(){
  [[ -f "${HOME}/.config/iris/iris.conf" ]] && . "${HOME}/.config/iris/iris.conf"
  declare _iris_base_path; _iris_base_path="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
  if [[ ${_iris_per_user:="false"} != "true" ]]; then
    [[ -f "${_iris_base_path}/config/iris.conf" ]] && . "${_iris_base_path}/config/iris.conf"
  fi
  for _mod in "${_iris_official_modules[@]}"; do
    [[ -f "${_iris_base_path}/config/modules/${_mod}.conf" ]] && . "${_iris_base_path}/config/modules/${_mod}.conf"
    if [[ -f "${_iris_base_path}/modules/${_mod}.module.sh" ]]; then
      . "${_iris_base_path}/modules/${_mod}.module.sh"
    else
      printf -- "error[3]: unable to load %s\n" "${_mod}" && return 3
    fi
  done
  for _mod in "${_iris_custom_modules[@]}"; do
    [[ -f "${_iris_base_path}/custom/config/${_mod}.conf" ]] && . "${_iris_base_path}/custom/config/${_mod}.conf"
    if [[ -f "${_iris_base_path}/custom/modules/${_mod}.module.sh" ]]; then
      . "${_iris_base_path}/custom/modules/${_mod}.module.sh"
    else
      printf -- "error[4]: unable to load %s\n" "${_mod}" && return 4
    fi
  done
  unset mod
}

################################################################################
# @description: checks if modules have init functions for prompt generation
# @arg $1: function to test
# @return_code: 0 function exists
# @return_code: 1 function does not exist
################################################################################
_module::init::test(){
  declare -f -F "$1" > /dev/null
  return $?
}

################################################################################
# @description: colors prompt information
# @arg $1: prompt information to color
################################################################################
_prompt::color(){
  [[ "${1}" != "-" ]] && _fg="38;5;${1}"
  echo -ne "\[\033[${_fg}m\]"
}

################################################################################
# @description: outputs prompt information
# @arg $1: prompt information to output
# @return_code 0: success
################################################################################
_prompt::output(){
  declare _prompt_re
  _prompt_re="\<${1}\>"
  if [[ ${PROMPT_COMMAND} =~ ${_prompt_re} ]]; then
    return
  elif [[ -z ${PROMPT_COMMAND} ]]; then
    PROMPT_COMMAND="${1}"
  else
    PROMPT_COMMAND="${1};${PROMPT_COMMAND}"
  fi
}

################################################################################
# @description: builds prompt information
# @noargs
################################################################################
_prompt::build(){
  declare _last_status="$?"; declare _gen_uh
  declare -gi _prompt_seg=1
  for _mod in "${_iris_official_modules[@]}"; do
    _module::init::test "_${_mod}::pre" && "_${_mod}::pre"
  done
  for _mod in "${_iris_custom_modules[@]}"; do
    _module::init::test "_${_mod}::pre" && "_${_mod}::pre"
  done
  declare _user_color="${_prompt_user_color:=178}"
  sudo -n uptime 2>&1 | grep -q "load" && _user_color="${_prompt_sudo_color:=215}"
  [[ ${_prompt_username:=true} == "true" ]] && _gen_uh="${USER}"
  { [[ ${_prompt_hostname:=ssh} == "all" ]]; } || { [[ ${_prompt_hostname} == "ssh" && -n ${SSH_CLIENT} ]]; } && _gen_uh="${_gen_uh}@${HOSTNAME}"
  _prompt::generate "${_gen_uh}|${_user_color}"
  [[ ${_prompt_dir:=true} == "true" ]] && _prompt::generate "${_prompt_wrapper:0:1}$(pwd | sed "s|^${HOME}|~|")${_prompt_wrapper:1:1}|${_prompt_info_color:=254}"
  for _mod in "${_iris_official_modules[@]}"; do
    _module::init::test "_${_mod}::post" && "_${_mod}::post"
  done
  for _mod in "${_iris_custom_modules[@]}"; do
    _module::init::test "_${_mod}::post" && "_${_mod}::post"
  done
  [[ ${_prompt_display_error:=true} == "true" ]] && [[ "${_last_status}" -ne 0 ]] && _prompt::generate "${_prompt_wrapper:0:1}${_last_status}${_prompt_wrapper:1:1} |${_prompt_fail_color:=203}"
    if [[ -n ${_prompt_information} ]]; then
    if [[ ${_last_status} -ne 0 ]]; then
      _prompt_status_color=${_prompt_fail_color:=203}
    else
      _prompt_status_color=${_prompt_success_color:=77}
    fi
  fi
  [[ ${_prompt_input_newline:=true} == "true" ]] && declare _prompt_new_line="\n"
  if [[ ${_prompt_nerd_font} == "true" ]]; then
    _prompt_information+="$(_prompt::color ${_prompt_status_color}) ${_prompt_new_line}${_prompt_nerd_symbol}\[\e[0m\]"
  else
    _prompt_information+="$(_prompt::color ${_prompt_status_color}) ${_prompt_new_line}${_prompt_input_symbol}\[\e[0m\]"
  fi
  PS1="${_prompt_information} "
  unset _prompt_information _prompt_seg _mod
}

################################################################################
# @description: generates prompt segments
# @arg $1: prompt information
# @arg $2: color of prompt
################################################################################
_prompt::generate(){
  declare OLD_IFS="${IFS}"; IFS="|"
  read -ra _params <<< "$1"
  IFS="${OLD_IFS}"
  declare _separator=""
  [[ ${_prompt_seg} -gt 1 ]] && _separator="${_prompt_seperator}"
  _prompt_information+="${_separator}$(_prompt::color "${_params[1]}")${_params[0]}\[\e[0m\]"
  (( _prompt_seg += 1 ))
}

################################################################################
# @description: parses arguments
# @arg $1: function to run
################################################################################
_iris::args(){
  if [[ $# -gt 0 ]]; then
    case "${1}" in
      --disable*)   _iris::disable "${2,,}" "${3,,}";;
      --enable*)    _iris::enable "${2,,}" "${3,,}";;
      --help)       _iris::help;;
      --version)    _iris::version;;
      *)            _iris::unknown "${1}";;
    esac
  else
    _iris::help
  fi
}

################################################################################
# @description: outputs help information
################################################################################
_iris::help(){
  declare _iris_version
  _iris_version="$(git describe --tags --abbrev=0)"
  printf -- "iris %s
usage: iris [--disable [o|c] <module> ] [--enable [o|c] <module>] [--help]
            [--modules] [--uninstall] [--upgrade] [--version]

iris is a minimal, fast, and customizable prompt for BASH 4.0 or greater.
Every detail is cusomizable to your liking to make it as lean or feature-packed
as you like.

options:
  --disable [o|c] [module]    disables the provided module [o=official|c=custom]
  --enable  [o|c] [module]    enables the provided module [o=official|c=custom]
  --help                      displays this help
  --modules                   lists all installed modules
  --uninstall                 uninstalls iris
  --upgrade                   upgrades iris to latest version
  --version                   outputs iris version\n\n" "${_iris_version}"
  return
}

################################################################################
# @description: outputs version
################################################################################
_iris::version(){
  declare _iris_version
  _iris_version="$(git describe --tags --abbrev=0)"
  printf -- "iris %s\n" "${_iris_version}"
}

################################################################################
# @description: outputs unknown command
# @arg $1: incorrect command
# @return_code: 5 command not found
################################################################################
_iris::unknown(){
  printf -- "iris: '%s' is not an iris command. See 'iris --help' for all commands.\n" "${1}"
  return 5
}

################################################################################
# @description: disables provided module
# @arg $1: o|c
# @arg $2: module
# @return_code: 6 o|c not specified
# @return_code: 7 module not enabled
# @return_code: 8 module not enabled
################################################################################
_iris::disable(){
  [[ -f "${HOME}/.config/iris/iris.conf" ]] && . "${HOME}/.config/iris/iris.conf"
  declare _iris_base_path; _iris_base_path="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
  if [[ ${_iris_per_user:="false"} != "true" ]]; then
    [[ -f "${_iris_base_path}/config/iris.conf" ]] && . "${_iris_base_path}/config/iris.conf"
    declare _conf_file="${_iris_base_path}/config/iris.conf"
  else
    declare _conf_file="${HOME}/.config/iris/iris.conf"
  fi
  case "$1" in
    o)
      if printf '%s\0' "${_iris_official_modules[@]}" | grep -Fxq "$2"; then
        for i in "${!_iris_official_modules[@]}"; do
          if [[ ${_iris_official_modules[i]} == "$2" ]]; then
            unset '_iris_official_modules[i]'
          fi
        done
        for _mod in "${_iris_official_modules[@]}"; do
          [[ -n "${_mod}" ]] && _enabled_mods=${_enabled_mods}"\"${_mod}\" "
        done
        sed -i "0,/_iris_official_modules.*)/{s//_iris_official_modules=( ${_enabled_mods})/}" "${_conf_file}"
        printf -- "iris: '%s' module disabled\n" "$2"
        return
      else
        printf -- "iris: '%s' module is not enabled\n" "$2"
        return 7
      fi;;
    c)
      if printf '%s\0' "${_iris_custom_modules[@]}" | grep -Fxq "$2"; then
        for i in "${!_iris_custom_modules[@]}"; do
          if [[ ${_iris_custom_modules[i]} == "$2" ]]; then
            unset '_iris_custom_modules[i]'
          fi
        done
        for _mod in "${_iris_custom_modules[@]}"; do
          [[ -n "${_mod}" ]] && _enabled_mods=${_enabled_mods}"\"${_mod}\" "
        done
        sed -i "0,/_iris_custom_modules.*)/{s//_iris_custom_modules=( ${_enabled_mods})/}" "${_conf_file}"
        printf -- "iris: '%s' module disabled\n" "$2"
        return
      else
        printf -- "iris: '%s' module is not enabled\n" "$2"
        return 8
      fi;;
    *) 
      printf -- "iris: please specifiy o or c\n"
      return 6;;
  esac
}

################################################################################
# @description: enables provided module
# @arg $1: o|c
# @arg $2: module
# @return_code: 9 o|c not specified
# @return_code: 10 module already enabled
# @return_code: 11 module already enabled
################################################################################
_iris::enable(){
  [[ -f "${HOME}/.config/iris/iris.conf" ]] && . "${HOME}/.config/iris/iris.conf"
  declare _iris_base_path; _iris_base_path="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
  if [[ ${_iris_per_user:="false"} != "true" ]]; then
    [[ -f "${_iris_base_path}/config/iris.conf" ]] && . "${_iris_base_path}/config/iris.conf"
    declare _conf_file="${_iris_base_path}/config/iris.conf"
  else
    declare _conf_file="${HOME}/.config/iris/iris.conf"
  fi
  case "$1" in
    o)
      if ! printf '%s\0' "${_iris_official_modules[@]}" | grep -Fxq "$2"; then
        _iris_official_modules+=( "${2}" )
        for _mod in "${_iris_official_modules[@]}"; do
          [[ -n "${_mod}" ]] && _enabled_mods=${_enabled_mods}"\"${_mod}\" "
        done
        sed -i "0,/_iris_official_modules.*)/{s//_iris_official_modules=( ${_enabled_mods})/}" "${_conf_file}"
        printf -- "iris: '%s' module enabled\n" "$2"
        return
      else
        printf -- "iris: '%s' module is already enabled\n" "$2"
        return 10
      fi;;
    c)
      if ! printf '%s\0' "${_iris_custom_modules[@]}" | grep -Fxq "$2"; then
        _iris_custom_modules+=( "${2}" )
        for _mod in "${_iris_custom_modules[@]}"; do
          [[ -n "${_mod}" ]] && _enabled_mods=${_enabled_mods}"\"${_mod}\" "
        done
        sed -i "0,/_iris_custom_modules.*)/{s//_iris_custom_modules=( ${_enabled_mods})/}" "${_conf_file}"
        printf -- "iris: '%s' module enabled\n" "$2"
        return
      else
        printf -- "iris: '%s' module is already enabled\n" "$2"
        return 11
      fi;;
    *) 
      printf -- "iris: please specifiy o or c\n"
      return 9;;
  esac
}

################################################################################
# @description: calls functions in required order
################################################################################
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  _prompt::init
  _prompt::output _prompt::build
else
  _iris::args "$@"
fi