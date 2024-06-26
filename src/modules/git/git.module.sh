#!/usr/bin/env bash
################################################################################
# @file_name: git.module.sh
# @version: 0.0.23
# @project_name: iris
# @brief: git module for iris
#
# @author: Jamie Dobbs (awildamnesiac)
# @author_contact: awildamnesiac@protonmail.ch
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2024, Jamie Dobbs
# All rights reserved.
# shellcheck disable=2154
################################################################################

################################################################################
# @description: generates git responses
# @noargs
################################################################################
_git::post() {
	if git status --porcelain &>/dev/null; then
		declare _unsafe_ref
		_unsafe_ref=$(command git symbolic-ref -q HEAD 2>/dev/null)
		declare _stripped_ref="${_unsafe_ref##refs/heads/}"
		declare _clean_ref="${_stripped_ref//[^a-zA-Z0-9\/]/-}"
		if [[ -n ${_clean_ref} ]]; then
			if [[ ${_prompt_nerd_font} == "true" ]]; then
				_prompt::generate "${_prompt_wrapper:0:1}${_git_nerd_symbol} ${_clean_ref}${_prompt_wrapper:1:1}|${_git_module_color}"
			else
				_prompt::generate "${_prompt_wrapper:0:1}${_git_module_symbol} ${_clean_ref}${_prompt_wrapper:1:1}|${_git_module_color}"
			fi
		fi
	fi
}
