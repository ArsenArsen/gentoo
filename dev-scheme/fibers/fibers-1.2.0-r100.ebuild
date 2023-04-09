# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GUILE_COMPAT=( 2_2 3_0 )
inherit autotools guile

DESCRIPTION="Lightweight concurrency facility for Guile Scheme"
HOMEPAGE="https://github.com/wingo/fibers/
	https://github.com/wingo/fibers/wiki/Manual/"
SRC_URI="https://github.com/wingo/${PN}/archive/v${PV}.tar.gz
	-> ${P}.tar.gz"

LICENSE="LGPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="strip"

RDEPEND="${GUILE_DEPS}"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}/${PN}-1.2.0-rename-scm-pipe2.patch"
)

src_prepare() {
	default

	# http://debbugs.gnu.org/cgi/bugreport.cgi?bug=38112
	find "${S}" -name "*.scm" -exec touch {} + || die

	eautoreconf
}

src_install() {
	guile_src_install

	find "${D}" -name "*.la" -delete || die
}
