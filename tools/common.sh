#!/bin/bash

export TOOLS_HOME=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Setup git
function setup_git()
{
    git config --global --get user.name || \
        git config --global user.name "$USER"
    git config --global --get user.email || \
        git config --global user.email "$USER@redhat.com"
}

function install_rvm_if_ruby_is_outdated()
{
    if ! ruby -e 'exit Gem::Version.new("2.2") <= Gem::Version.new(RUBY_VERSION)' ; then
        # see http://10.66.129.213/index.php/archives/372/ for RHEL notes
        gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
        curl -sSL https://get.rvm.io | bash -s stable --ruby
        source /usr/local/rvm/scripts/rvm
    fi
}
#################################################
############ system-wide functions ##############
#################################################

# Prints operating system
function os_type()
{
    if [ -f /etc/os-release ]; then
       if cat /etc/os-release | grep -iq 'ID=fedora'; then
          version=`sed -rn 's/^VERSION_ID=([0-9]+)$/\1/p' < /etc/os-release`
          if [ $version -ge 22 ]; then
            echo fedora_dnf; return 0
          else
            echo fedora ; return 0
          fi
        fi
        cat /etc/os-release | grep -i -q 'debian' && { echo "debian"; return 0; }
        cat /etc/os-release | grep -i -q 'ubuntu' && { echo "ubuntu"; return 0; }
        cat /etc/os-release | grep -i -q "CentOS .* 7" && { echo "centos7"; return 0; }
        cat /etc/os-release | grep -i -q "Red Hat .* 7" && { echo "rhel7"; return 0; }
        cat /etc/os-release | grep -i -q "Red Hat .* 6" && { echo "rhel6"; return 0; }
        cat /etc/os-release | grep -i -q 'mint' && { echo "mint"; return 0; }
    fi
    echo 'ERROR: Unsupported OS type'
    return 1
}

# Will return the method of installing system packages: DEB/YUM
function os_pkg_method()
{
  if [ "$(os_type)" == "fedora_dnf" ]; then
    echo DNF
  elif [ "$(os_type)" == "fedora" ] || [[ "$(os_type)" =~ "rhel" ]] || [[ "$(os_type)" =~ "centos" ]]; then
    echo "YUM"
  elif [ "$(os_type)" == "ubuntu" ] || [ "$(os_type)" == "debian" ] || [ "$(os_type)" == "mint" ]; then
    echo "DEB"
  else
    echo "TAR"
  fi
}

# Return 'sudo' if the user's not root
function need_sudo()
{
    if [ `id -u` == "0" ]; then
        echo ''
    else
        echo 'sudo'
    fi
}

# Setup sudo configuration
function setup_sudo()
{
    $(need_sudo) grep CUCUSHIFT_SETUP /etc/sudoers && return
    $(need_sudo) cat > /etc/sudoers <<END
# CUCUSHIFT_SETUP #
Defaults    env_reset
Defaults    env_keep =  "COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR LS_COLORS"
Defaults    env_keep += "MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE"
Defaults    env_keep += "LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES"
Defaults    env_keep += "LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE"
Defaults    env_keep += "LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY"

Defaults    secure_path = /usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

root    ALL=(ALL)       ALL
%wheel  ALL=NOPASSWD: ALL
# CUCUSHIFT_SETUP #
END
}

function random_email()
{
    echo "cucushift+$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 10)@redhat.com"
}

function get_random_str()
{
    LEN=10
    [ -n "$1" ] && LEN=$1
    echo "$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c $LEN)"
}
