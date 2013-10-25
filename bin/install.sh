UNDERCLOUDRC=/etc/sysconfig/undercloudrc
INSTALL_DIR=/opt/stack
NOVA_INSTALL_DIR=/usr/lib/python2.7/site-packages/nova
BASE_DIR=`dirname $0`/../

# Install deps
sudo yum -y install python-devel swig openssl-devel python-pip mysql-devel libxml2-devel libxslt-devel tox patch
sudo easy_install nose
sudo pip install virtualenv setuptools-git flake8 tox

# Patch Nova - Requires a Nova Restart
cd $BASE_DIR/patches/nova
sudo find $NOVA_INSTALL_DIR -name "*.pyc" -exec rm -rf {} \;
sudo find . -name "*.*" -exec patch $NOVA_INSTALL_DIR/{} {} \;
sudo service openstack-nova-api restart

# Source credentials
sudo source $UNDERCLOUDRC

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
tuskar-dbsync --config-file etc/tuskar/tuskar.conf

# Run Tuskar API service
mkdir $INSTALL_DIR/tuskar/log/
nohup tuskar-api --config-file etc/tuskar/tuskar.conf --debug > $INSTALL_DIR/tuskar/log/api.log 2>&1 &

# Setup Tuskar UI

cd $INSTALL_DIR
git clone git://github.com/openstack/horizon.git
git clone https://github.com/openstack/tuskar-ui

# Create symbolic link to tuskar-ui
cd horizon
ln -s ../tuskar-ui/tuskar_ui

# Install deps following tuskar-ui readme steps
cp ../tuskar-ui/local_settings.py.example openstack_dashboard/local/local_settings.py
python tools/install_venv.py
source .venv/bin/activate
sudo pip install git+http://github.com/openstack/python-tuskarclient.git

#./run_tests.sh

# Open up Port for remote access
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT

mkdir $INSTALL_DIR/horizon/log
nohup tools/with_venv.sh ./manage.py runserver 0.0.0.0:8080 > $INSTALL_DIR/horizon/log/horizon.log 2>&1 &
