Name:           fedora-laptop-full-setup
Version:        1.0.5
Release:        1%{?dist}
Summary:        Fedora Laptop Full Setup Script

License:        MIT
URL:            https://github.com/FERNLabs-SW/fedora-laptop-full-setup
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  tar
Requires:       bash

%description
Automated Fedora laptop setup script that installs drivers, firmware, and utilities.

%prep
%setup -q

%build
# Nothing to build; this is just a script

%install
mkdir -p %{buildroot}/usr/local/bin
install -m 0755 fedora-laptop-full-setup.sh %{buildroot}/usr/local/bin/fedora-laptop-full-setup

%files
/usr/local/bin/fedora-laptop-full-setup

%changelog
* Mon Nov 18 2025 Rich FERNLabs-SW <fernlabs@icloud.com> - 1.0.5-1
- Added SPEC file to repo root
- Updated build structure to be self-contained
