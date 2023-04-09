# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: guile-single.eclass
# @PROVIDES: guile-utils
# @MAINTAINER:
# Gentoo Scheme project <scheme@gentoo.org>
# @AUTHOR:
# Author: Arsen Arsenović <arsen@gentoo.org>
# Inspired by prior work in the Gentoo Python ecosystem.
# @BLURB: Utilities for packages that build against a single Guile.
# @SUPPORTED_EAPIS: 8
# @PROVIDES: guile-utils
# @DESCRIPTION:
# This eclass facilitates packages building against a single slot of
# Guile, which is normally something that uses Guile for extending, like
# GNU Make, or for programs built in Guile, like Haunt.

case "${EAPI}" in
	7|8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ ! "${_GUILE_SINGLE_R1}" ]]; then
_GUILE_SINGLE_R1=foo

inherit guile-utils

# @ECLASS_VARIABLE: GUILE_COMPAT
# @REQUIRED
# @PRE_INHERIT
# @DESCRIPTION:
# List of acceptable versions of Guile.  For instance, setting this
# variable like below will allow the package to be built against either
# Guile 2.2 or 3.0:
#
# @CODE
# GUILE_COMPAT=( 2_2 3_0 )
# @CODE

_guile_setup() {
	debug-print-function ${FUNCNAME} "${@}"

	# Inhibit generating the GUILE_USEDEP.  This variable is not usable
	# for single packages.
	local GUILE_USEDEP
	guile_generate_depstrings guile_single_target ^^
}

_guile_setup
unset -f _guile_setup

# @FUNCTION: guile_gen_cond_dep
# @USAGE: <dependency> [<pattern>...]
# @DESCRIPTION:
# Takes a string that uses (quoted) ${GUILE_SINGLE_USEDEP} and
# ${GUILE_MULTI_USEDEP} markers as placeholders for the correct USE
# dependency strings for each compatible slot.
#
# If the pattern is provided, it is taken to be list of slots to
# generate the dependency string for, otherwise, ${GUILE_COMPAT[@]} is
# taken.
#
# @EXAMPLE:
# RDEPEND="
#	$(guile_gen_cond_dep '
#		dev-scheme/guile-zstd[${GUILE_MULTI_USEDEP}]
#		dev-scheme/guile-config[${GUILE_SINGLE_USEDEP}]
#	')
# "
guile_gen_cond_dep() {
	debug-print-function ${FUNCNAME} "${@}"

	local deps="$1"
	shift

	local candidates=( "$@" )
	if [[ ${#candidates[@]} -eq 0 ]]; then
		candidates=( "${GUILE_COMPAT[@]}" )
	fi

	local candidate
	for candidate in "${candidates[@]}"; do
		local s="guile_single_target_${candidate}" \
			  m="guile_targets_${candidate}" \
			  subdeps=${deps//\$\{GUILE_SINGLE_USEDEP\}/${s}}
		subdeps=${subdeps//\$\{GUILE_MULTI_USEDEP\}/${m}}
		cat <<-EOF
		guile_single_target_${candidate}? (
			${subdeps}
		)
		EOF
	done
}

# @FUNCTION: guile-single_pkg_setup
# @DESCRIPTION:
# Sets up the PKG_CONFIG_PATH with the appropriate GUILE_SINGLE_TARGET.
guile-single_pkg_setup() {
	debug-print-function ${FUNCNAME} "${@}"

	guile_set_common_vars

	GUILE_SELECTED_TARGET=
	for ver in "${GUILE_COMPAT[@]}"; do
		debug-print "${FUNCNAME}: checking for ${ver}"
		use "guile_single_target_${ver}" || continue
		GUILE_SELECTED_TARGET="${ver/_/.}"
		break
	done

	[[ ${GUILE_SELECTED_TARGET} ]] \
		|| die "No GUILE_SINGLE_TARGET specified."

	export PKG_CONFIG_PATH
	guile_filter_pkgconfig_path "${GUILE_SELECTED_TARGET}"
}

# @FUNCTION: guile-single_src_install
# @DESCRIPTION:
# Runs the default install stage, and then marks ccache files not to be
# stripped using guile_unstrip_ccache.
guile-single_src_install() {
	debug-print-function ${FUNCNAME} "${@}"

	default
	guile_unstrip_ccache
}

EXPORT_FUNCTIONS pkg_setup src_install

fi  # _GUILE_SINGLE_R1
