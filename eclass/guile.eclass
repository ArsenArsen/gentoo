# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: guile.eclass
# @PROVIDES: guile-utils
# @MAINTAINER:
# Gentoo Scheme project <scheme@gentoo.org>
# @AUTHOR:
# Author: Arsen Arsenović <arsen@gentoo.org>
# Inspired by prior work in the Gentoo Python ecosystem.
# @SUPPORTED_EAPIS: 8
# @BLURB: Utilities for packages multi-implementation Guile packages.
# @DESCRIPTION:
# This eclass facilitates building against many Guile implementations,
# useful for pure Guile libraries and similar.
#
# Packages using this eclass are multibuild packages, and hence, should
# use guile_foreach_impl to wrap stage functions that they implement.

case "${EAPI}" in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ ! "${_GUILE_R1}" ]]; then
_GUILE_R1=foo

inherit guile-utils multibuild

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

	guile_generate_depstrings guile_targets '||'
}

_guile_setup
unset -f _guile_setup

# @ECLASS_VARIABLE: GUILE_SELECTED_TARGETS
# @INTERNAL
# @DESCRIPTION:
# Contains the intersection of GUILE_TARGETS and GUILE_COMPAT.
# Generated in guile_pkg_setup.

# @FUNCTION: guile_pkg_setup
# @DESCRIPTION:
# Sets up eclass-internal variables for this build.
guile_pkg_setup() {
	debug-print-function ${FUNCNAME} "${@}"

	guile_set_common_vars
	GUILE_SELECTED_TARGETS=()
	for ver in "${GUILE_COMPAT[@]}"; do
		debug-print "${FUNCNAME}: checking for ${ver}"
		use "guile_targets_${ver}" || continue
		GUILE_SELECTED_TARGETS+=("${ver/_/.}")
	done
	if [[ "${#GUILE_SELECTED_TARGETS[@]}" -eq 0 ]]; then
		die "No GUILE_TARGETS specified."
	fi
}

# @FUNCTION: guile_copy_sources
# @DESCRIPTION:
# Create a single copy of the package sources for each selected Guile
# implementation.
guile_copy_sources() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS
	MULTIBUILD_VARIANTS=("${GUILE_SELECTED_TARGETS[@]}")

	multibuild_copy_sources
}

# @FUNCTION: _guile_multibuild_wrapper
# @USAGE: <command> [<argv>...]
# @INTERNAL
# @DESCRIPTION:
# Initialize the environment for a single build variant.  See
# guile_foreach_impl.
_guile_multibuild_wrapper() {
	local GUILE_CURRENT_VERSION="${MULTIBUILD_VARIANT}"
	debug-print-function ${FUNCNAME} "${@}" "on ${MULTIBUILD_VARIANT}"

	local -x PKG_CONFIG_PATH="${PKG_CONFIG_PATH}"
	guile_filter_pkgconfig_path "${MULTIBUILD_VARIANT}"
	local ECONF_SOURCE="${S}"
	local -x SLOTTED_D="${T}/dests/image${MULTIBUILD_ID}/"
	local -x SLOTTED_ED="${SLOTTED_D%/}${EPREFIX}/"
	mkdir -p "${BUILD_DIR}" || die
	cd "${BUILD_DIR}" || die
	"$@"
}

# @VARIABLE: SLOTTED_D
# @DESCRIPTION:
# In functions ran by guile_foreach_impl, this variable is set to a new
# ${D} value that the variant being installed should use.

# @VARIABLE: SLOTTED_ED
# @DESCRIPTION:
# In functions ran by guile_foreach_impl, this variable is set to a new
# ${ED} value that the variant being installed should use.  It is
# equivalent to "${SLOTTED_D%/}${EPREFIX}/".

# @VARIABLE: ECONF_SOURCE
# @DESCRIPTION:
# In functions ran by guile_foreach_impl, this variable is set to ${S},
# for convenience.

# @VARIABLE: PKG_CONFIG_PATH
# @DESCRIPTION:
# In functions ran by guile_foreach_impl, PKG_CONFIG_PATH is filtered to
# contain only the current ${MULTIBUILD_VARIANT}.

# @VARIABLE: BUILD_DIR
# @DESCRIPTION:
# In functions ran by guile_foreach_impl, this variable is set to a
# newly-generated build directory for this variant.

# @FUNCTION: guile_foreach_impl
# @USAGE: <command> [<argv>...]
# @DESCRIPTION:
# Runs the given command for each of the selected Guile implementations.
#
# The function will return 0 status if all invocations succeed.
# Otherwise, the return code from first failing invocation will
# be returned.
#
# Each invocation will have the correct PKG_CONFIG_DIR set, as well as a
# SLOTTED_D, SLOTTED_ED for installation purposes, and a new BUILD_DIR,
# in which the wrapped function will be executed, with a pre-configured
# ECONF_SOURCE.
guile_foreach_impl() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS
	MULTIBUILD_VARIANTS=("${GUILE_SELECTED_TARGETS[@]}")

	debug-print "${FUNCNAME}: Running for each of:" \
				"${GUILE_SELECTED_TARGETS[@]}"

	multibuild_foreach_variant _guile_multibuild_wrapper "${@}"
}

# @FUNCTION: _guile_merge_single_root
# @INTERNAL
# @DESCRIPTION:
# Runs a single merge_root step for guile_merge_roots.
_guile_merge_single_root() {
	debug-print-function ${FUNCNAME} "${@}"

	multibuild_merge_root "${SLOTTED_D}" "${D}"
}

# @FUNCTION: guile_merge_roots
# @DESCRIPTION:
# Merges install roots from all slots, diagnosing conflicts.
guile_merge_roots() {
	debug-print-function ${FUNCNAME} "${@}"

	guile_foreach_impl _guile_merge_single_root
}

# Default implementations for a GNU Autoconf-based Guile package.

# @FUNCTION: guile_src_prepare
# @DESCRIPTION:
# Runs the default src_prepare for each selected variant target.
guile_src_prepare() {
	debug-print-function ${FUNCNAME} "${@}"

	guile_foreach_impl default
}

# @FUNCTION: guile_src_configure
# @DESCRIPTION:
# Runs the default src_configure for each selected variant target.
guile_src_configure() {
	debug-print-function ${FUNCNAME} "${@}"

	guile_foreach_impl default
}

# @FUNCTION: guile_src_compile
# @DESCRIPTION:
# Runs the default src_compile for each selected variant target.
guile_src_compile() {
	debug-print-function ${FUNCNAME} "${@}"

	guile_foreach_impl default
}

# @FUNCTION: _guile_default_install_slot
# @INTERNAL
# @DESCRIPTION:
# Imitates the default build system install "substep", but for a given
# ${SLOTTED_D} rather than the usual ${D}.  See guile_src_install.
_guile_default_install_slot() {
	debug-print-function ${FUNCNAME} "${@}"

	if [[ -f Makefile ]] || [[ -f GNUmakefile ]] || [[ -f makefile ]]; then
		emake DESTDIR="${SLOTTED_D}" install
	fi
}

# @FUNCTION: guile_src_install
# @DESCRIPTION:
# Runs the an imitation of the src_install that does the right thing for
# a GNU Build System based Guile package, for each selected variant
# target.  Merges roots after completing the installs.
guile_src_install() {
	debug-print-function ${FUNCNAME} "${@}"

	guile_foreach_impl _guile_default_install_slot
	guile_merge_roots
	guile_unstrip_ccache

	einstalldocs
}

EXPORT_FUNCTIONS pkg_setup src_prepare src_configure src_compile src_install

fi  # _GUILE_R1
