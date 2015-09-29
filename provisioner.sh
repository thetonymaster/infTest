#!/bin/sh

# This script will make sure that a puppet_master service
# gets installed in the server where the script is executed

# To run the script:
#
# /// To install puppetmaster for environment iaas.
# If env is not provided only puppetmaster service will be installed.
# ./provisioner.sh master iaas
#
# /// To install normal agent
# ./provisioner.sh

txtrst=$(tput sgr0) # Text reset
txtred=$(tput setaf 1) # Red
txtgrn=$(tput setaf 2) # Green
txtylw=$(tput setaf 3) # Yellow
txtblu=$(tput setaf 4) # Blue
txtbld=$(tput bold)

if [ "$1" = "master" ];
then
    echo "Will install Master"
    package="puppetmaster"
    manifest="site.pp"
    env_parameter="--environment $2"
    environment=${env_parameter:-}
    iaasrepo="https://AAlvz:a3ce3870e2511de8eefba33227f88e11e9f7638c@github.com/AAlvz/iaas.git"
else
    echo "Will install Agent"
    package="puppet"
    manifest="site.pp" # the manifest may change in the future
    hostname=$(hostname)
    initpp="https://raw.githubusercontent.com/AAlvz/iaas/master/modules/base/manifests/init.pp?token=ADW_KVa78GS5KOvxgg_5g-a08Zvi3JO0ks5V44IjwA%3D%3D"
    hierayaml="https://raw.githubusercontent.com/AAlvz/iaas/master/hiera.yaml?token=ADW_KbDZWNN9i1JBxZBRbHyHruhhVmt4ks5V44wowA%3D%3D"
    hostsyaml="https://raw.githubusercontent.com/AAlvz/iaas/master/hieradata/hosts.yaml?token=ADW_KenC_sRu1i0tMvho1U3NU3BcNdfoks5V44K7wA%3D%3D"
    puppetconfagent="https://raw.githubusercontent.com/AAlvz/iaas/master/modules/base/templates/puppet.conf.agent?token=ADW_KUl6KkOroNJGX2WdVdLAiMrrKm-cks5V5LI7wA%3D%3D"
fi

is_sudo()
{
    echo "Verifying sudo"
    if [ "$(whoami)" != 'root' ];
    then
        echo "Currently you are user $(whoami) \n${txtbld}${txtred}PLEASE RUN AS SUDO.${txtrst}"
        exit 1
    else
        return 0
    fi
}

is_installed()
{
    dpkg -s $package > /dev/null
    installed=$?
    if [ ! $installed -eq "0" ];
    then
        echo "$package not installed."
        return 1
    else
        echo "$package already installed."
        return 0
    fi
}

install_puppet()
{
    if ! is_installed;
    then
        echo "${txtblu}Installing $package package${txtrst}"
        apt-get update --fix-missing && apt-get install -y $package
    fi
}

install_dependencies()
{
    echo "${txtblu}Installing dependencies${txtrst}"
    apt-get install -y git
    dpkg -s git > /dev/null
    git_installed=$?
    if [ ! $git_installed -eq "0" ];
    then
        install_dependencies
    fi
}

prepare_puppet_files()
{

    is_installed

    # Make sure Manifests and Module files are
    # in the puppet path. /etc/puppet/{modules,manifests}

    # This will be done cloning the repository with the
    # proper files (puppetmaster modules and manifests)
    # into the puppet config path.

    # Vagrant Environment.
    # As a first version, the cloning will be replaced copying
    # the files located in /vagrant into the puppet path.
    echo "Copying modules and manifests folders"
    virtual=`facter virtual`
    if [ ! "$virtual" = "virtualbox" ]
    then
        if [ "$package" = "puppetmaster" -a "$environment" = "--environment iaas" ]
        then
            echo "${txtblu} Preparing puppetMASTER files${txtrst}"
            if [ ! -d "/etc/puppet/iaas" ]
            then
                git clone $iaasrepo /etc/puppet/iaas
            fi
        else
            echo "${txtblu} Preparing puppet agent files${txtrst}"
            mkdir -p /etc/puppet/modules
            mkdir -p /etc/puppet/modules/base/
            mkdir -p /etc/puppet/modules/base/manifests
            mkdir -p /etc/puppet/modules/base/templates
            mkdir -p /etc/puppet/iaas/
            mkdir -p /etc/puppet/iaas/hieradata/
            wget -q $initpp    -O /etc/puppet/modules/base/manifests/init.pp
            wget -q $hierayaml -O /etc/puppet/hiera.yaml
            wget -q $puppetconfagent -O /etc/puppet/modules/base/templates/puppet.conf.agent
            wget -q $hostsyaml -O /etc/puppet/iaas/hieradata/hosts.yaml
        fi
    else
        echo "${txtblu} Virtual machine. Vagrantfile will rise.${txtrst}"
    fi
}

provision_server()
{
    if [ ! "$virtual" = "virtualbox" ]
    then
        if [ "$package" = "puppetmaster" ]
        then
            puppet apply /etc/puppet/iaas/manifests/$manifest --modulepath=/etc/puppet/iaas/environments/iaas/modules/ --hiera_config /etc/puppet/iaas/hiera.yaml $environment
        else
            puppet apply --modulepath=/etc/puppet/modules -e "include base"
        fi
    fi
}

main()
{
    install_dependencies
    install_puppet
    prepare_puppet_files
    provision_server
}

# This script should run as super user.
is_sudo
main
