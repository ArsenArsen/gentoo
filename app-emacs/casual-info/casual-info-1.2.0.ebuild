# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

NEED_EMACS=29.3
inherit elisp

DESCRIPTION="An opinionated Transient porcelain for the Emacs Info reader"
HOMEPAGE="https://github.com/kickingvegas/casual-info"
SRC_URI="
	https://github.com/kickingvegas/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz
"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	app-emacs/casual-lib
"
DEPEND="${RDEPEND}"

SITEFILE="50${PN}-gentoo.el"

src_compile() {
	local -x BYTECOMPFLAGS="-L lisp"
	elisp-compile lisp/*.el
	elisp-make-autoload-file
}

src_install() {
	elisp-install "${PN}" lisp/*.{el,elc} "${PN}-autoloads.el"
	elisp-make-site-file "${SITEFILE}" "${PN}" \
						 "(load \"@SITELISP@/${PN}-autoloads\")"
}
