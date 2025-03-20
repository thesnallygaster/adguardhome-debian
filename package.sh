#!/bin/bash

ADGUARDHOME_VERSION="0.107.58"
DEB_REVISION="1"
ARCHITECTURE="$(dpkg --print-architecture)"

cat << EOF > /etc/apt/sources.list.d/debian.sources
Types: deb
URIs: http://ftp.pl.debian.org/debian
Suites: bookworm bookworm-updates
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: bookworm-security
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

if [ -n "${APT_PROXY_URL}" ]; then
	echo "Acquire::http { Proxy \"${APT_PROXY_URL}\"; }" > /etc/apt/apt.conf.d/01proxy
fi

apt update
apt upgrade -y
apt install -y --no-install-recommends \
	ca-certificates \
	curl \
	zstd \
	tree

mkdir -p /build
cd /build
curl -LO https://github.com/AdguardTeam/AdGuardHome/releases/download/v${ADGUARDHOME_VERSION}/AdGuardHome_linux_${ARCHITECTURE}.tar.gz
tar xvf AdGuardHome_linux_${ARCHITECTURE}.tar.gz
mkdir -p /build/destdir/usr/bin \
	/build/destdir/etc/adguardhome
install -Dm 755 AdGuardHome/AdGuardHome /build/destdir/usr/bin/adguardhome
install -Dm 644 /distrib/config.yaml /build/destdir/etc/adguardhome/config.yaml
tree /build/destdir

cd /build
apt install -y --no-install-recommends \
	build-essential \
	ruby-rubygems \
	openssh-client
gem install fpm
cd destdir
fpm -a native -s dir -t deb -p ../adguardhome_"${ADGUARDHOME_VERSION}"-"${DEB_REVISION}"_"${ARCHITECTURE}".deb --name adguardhome --version "${ADGUARDHOME_VERSION}" --iteration "${DEB_REVISION}" --deb-compression zst --after-install /distrib/postinst --after-remove /distrib/postrm --deb-systemd /distrib/adguardhome.service --deb-systemd-auto-start --deb-systemd-enable --description "Description=AdGuard Home: Network-level blocker" --url "https://github.com/AdguardTeam/AdGuardHome" --maintainer "Damian Duży <dame@zakonfeniksa.org>" .
