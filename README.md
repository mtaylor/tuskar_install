tuskar install
==============


This install script is designed to run on top of Undercloud Live Images, see: https://github.com/agroup/undercloud-live/.  It is not tested and therefore not guarentted to work on any other OpenStack installation.



Prerequisite
-------------

To install tuskar using this script, you **MUST** first run through all steps: 1 - 28 from this guide:

https://github.com/agroup/undercloud-live/blob/slagle/package/README.md#runninginstalling-2-node

Install 
--------

Once you have completed all steps in the above Guide do the following:


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

        # Each Rack in the Associative Array can take a string of MAC address separated by spaces.

1. [CONTROL] Run the Create Node Script

        ./bin/create_racks.sh

1. [HOST]/[BROWSER] Navigate to <undercloud-control-ip>:8080 and log in.

    Login is admin, password is unset.

        # If working on a remote machine without X you may want to setup a tunnel (and proxy in browser)
        ssh -D 8080 -C -N stack@lab12

1. [BROWSER] Create a control resource class.

        # Be sure to associate the correct rack with this resource class.
        # Ensure you choose the overcloud-control image

1. [BROWSER] Create a compute resource class.

        # Be sure to associate the correct rack with this resource class.
        # Ensure you choose teh overcloud-compute image

1. [BROWSER] Click provision racks button.

1. [BROWSER] Check the status of the overcloud.

1. [CONTROL] Once complete follow on from step: 26 here: https://github.com/agroup/undercloud-live/blob/slagle/package/README.md#runninginstalling-2-node
