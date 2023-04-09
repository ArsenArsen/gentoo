# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GUILE_COMPAT=( 3_0 2_2 2_0 )
inherit guile-single

DESCRIPTION="A simple, functional, hackable static site generator for GNU Guile"
HOMEPAGE="https://dthompson.us/projects/haunt.html"
SRC_URI="https://files.dthompson.us/haunt/${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
REQUIRED_USE="${GUILE_REQUIRED_USE}"

RDEPEND="${GUILE_DEPS}"
DEPEND="${RDEPEND}"
