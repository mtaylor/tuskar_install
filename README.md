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

1. [HOST]/[BROWSER] Navigate to <undercloud-control-ip>:8080, log in, and navigate to the Tuskar section of the dashboard.

    The username is admin and the password is unset.

    Since the Tuskar UI is a plugin for Horizon, the user interface will look familiar to those who have used Horizon before.  Click on the Infrastructure tab to reach the Tuskar section.

        # If working on a remote machine without X you may want to setup a tunnel (and proxy in browser)
        ssh -D 8080 -C -N stack@lab12

1. [BROWSER] Create a control resource class.

    Click on the 'Create Class' button to start the resource class creation workflow for a control resource class.  This resource class will be responsible for running shared OpenStack services such as Keystone, Swift and Cinder.

        # Select 'Controller' in the 'Class Type' drop down.
        # Ensure you choose the overcloud-control image.
        # Be sure to associate the correct control rack with this resource class.

1. [BROWSER] Create a compute resource class.

    Click on the 'Create Class' button to start the resource class creation workflow for a compute resource class.  For demonstration purposes we will represent the Amazon EC2 m1 class and create the following flavors:

| Flavor Name | VCPU | RAM (MB) | Root Disk (GB) | Ephemeral Disk (GB) | Swap Disk (MB) |
|:-----------:|:----:|:--------:|:--------------:|:-------------------:|:--------------:|
| tiny        | 1    | 512      | 1              | 0                   | 0              |
| small       | 1    | 2048     | 20             | 0                   | 0              |
| medium      | 2    | 4096     | 40             | 0                   | 0              |
| large       | 4    | 8192     | 80             | 0                   | 0              |
| xlarge      | 8    | 16384    | 160            | 0                   | 0              |

        # Name the resource class 'm1'.
        # Select 'Compute' in the 'Class Type' drop down.
        # Ensure you choose the overcloud-compute image.
        # Create the flavors listed above.
        # Be sure to associate the correct compute rack with this resource class.

1. [BROWSER] Click on the 'Provision Deployment' button.
   
1. [BROWSER] Check the status of the overcloud.

    By clicking on the 'Racks' tab, you can see the status of the provisioning racks.

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
        



Work arounds for potential issues
----------------------------------

1. heat stack-list shows the stack in DELETE_COMPLETE state and will not go away.

This is a known issue in Heat, but Heat devs are not aware of what the cause is or steps to reproduce.
This is caused by NULL being set in the deleted_at field of the stack table in the heat database.  To fix
set this field to a random datetime.

        # [CONTROL]
        mysql -r root -h localhost
        use heat;
        
        # Check to see if the error is caused by NULL set in the deleted_at column
        select deleted_at from stack where id="<stack_id>"

        # Set the deleted_at column to any random timestamp
        update stack set deleted_at="2013-10-30 18:50:10" where id="<stack_id>"

        # Check to see if the stack is not showing in heat stack-list
        heat stack-list 
