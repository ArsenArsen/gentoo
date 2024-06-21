# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

NEED_EMACS=29.3
inherit elisp

DESCRIPTION="Library package for the Casual porcelains"
HOMEPAGE="https://github.com/kickingvegas/casual-lib"
SRC_URI="
	https://github.com/kickingvegas/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz
"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

SITEFILE="50${PN}-gentoo.el"

src_compile() {
	local -x BYTECOMPFLAGS="-L lisp"
	elisp-compile lisp/*.el
}

src_install() {
	elisp-install "${PN}" lisp/*.{el,elc}
	elisp-make-site-file "${SITEFILE}" "${PN}"
}
