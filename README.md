tuskar install
==============


This install script is designed to run on top of Undercloud Live Images, see: https://github.com/agroup/undercloud-live/.  It is not tested and therefore not guarentted to work on any other OpenStack installation.



Prerequisite
-------------

To install tuskar using this script, you **MUST** first run the steps through
running configure-overcloud.sh from this guide:

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

1. [CONTROL] Next add the MAC address to the top of /bin/create_racks.sh

        # Each Rack in the Associative Array can take a string of MAC address separated by spaces.
        #
        # You need a rack defined for each type of resource class you intend to
        # create.
        #
        # Add MAC addresses to each defined rack for the nodes you intend to
        # provision as that resource type.

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
        # Ensure you choose the overcloud-compute image

1. [BROWSER] Click provision racks button.

1. [BROWSER] Check the status of the overcloud.

1. [CONTROL] Use heat stack-list to check for the overcloud to finish deploying.
             It should show CREATE_COMPLETE in the output.

1. [CONTROL] Configure the overcloud. This performs setup of the overcloud and loads the demo image
             into overcloud glance. (Assumption: you already have the fedora-cloud.qcow2 image on local disk)

        source /etc/sysconfig/undercloudrc
        export OVERCLOUD_IP=$(nova list | grep notcompute.*ctlplane | sed  -e "s/.*=\\([0-9.]*\\).*/\1/")
        source tripleo-overcloud-passwords
        source /opt/stack/tripleo-incubator/overcloudrc
        glance image-create \
                --name user \
                --public \
                --disk-format qcow2 \
                --container-format bare \
                --file fedora-cloud.qcow2
        source /opt/stack/tripleo-incubator/overcloudrc-user
        nova boot --key-name default --flavor m1.tiny --image user demo
        # nova list until the instance is ACTIVE
        nova list
        PORT=$(neutron port-list -f csv -c id --quote none | tail -n1)
        neutron floatingip-create ext-net --port-id "${PORT//[[:space:]]/}"
        # nova list again to see the assigned floating ip
        nova list
        
1. [CONTROL] To discover the IP and URI for overcloud Horizon - you can do this in 2 ways:

        
        1. Using nova list - you want the IP address of the notcompute node
        2. Via the Tuskar UI - using the 'standard' parts of Horizon - go to 'Project' --> 'Instances'
           and you will see the IP address. Again, you want the IP of notcompute (alternatively,
           the instance launced from the 'overcloud-control' image).
           
        You can then use this IP to construct the Horizon URI.   
        



    
