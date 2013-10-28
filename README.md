tuskar install
==============


This install script is designed to run on top of Undercloud Live Images, see: https://github.com/agroup/undercloud-live/.  It is not tested and therefore not guarentted to work on any other OpenStack installation.

To install first run through the steps here: https://github.com/agroup/undercloud-live/blob/slagle/package/README.md#runninginstalling-2-node

Once you have done this do the following:

1. [CONTROL]  Unprovision the overcloud:

        heat stack-delete overcloud

1. [CONTROL] Checkout Tuskar Install 

        cd ~
        git clone https://github.com/mtaylor/tuskar_install.git
        cd tuskar_install

1. [CONTROL] Install and configure Tuskar

        # check the variables at the top of ./bin/install.sh are correct then run:
        ./bin/install.sh

1. [CONTROL] Next add the MAC address to the top of /bin/create_nodes.sh

        ./bin/create_nodes.sh

1. [HOST]/[BROWSER] Navigate to <undercloud-control-ip>:8080 and log in

        # If working on a remote machine without X you may want to setup a tunnel:
        ssh -D 8080 -C -N stack@lab12

1. [BROWSER] Create a control resource class.  Be sure to associate the correct rack with this resource class

1. [BROWSER] Create a compute resource class.  Be sure to associate the correct rack with this resource class.

1. [BROWSER] Click provision racks button.

