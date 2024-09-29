#!/bin/bash

set -e

# Set variables
PROXYCHAINS_NG_VER=4.17

# Determine DISTTAG based on OS release
if grep -q "release 8" /etc/redhat-release; then
    DISTTAG='el8'
    CRB_REPO="powertools"
elif grep -q "release 9" /etc/redhat-release; then
    DISTTAG='el9'
    CRB_REPO="crb"
fi

# Enable repositories: CRB and EPEL
dnf clean all
dnf install -y epel-release
dnf config-manager --set-enabled ${CRB_REPO}

# Install dependencies
dnf groupinstall -y 'Development Tools'
dnf install -y --allowerasing \
  git \
  automake \
  libtool \
  rpm-build \
  wget \
  make \
  tar \
  nano \
  jq \
  gcc \
  gcc-c++ \
  redhat-rpm-config \
  autoconf \
  pkgconfig \
  gettext \
  which \
  sed --skip-broken

# Download the source code tarball from GitHub releases
cd /tmp
wget "https://github.com/rofl0r/proxychains-ng/archive/refs/tags/v${PROXYCHAINS_NG_VER}.tar.gz" -O proxychains-ng-${PROXYCHAINS_NG_VER}.tar.gz

# Extract the tarball
tar xzf proxychains-ng-${PROXYCHAINS_NG_VER}.tar.gz

# Prepare for building the RPM
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mv proxychains-ng-${PROXYCHAINS_NG_VER}.tar.gz ~/rpmbuild/SOURCES/

# Create the spec file (updated)
cat << 'EOF' > ~/rpmbuild/SPECS/proxychains-ng.spec
Name:           proxychains-ng
Version:        %{version}
Release:        1%{?dist}
Summary:        A hook preloader that allows to proxy applications

License:        GPLv2+
URL:            https://github.com/rofl0r/proxychains-ng
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  gcc, automake, libtool, make, autoconf, pkgconfig

%description
Proxychains-ng is a preloader which hooks calls to sockets in dynamically linked programs and redirects them through one or more proxies.

%prep
%setup -q

%build
# Configure with correct libdir
%configure --prefix=/usr --sysconfdir=/etc/proxychains --libdir=%{_libdir}
make %{?_smp_mflags}

%install
make DESTDIR=%{buildroot} install

# Create additional config files
install -D -m 644 src/proxychains.conf %{buildroot}%{_sysconfdir}/proxychains/proxychains.conf
cp %{buildroot}%{_sysconfdir}/proxychains/proxychains.conf %{buildroot}%{_sysconfdir}/proxychains/proxychains1.conf
cp %{buildroot}%{_sysconfdir}/proxychains/proxychains.conf %{buildroot}%{_sysconfdir}/proxychains/proxychains2.conf
cp %{buildroot}%{_sysconfdir}/proxychains/proxychains.conf %{buildroot}%{_sysconfdir}/proxychains/proxychains3.conf

%files
%license COPYING
%doc README.md
%config(noreplace) %{_sysconfdir}/proxychains/proxychains.conf
%config(noreplace) %{_sysconfdir}/proxychains/proxychains1.conf
%config(noreplace) %{_sysconfdir}/proxychains/proxychains2.conf
%config(noreplace) %{_sysconfdir}/proxychains/proxychains3.conf
%{_bindir}/proxychains4
%{_bindir}/proxychains4-daemon
%{_libdir}/libproxychains4.so*

%changelog
* $(date +"%a %b %d %Y") George Liu <centminmod.com> - %{version}-1
- Initial build for %{name} %{version}
EOF

# Replace %{version} with actual version in spec file
sed -i "s/%{version}/${PROXYCHAINS_NG_VER}/g" ~/rpmbuild/SPECS/proxychains-ng.spec

# Build the RPM using rpmbuild
rpmbuild -ba ~/rpmbuild/SPECS/proxychains-ng.spec --define "dist .${DISTTAG}"

echo
ls -lah ~/rpmbuild/RPMS/x86_64/
echo
ls -lah ~/rpmbuild/SRPMS/
echo

# Move the built RPMs and SRPMs to the workspace for GitHub Actions
mkdir -p /workspace/rpms
cp ~/rpmbuild/SPECS/proxychains-ng.spec /workspace/rpms/
cp ~/rpmbuild/RPMS/x86_64/*.rpm /workspace/rpms/ || echo "No RPM files found in ~/rpmbuild/RPMS/x86_64/"
cp ~/rpmbuild/SRPMS/*.rpm /workspace/rpms/ || echo "No SRPM files found in ~/rpmbuild/SRPMS/"

# Verify the copied files
ls -lah /workspace/rpms/
