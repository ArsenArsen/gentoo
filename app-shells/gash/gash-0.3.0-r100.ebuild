# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GUILE_COMPAT=( 2_2 3_0 )
inherit guile-single

DESCRIPTION="POSIX-compatible shell written in Guile Scheme"
HOMEPAGE="https://savannah.nongnu.org/projects/gash/"
SRC_URI="mirror://nongnu/${PN}/${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="strip"

RDEPEND="${GUILE_DEPS}"
DEPEND="${RDEPEND}"
BDEPEND="sys-apps/texinfo"

src_prepare() {
	default

	# http://debbugs.gnu.org/cgi/bugreport.cgi?bug=38112
	find "${S}" -name "*.scm" -exec touch {} + || die
}
