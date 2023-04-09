# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GUILE_COMPAT=( 2_2 3_0 )
inherit guile

DESCRIPTION="Colorized REPL for GNU Guile"
HOMEPAGE="https://gitlab.com/NalaGinrut/guile-colorized/"

if [[ "${PV}" == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.com/NalaGinrut/${PN}.git"
else
	# Latest release (before this commit from 2019) was in 2015
	COMMIT_SHA="1625a79f0e31849ebd537e2a58793fb45678c58f"
	SRC_URI="https://gitlab.com/NalaGinrut/${PN}/-/archive/${COMMIT_SHA}.tar.bz2 -> ${P}.tar.bz2"
	KEYWORDS="~amd64"
	S="${WORKDIR}/${PN}-${COMMIT_SHA}"
fi

LICENSE="GPL-3"
SLOT="0"

RDEPEND="${GUILE_DEPS}"
DEPEND="${RDEPEND}"

guile_compile_single() {
	guile_export GUILD

	"${GUILD}" compile -o ice-9/colorized.go "${S}"/ice-9/colorized.scm
}

src_compile() {
	guile_foreach_impl guile_compile_single
}

guile_install_single() {
	guile_export GUILE_SITEDIR GUILE_SITECCACHEDIR
	mkdir -p "${D}${GUILE_SITEDIR}"
	emake -C "${S}" TARGET="${D}${GUILE_SITEDIR}" install
	insinto "${GUILE_SITECCACHEDIR}/ice-9"
	doins ice-9/colorized.go
}

src_install() {
	einstalldocs
	guile_foreach_impl guile_install_single
	guile_unstrip_ccache
}
