UNDERCLOUDRC=/etc/sysconfig/undercloudrc
INSTALL_DIR=/opt/stack

# Install deps
sudo yum -y install python-devel swig openssl-devel python-pip mysql-devel libxml2-devel libxslt-devel tox
sudo easy_install nose
sudo pip install virtualenv setuptools-git flake8 tox

# Source credentials and change install dir
source $UNDERCLOUDRC

# Setup Tuskar Core
cd $INSTALL_DIR
git clone https://github.com/openstack/tuskar
cd tuskar

## Configure Tuskar Core
cp etc/tuskar/tuskar.conf.sample etc/tuskar/tuskar.conf
echo "
# Tuskar Core Credentials
username=$OS_USERNAME
password=$OS_PASSWORD
tenant_name=$OS_TENANT_NAME
auth_url=$OS_AUTH_URL
insecure=True
" >> etc/tuskar/tuskar.conf

## Create virtual environment and install Tuskar Core deps
tox -evenv -- echo 'done'
source .tox/venv/bin/activate
pip install -r requirements.txt
pip install -r test-requirements.txt

# Setup Tuskar UI

cd $INSTALL_DIR
git clone https://github.com/openstack/tuskar-ui

