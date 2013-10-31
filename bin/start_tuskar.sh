#!/bin/bash
INSTALL_DIR=/opt/stack
cd $INSTALL_DIR/tuskar
source .tox/venv/bin/activate
nohup tuskar-api --config-file etc/tuskar/tuskar.conf --debug > $INSTALL_DIR/tuskar/log/api.log 2>&1 &

cd $INSTALL_DIR/horizon
source .venv/bin/activate
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
nohup tools/with_venv.sh ./manage.py runserver 0.0.0.0:8080 > $INSTALL_DIR/horizon/log/horizon.log 2>&1 &
