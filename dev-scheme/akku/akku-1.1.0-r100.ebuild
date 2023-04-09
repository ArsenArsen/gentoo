# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GUILE_COMPAT=( 2_2 3_0 )
inherit autotools guile-single

DESCRIPTION="Language package manager for Scheme"
HOMEPAGE="https://akkuscm.org/"

if [[ "${PV}" == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.com/akkuscm/${PN}.git"
else
	SRC_URI="https://gitlab.com/akkuscm/${PN}/-/archive/v${PV}/${PN}-v${PV}.tar.gz"
	KEYWORDS="~amd64"
	S="${WORKDIR}/${PN}-v${PV}"
fi

LICENSE="GPL-3+"
SLOT="0"
# tests require network access
RESTRICT="strip test"

RDEPEND="
	${GUILE_DEPENDS}
	net-misc/curl[ssl]
"
DEPEND="${RDEPEND}"

# Guile generates ELF files without use of C or machine code
# It's a portage's false positive. bug #677600
# Despite the eclass setting it, it's set again here as Akku uses custom
# paths for its ccache.
QA_PREBUILT='*[.]go'

src_prepare() {
	default

	# http://debbugs.gnu.org/cgi/bugreport.cgi?bug=38112
	find "${S}" -name "*.scm" -exec touch {} + || die

	eautoreconf
}

src_compile() {
	touch bootstrap.db || die

	emake
}
