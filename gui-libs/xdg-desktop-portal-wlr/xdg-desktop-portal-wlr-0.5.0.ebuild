# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit meson

DESCRIPTION="xdg-desktop-portal backend for wlroots"
HOMEPAGE="https://github.com/emersion/xdg-desktop-portal-wlr"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/emersion/${PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/emersion/${PN}/releases/download/v${PV}/${P}.tar.gz"
	KEYWORDS="~amd64"
fi

LICENSE="MIT"
SLOT="0/9999"
IUSE="elogind systemd"
REQUIRED_USE="?? ( elogind systemd )"

DEPEND="
	>=media-video/pipewire-0.3.34:=
	dev-libs/inih
	dev-libs/wayland
	|| (
		systemd? ( >=sys-apps/systemd-237 )
		elogind? ( >=sys-auth/elogind-237 )
		sys-libs/basu
	)
"
RDEPEND="
	${DEPEND}
	sys-apps/xdg-desktop-portal
"
BDEPEND="
	dev-libs/wayland-protocols
	dev-util/meson
	virtual/pkgconfig
"

src_configure() {
	local emesonargs=(
		"-Dwerror=false"
	)
	if use systemd; then
		emesonargs+=(-Dsd-bus-provider=systemd)
	elif use elogind; then
		emesonargs+=(-Dsd-bus-provider=elogind)
	else
		emesonargs+=(-Dsd-bus-provider=basu)
	fi
	meson_src_configure
}
