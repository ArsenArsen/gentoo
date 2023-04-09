# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: guile-utils.eclass
# @MAINTAINER:
# Gentoo Scheme project <scheme@gentoo.org>
# @AUTHOR:
# Author: Arsen Arsenović <arsen@gentoo.org>
# Inspired by prior work in the Gentoo Python ecosystem.
# @BLURB: Common code between GNU Guile-related eclasses and ebuilds.
# @SUPPORTED_EAPIS: 8
# @DESCRIPTION:
# This eclass contains various bits of common code between
# dev-scheme/guile, Guile multi-implementation ebuilds and Guile
# single-implementation ebuilds.

case "${EAPI}" in
	7|8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ ! "${_GUILE_UTILS}" ]]; then
_GUILE_UTILS=foo

inherit toolchain-funcs

BDEPEND="virtual/pkgconfig"

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

# @FUNCTION: guile_check_compat
# @DESCRIPTION:
# Checks that GUILE_COMPAT is set to an array, and has no invalid
# values.
guile_check_compat() {
	debug-print-function ${FUNCNAME} "${@}"

	if ! [[ $(declare -p GUILE_COMPAT) =~ 'declare -a '* ]]; then
		die "GUILE_COMPAT not set to an array"
	fi

	if [[ ${#GUILE_COMPAT[@]} -eq 0 ]]; then
		die "GUILE_COMPAT is empty"
	fi
}

guile_check_compat

# @ECLASS_VARIABLE: GUILE_REQ_USE
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# Specifies a USE dependency string for all versions of Guile in
# GUILE_COMPAT.
#
# @EXAMPLE:
# GUILE_REQ_USE="deprecated"

# @ECLASS_VARIABLE: GUILE_USEDEP
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# This variable is populated with a USE-dependency string which can be
# used to depend on other Guile multi-implementation packages.
# This variable is not usable from guile-single packages.

# @ECLASS_VARIABLE: GUILE_DEPS
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# Contains the dependency string for the compatible Guile runtimes.

# @FUNCTION: guile_set_common_vars
# @USAGE: guile_set_common_vars
# @VARIABLE: QA_PREBUILT
# @DESCRIPTION:
# Sets common variables that apply to all Guile packages, namely,
# QA_PREBUILT.
guile_set_common_vars() {
	debug-print-function ${FUNCNAME} "${@}"

	# These aren't strictly speaking prebuilt. but they do generated a
	# nonstandard ELF object.
	if [[ -z ${QA_PREBUILT} ]]; then
		QA_PREBUILT="${EPREFIX}/usr/$(get_libdir)/guile/*/site-ccache/*"
	fi
}

# @FUNCTION: guile_filter_pkgconfig_path
# @USAGE: <acceptable slots>...
# @DESCRIPTION:
# Alters ${PKG_CONFIG_PATH} such that it does not contain any Guile
# slots besides the ones required by the caller.
guile_filter_pkgconfig_path() {
	debug-print-function ${FUNCNAME} "${@}"

	local filtered_path= unfiltered_path path
	IFS=: read -ra unfiltered_path <<<"$PKG_CONFIG_PATH"
	debug-print "Unfiltered PKG_CONFIG_PATH:" "${unfiltered_path[@]}"
	for p in "${unfiltered_path[@]}"; do
		for v in "$@"; do
			# Exclude non-selected versions.
			[[ "$p" == */usr/share/guile-data/*/pkgconfig ]] \
				&& [[ "$p" != */usr/share/guile-data/"$v"/pkgconfig ]] \
				&& continue 2
		done

		# Add separator, if some data already exists.
		[[ "${filtered_path}" ]] && filtered_path+=:

		filtered_path+="${p}"
	done

	debug-print "${FUNCNAME}: Constructed PKG_CONFIG_PATH: ${filtered_path}"
	PKG_CONFIG_PATH="$filtered_path"
}

# @FUNCTION: guile_generate_depstrings
# @USAGE: <prefix> <depop>
# @DESCRIPTION:
# Generates GUILE_REQUIRED_USE/GUILE_DEPS/GUILE_USEDEP based on
# GUILE_COMPAT, and populates IUSE.
guile_generate_depstrings() {
	debug-print-function ${FUNCNAME} "${@}"

	# Generate IUSE, REQUIRED_USE, GUILE_USEDEP
	local prefix="$1" depop="$2"
	GUILE_USEDEP=""
	local ver uses=()
	for ver in "${GUILE_COMPAT[@]}"; do
		[[ -n ${GUILE_USEDEP} ]] && GUILE_USEDEP+=","
		uses+=("${prefix}_${ver}")
		GUILE_USEDEP+="${prefix}_${ver}"
	done
	GUILE_REQUIRED_USE="${depop} ( ${uses[@]} )"
	IUSE="${uses[@]}"
	debug-print "${FUNCNAME}: requse ${GUILE_REQUIRED_USE}"
	debug-print "${FUNCNAME}: generated ${uses[*]}"
	debug-print "${FUNCNAME}: iuse ${IUSE}"

	# Generate GUILE_DEPS
	local base_deps=()
	local requse="${GUILE_REQ_USE+[}${GUILE_REQ_USE:-}${GUILE_REQ_USE+]}"
	for ver in "${GUILE_COMPAT[@]}"; do
		base_deps+="
			${prefix}_${ver}? (
				dev-scheme/guile:${ver/_/.}${requse}
			)
		"
	done
	GUILE_DEPS="${base_deps[*]}"
	debug-print "${FUNCNAME}: GUILE_DEPS=${GUILE_DEPS}"
	debug-print "${FUNCNAME}: GUILE_USEDEP=${GUILE_USEDEP}"
}

# @FUNCTION: guile_unstrip_ccache
# @DESCRIPTION:
# Marks site-ccache files not to be stripped.  Operates on ${ED}.
guile_unstrip_ccache() {
	debug-print-function ${FUNCNAME} "${@}"

	local ccache
	while read -r -d $'\0' ccache; do
		debug-print "${FUNCNAME}: ccache found: ${ccache#.}"
		dostrip -x "${ccache#.}"
	done < <(cd "${D}" || die; find . \
				  -name '*.go' \
				  -path "*/usr/$(get_libdir)/guile/*/site-ccache/*" \
				  -print0 || die) || die
}

# @FUNCTION: guile_export
# @USAGE: [GUILE|GUILD|GUILE_SITECCACHEDIR|GUILE_SITEDIR]...
# @DESCRIPTION:
# Exports a given variable for the selected Guile variant.
#
# Supported variables are:
#
# - GUILE - Path to the Guile executable,
# - GUILD - Path to the guild executable,
# - GUILE_SITECCACHEDIR - Path to the site-ccache directory,
# - GUILE_SITEDIR - Path to the site Scheme directory
guile_export() {
	local gver
	if [[ "${GUILE_CURRENT_VERSION}" ]]; then
		gver="${GUILE_CURRENT_VERSION}"
	elif [[ "${GUILE_SELECTED_TARGET}" ]]; then
		gver="${GUILE_SELECTED_TARGET}"
	else
		die "Calling guile_export outside of a Guile build context?"
	fi

	_guile_pcvar() {
		$(tc-getPKG_CONFIG) --variable="$1" guile-"${gver}" || die
	}

	for var; do
		case "${var}" in
			GUILE) export GUILE="$(_guile_pcvar guile)" ;;
			GUILD) export GUILD="$(_guile_pcvar guild)" ;;
			GUILE_SITECCACHEDIR)
				GUILE_SITECCACHEDIR="$(_guile_pcvar siteccachedir)"
				export GUILE_SITECCACHEDIR
				;;
			GUILE_SITEDIR)
				export GUILE_SITEDIR="$(_guile_pcvar sitedir)"
				;;
			*) die "Unknown variable '${var}'" ;;
		esac
	done
}

fi  # _GUILE_UTILS
