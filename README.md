Provision an Overcloud using Tuskar
-------------
<a name=intro> </a>

To install Tuskar using these instructions and succesfully deploy an
overcloud, you must first set up a functioning undercloud consisting of a
control and leaf node.

The first part of these instructions will guide you through the installation
of the undercloud control and leaf nodes (in 2 virtual machines) and the
second part will guide you through the Tuskar installation.


 * [Setup 2-node undercloud](#undercloud)
    * [Extra Notes/Troubleshooting for the 2-node undercloud setup](#notes_undercloud)
 * [Setup Tuskar and deploy Overcloud](#tuskar)
    * [Extra Notes/Troubleshooting for the Tuskar install](#notes_tuskar)

---------------------------------------------------------------------------

Setup the 2 node undercloud:
---------------------
<a name=undercloud> </a>


The 2-node (control and leaf) version of undercloud-live uses the host's
libvirt instance for the baremetal nodes. This makes it easier to use VMs for
everythng, but, there is some host setup that needs to be done.

Each step below (where applicable) is prefaced with what system to run it on.
 * HOST - the virtualization host you're using to run VM's
 * CONTROL - undercloud control node
 * LEAF - undercloud leaf node

Commands on the Host can be run as your normal user.

Commands on the Control and Leaf nodes should be run as the **stack** user unless
specified otherwise (you do **not** need to create this user it will be created
for you on the Control and Leaf VMs).

### Prerequisites
* Instructions below assume Fedora 19 x86_64 on the HOST machine.
* You will need to have sudo as root ability
* The control and leaf nodes that make up the undercloud will be launched
  as VMs - so you should make sure both *libvirt* and *openvswitch* are installed
  and running.

-----------------------------


1. **[HOST] Define and use a $TRIPLEO_ROOT directory**

        cd ~
        mkdir tripleo
        export TRIPLEO_ROOT=~/tripleo
        cd $TRIPLEO_ROOT

1. **[HOST] Clone the repositories for tripleo-incubator and undercloud-live.**

        git clone https://github.com/openstack/tripleo-incubator
        git clone https://github.com/agroup/undercloud-live
        pushd undercloud-live
        git checkout slagle/package
        popd

1. **[HOST] Add the tripleo scripts to your path.**

        export PATH=$TRIPLEO_ROOT/tripleo-incubator/scripts:$PATH

1. **[HOST] Install necessary packages**

        install-dependencies

1. **[HOST] Define environment variables for the baremetal nodes.**

        export NODE_CPU=1
        export NODE_MEM=2048
        export NODE_DISK=20
        export NODE_ARCH=amd64

1. **[HOST] Ensure that openvswitch is started**

        sudo service openvswitch start

1. **[HOST] Setup the brbm openvswitch bridge and libvirt network.**

        setup-network

1. **[HOST] Check that LIBVIRT_DEFAULT_URI is set correctly**

   Check that the default libvirt connection for your user is qemu:///system:

        [root@dell-per610-01 ~]# echo $LIBVIRT_DEFAULT_URI
        qemu:///system

   **If it is not**, set an environment variable to configure the
   connection. Also, create a profile script to ensure the environment variable
   gets set in future sessions. This is needed to ensure the virtual power
   manager can find the baremetal instances created on the host.

        export LIBVIRT_DEFAULT_URI=${LIBVIRT_DEFAULT_URI:-"qemu:///system"}
        sudo su -c "echo export LIBVIRT_DEFAULT_URI=qemu:///system > /etc/profile.d/virsh.sh"

1. **[HOST] Create the baremetal nodes.**

   You need to **Save the output** of this command, you will need it later.

        undercloud-live/bin/nodes.sh

1. **[HOST] Review the VM templates for the control node and leaf nodes.**

   There are libvirt templates called ucl-control-live and ucl-leaf-live in
   the **undercloud-live/templates** directory for you to create the Control
   and Leaf VMs from.

   Review the templates and make any changes you'd like (e.g., increase ram).

   **Note**: you will need to access the resulting VMs to drive the installation
   and configuration into control/leaf nodes. If you are using a local
   machine (e.g. your laptop) as HOST then you can use virt-manager for
   access. Otherwise, if you are using a remote lab machine as HOST then you
   may want to setup spice - see the [notes](#spice) for info about a change
   you need to make to the template XML to enable access with a spice client.

   **Note**: when reviewing the above templates, you will note they are
   expecting the Fedora-Undercloud-Control.iso and Fedora-Undercloud-Leaf.iso
   images to be in [HOST] /var/lib/libvirt/images so make sure you move them there
   after download and rename or edit the XML accordingly.

1. **[HOST]: Create the disk images that your VMs will use:**

   Note: the path to the images you are creating below is reference by the
   XML templates for the Control and Leaf VMs. If you have edited that
   path in the previous step then ammend the following accordingly:

        cd /var/lib/libvirt/images
        qemu-img create -f qcow2 ucl-leaf-live.qcow2 40G
        qemu-img create -f qcow2 ucl-control-live.qcow2 40G
        cd $TRIPLEO_ROOT

1. **[HOST] Create and boot the VMs for the control and leaf nodes**.

   Assuming you are using the provided XML templates from above:

        virsh define undercloud-live/templates/ucl-control-live.xml
        virsh define undercloud-live/templates/ucl-leaf-live.xml
        virsh start ucl-control-live
        virsh start ucl-leaf-live

1. **[CONTROL],[LEAF] Access the running VMs and review the kickstart files:**

   **Note**: you will need access to the running VMs to drive the installation.
   You can use virt-manager for this, or see the [notes](#spice) for info
   on using a spice client instead.

   There is a kickstart file included on the images to make installation easier.
   However, before using the kickstart file, first make sure that a network
   configuration script exists for every network interface (this might be
   a Fedora bug).  Here are some example commands that copy network scripts for
   a system with 1 interface (CONTROL) and a system with 2 interfaces (LEAF)

        # System with 1 interface called ens3, i.e. the CONTROL node:
        sudo cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-ens3

        # System with 2 interfaces, ens3 and ens6, i.e. the LEAF node:
        sudo cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-ens3
        sudo cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-ens6

1. **[CONTROL],[LEAF] Install the undercloud images to each VM:**

   Make any needed changes to the kickstart file and then run
   (This should be run as liveuser, not root):

        liveinst --kickstart /opt/stack/undercloud-live/kickstart/anaconda-ks.cfg

   **Note:** the installation is automated; you do not need to create any users
   or edit the disk configuration as you may be accustomed to when installing
   Fedora usually.

1. **[CONTROL],[LEAF] Reboot the VMs:**

   Once the install has finished, reboot the control and leaf VM's. Make
   sure when they reboot, they boot from disk, not iso.  You can login with
   stack/stack.

        sudo shutdown --reboot now

1. **[HOST] Add a route from your host to the 192.0.2.0/24 subnet via the leaf
   ip.**

   Update $LEAF_IP for your environment:

        export LEAF_IP=192.168.122.101
        sudo ip route add 192.0.2.0/24 via $LEAF_IP

1. **[CONTROL] Edit /etc/sysconfig/undercloud-live-config**

   **Note:** you will need superuser privileges to edit this file

        sudo vi /etc/sysconfig/undercloud-live-config

   You need to set all the defined environment variables in the file according
   to your enviroment. Remember to set $UNDERCLOUD_MACS based on the output
   from when nodes.sh was run earlier. There is a guide/example of the values
   you should provide in this file in the [notes](#ucloud_config).

        NOTE: The following may not be obvious variables in
        the config file:

        #this is the primary (and likely only) interface on control
        export CONTROL_INTERFACE=ens3

        #this is the second interface on the leaf node, ens6
        export LEAF_INTERFACE=ens6

        #set libvirt user according to what was used on HOST:
        export LIBVIRT_USER=root

        #the LIBVIRT Host IP will be the IP for virbr0 on HOST, not the
        #'main' host address:
        export LIBVIRT_HOST=192.168.122.1

        The rest should be self explanatory, if not shout!

   Once edited,  run undercloud-metadata
   on the control node to refresh the configuration.

        sudo undercloud-metadata

   Use the command in the output from undercloud-metadata to watch/tail the log
   of os-collect-config.  Make sure it runs successfully once.  You'll be able
   to tell when you see "Completed phase post-configure" in the log.

1. **[LEAF] Edit /etc/sysconfig/undercloud-live-config**

   Set all the defined environment variables in the file, as described above.
   Once edited, run undercloud-metadata  on the LEAF node to refresh the configuration.

   MAKE SURE you set the variables correctly, as mentioned in the previous
   step for CONTROL.

        sudo undercloud-metadata

   Use the command in the output from undercloud-metadata to watch/tail the log
   of os-collect-config.  Make sure it runs successfully once.  You'll be able
   to tell when you see "Completed phase post-configure" in the log.

1. **[CONTROL] Copy over images to Control:**

   If you don't provide the images, the next step will attempt to create
   them for you.  You will need the following images to exist on the control node.

        /opt/stack/images/overcloud-control.qcow2
        /opt/stack/images/overcloud-compute.qcow2
        /opt/stack/images/deploy-ramdisk.initramfs
        /opt/stack/images/deploy-ramdisk.kernel
        #the following will be used later to launch an instance in Overcloud
        /opt/stack/images/fedora-cloud.qcow2

   Assuming you have previously downloaded all images to a directory on the
   HOST, you can use the followig scp commands for copying the images across
   (**SET CONTROL_IP** accordingly):

        [HOST]
        CONTROL_IP=192.168.122.155
        scp overcloud-control.qcow2 stack@$CONTROL_IP:/opt/stack/images
        scp overcloud-compute.qcow2 stack@$CONTROL_IP:/opt/stack/images
        scp deploy-ramdisk.initramfs stack@$CONTROL_IP:/opt/stack/images
        scp deploy-ramdisk.kernel stack@$CONTROL_IP:/opt/stack/images
        scp fedora-cloud.qcow2 stack@$CONTROL_IP:/opt/stack/images

1. **[CONTROL] Load the images into glance.**

        /opt/stack/undercloud-live/bin/images.sh

1. **[CONTROL] Run the script to setup the baremetal nodes**

   This will also define the baremetal flavor:

        /opt/stack/undercloud-live/bin/baremetal-2node.sh

1. **[HOST] Add the configured virtual power host key to ~/.ssh/authorized_keys**

   Define $LEAF_IP as needed for your environment:

        export LEAF_IP=192.168.122.101
        ssh stack@$LEAF_IP "cat /opt/stack/boot-stack/virtual-power-key.pub" >> ~/.ssh/authorized_keys
        chmod 0600 ~/.ssh/authorized_keys

1. **[HOST] Ensure that SSH Daemon has started**

        sudo service sshd start


**You can now proceed with the Tuskar installation**

[back to top](#intro)


--------------------------------------------------------------------------

Install and use Tuskar to deploy the Overcloud:
------------------
<a name=tuskar></a>

Once you have completed the steps above you are ready to install Tuskar and deploy
an Overcloud:

1. **[CONTROL] Checkout Tuskar Install**

        cd ~
        git clone https://github.com/mtaylor/tuskar_install.git
        cd tuskar_install

1. **[CONTROL] Install and configure Tuskar**

        # check the variables at the top of ./bin/install.sh are correct then run:
        ./bin/install.sh

1. **[CONTROL] Update the MAC addresses at the top of ./bin/create_racks.sh**

   You need to use the MAC addresses for the baremetal nodes you created as
   part of the 2 node undercloud setup. If you have misplaced these or if you
   wish to confirm their value, refer to the [notes](#bm_mac).

        #!/bin/bash
        TUSKAR_URL="http://localhost:8585/v1"
        UNDERCLOUDRC="/etc/sysconfig/undercloudrc"

        source $UNDERCLOUDRC
        declare -A RACKS
        RACKS["rack-m1"]="52:54:00:2e:a7:4e"
        RACKS["rack-control"]="52:54:00:da:8e:df"

1. **[CONTROL] Run the Create Rack Script**

        ./bin/create_racks.sh

1. **[HOST]/[BROWSER] Open Undercloud Horizon dashboard**

   Navigate to <undercloud-control-ip>:8080 and log in - the username is
   *admin* and the password is *unset*.

   Since the Tuskar UI is a plugin for Horizon, the user interface will
   look familiar to those who have used Horizon before.  Click on the
   Infrastructure tab to reach the Tuskar section.

        # If working on a remote machine without X you may want to setup a tunnel (and proxy in browser)
        ssh -D 8080 -C -N stack@lab12

1. **[BROWSER] Create a control resource class.**

   Click on the 'Create Class' button to start the resource class creation
   workflow for a control resource class.  This resource class will be
   responsible for running shared OpenStack services such as Keystone,
   Swift and Cinder.

        # Select 'Controller' in the 'Class Type' drop down.
        # Ensure you choose the overcloud-control image.
        # Be sure to associate the correct control rack with this resource class.

1. **[BROWSER] Create a compute resource class.**

   Click on the 'Create Class' button to start the resource class creation
   workflow for a compute resource class.  As part of the creation of a compute resource class
   you will need to define some flavors. These will be available to users of the overcloud
   when launching instances as part of the given resource class, for example:

    | Flavor Name | VCPU | RAM (MB) | Root Disk (GB) | Ephemeral Disk (GB) | Swap Disk (MB) |
    |:-----------:|:----:|:--------:|:--------------:|:-------------------:|:--------------:|
    | tiny        | 1    | 512      | 1              | 0                   | 0              |
    | small       | 1    | 2048     | 20             | 0                   | 0              |

        # Name the resource class 'm1'.
        # Select 'Compute' in the 'Class Type' drop down.
        # Ensure you choose the overcloud-compute image.
        # Create flavors as shown in the example above.
        # Be sure to associate the correct compute rack with this resource class.

1. **[BROWSER] Click on the 'Provision Deployment' button.**

1. **[BROWSER] Check the status of the Overcloud deployment:**

    By clicking on the 'Racks' tab, you can see the status of the provisioning racks.

    You can monitor the deployment progress on the CONTROL node:

        #on CONTROL:
        [stack@ucl-control-live tuskar_install]$ source /etc/sysconfig/undercloudrc
        [stack@ucl-control-live tuskar_install]$ while true; do nova list; heat stack-list; date; sleep 10; done

    It should show CREATE_COMPLETE in the output after succesful deployment.
    You must wait until this has happened before moving on!


1. **[CONTROL] Configure the overcloud**

   If you saw 'CREATE_COMPLETE' above then you have succesfully deployed an
   Overcloud using Tuskar. We can now perform setup of the overcloud and
   load the demo image into overcloud glance.

        cd ~
        #Don't worry if the following complains about 'flavor m1.tiny doesn't exist'
        /opt/stack/undercloud-live/bin/configure-overcloud.sh

        #get overcloud control node IP address:
        source /etc/sysconfig/undercloudrc
        export OVERCLOUD_IP=$(nova list | grep notcompute.*ctlplane | sed  -e "s/.*=\\([0-9.]*\\).*/\1/")

1. **[CONTROL] Register an Overcloud demo image to launch:**

   **NOTE**: you should already have the demo fedora-cloud.qcow2 image on CONTROL. Make sure the
   path to that image is specified correctly below:

        #source credentials
        cd ~
        source tripleo-overcloud-passwords
        source /opt/stack/tripleo-incubator/overcloudrc
        #NOTE SET THE CORRECT PATH TO THE fedora-cloud.qcow2 image below!
        glance image-create \
                --name user \
                --public \
                --disk-format qcow2 \
                --container-format bare \
                --file /opt/stack/images/fedora-cloud.qcow2

1. **[CONTROL] Setup Overcloud user:**


        source /opt/stack/tripleo-incubator/overcloudrc-user
        user-config

1. **[CONTROL] Launch an Overcloud instance:**
   Note - the flavor specified below must match one that was created by you earlier in the Tuskar UI.
   If you are unsure you can use 'nova flavor-list':

        nova boot --key-name default --flavor m1.small --image user demo
        # nova list until the instance is ACTIVE
        nova list

1. **[CONTROL] Add floating IP to your Overcloud instance:**

        PORT=$(neutron port-list -f csv -c id --quote none | tail -n1)
        neutron floatingip-create ext-net --port-id "${PORT//[[:space:]]/}"
        # nova list again to see the assigned floating ip
        nova list

1. **[CONTROL] Discover the IP and URI for overcloud Horizon**

   Presently you can do this in 2 ways:

        1. Using nova list - you want the IP address of the notcompute node
        2. Via the Tuskar UI - using the 'standard' parts of Horizon - go to 'Project' --> 'Instances'
           and you will see the IP address. Again, you want the IP of notcompute (alternatively,
           the instance launced from the 'overcloud-control' image).

        You can then use this IP to construct the Horizon URI:

            http://IP_OF_NOTCOMPUTE:80

   To login to Overcloud Horizon - username is 'admin' and the password is available from the
   tripleo-overcloud-passwords file (it is the OVERCLOUD_ADMIN_PASSWORD):

        cd ~
        cat tripleo-overcloud-passwords


   You can navigate to the Instances page to view details of your running Overcloud instance.

[back to top](#intro)

--------------------------------------------------------------------------

Extra Notes for the 2 node undercloud setup:
-----------------------------------------------------------
<a name=notes_undercloud> </a>

* **Configure spice for access to the leaf/control VMs**:
<a name=spice></a>

  You will need to edit the two XML templates to add the HOST IP address to the graphics
  definition for each VM. This way you can use a spice client to connect and run
  the installation:

        <graphics type='spice' autoport='yes' listen='10.0.1.25'/>

  Once the VMs are running you'll be able to use a spice client
  to connect. You need to first discover the port spice is listening on for
  each VM

  **NOTE** this port is only assigned/available *after* the VM has been started:

        [HOST]
        [root@hostname]# virsh dumpxml ucl-control-live
        ...
        <graphics type='spice' port='5900'
        ...

        [yourlaptop]
        yum install spice-gtk-tools.x86_64
        spicy -h 10.0.1.25 -p 5900

   Repeat the above for ucl-leaf-live.

* **Example/Guide values for /etc/sysconfig/undercloud-live-config**:
  <a name=ucloud_config></a>
  The following is a guide only - in particular make sure you set the
  IP addresses of the CONTROL and LEAF VM correctly depending on your setup!

        # Management IP address of Control Node
        # Used by:
        #   -- leaf node to connect to the control node
        #   -- leaf node redirects metadata and heat data requests to
        export CONTROL_IP=192.168.122.155

        # Control Node management network interface
        # This is most likely the first interface (eth0)
        # Used by:
        #  -- control node adds a route to 192.0.2.0/24 via eth0 and
        export CONTROL_INTERFACE=ens3

        # Management IP address of Leaf Node
        # Used by:
        #  -- control node adds a route to 192.0.2.0/24 via eth0 and
        export LEAF_IP=192.168.122.153

        # IP address assigned to the br-ctlplane ovs bridge that is bridged to the
        # interface that is used for pxe booting nodes by the leaf.
        # Used by:
        #  -- init-neutron-ovs script on leaf node to assign an IP to br-ctlplanej
        export LEAF_DNSMASQ_IP=192.0.2.1

        # Leaf Node physical network interface for L2 broadcast domain for pxe
        # This is possibly not the management interface, if running everything in vm's,
        # it's most likely the 2nd interface (eth1)
        # Used by:
        #  -- leaf interface that is bridged to br-ctlplane and used for
        #     dnsmasq/dhcp/pxe/tftp
        export LEAF_INTERFACE=ens6

        # Compute service host name of the Leaf Node
        # Used by:
        #  -- leaf node setting in nova.conf that identifies the compute host to the
        #     control node
        LEAF_SERVICE_HOST=undercloud-leaf

        # Barmetal node vm's hardware characteristics.  These settings should match
        # what they were when you defined them on the host.
        export NODE_CPU=1
        export NODE_MEM=2048
        export NODE_DISK=20
        export NODE_ARCH=amd64

        # Mac addresses of baremetal node vm's.  This value was output to the screen
        # when nodes.sh was run on the host.
        export UNDERCLOUD_MACS="52:54:00:61:b2:ae 52:54:00:c6:72:bc"

        # IP address of host system running libvirt where baremetal nodes are defined
        export LIBVIRT_HOST=192.168.122.1
        # User on host system to use to run virsh/libvirt commands
        export LIBVIRT_USER=root

        # libvirt type (either qemu or kvm) that the overcloud will use to launch
        # instances *on* the overcloud.  If running the overcloud in vm's, you most
        # likely want qemu.
        export OVERCLOUD_LIBVIRT_TYPE=qemu

[back to top](#intro)

--------------------------------------------------------------------------


Extra Notes for the Tuskar installation:
-----------------------------------------------------------
<a name=notes_tuskar> </a>

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

1. Retrieve/Confirm the MAC addresses of the baremetal nodes
<a name=bm_mac> </a>
You can use the nova baremetal CLI to confirm the values of the 2 baremetal
node MAC addresses:

        [CONTROL]
        #source the undercloud credentials
        [stack@ucl-control-live tuskar_install]$ source /etc/sysconfig/undercloudrc
        #list the baremetal nodes:
        [stack@ucl-control-live tuskar_install]$ nova baremetal-node-list
        +--------------------------------------+-----------------+------+-----------+---------+-------------+------------+-------------+-------------+---------------+
        | ID                                   | Host            | CPUs | Memory_MB | Disk_GB | MAC Address | PM Address | PM Username | PM Password | Terminal Port |
        +--------------------------------------+-----------------+------+-----------+---------+-------------+------------+-------------+-------------+---------------+
        | e34fdb57-b605-443a-9e43-9a874ee084db | undercloud-leaf | 1    | 2048      | 20      |             | None       | None        |             | None          |
        | 8f5e7f95-d9d2-415e-9388-25afd3db0c64 | undercloud-leaf | 1    | 2048      | 20      |             | None       | None        |             | None          |
        +--------------------------------------+-----------------+------+-----------+---------+-------------+------------+-------------+-------------+---------------+

        #retrieve details for each to get the MAC:
        [stack@ucl-control-live tuskar_install]$ nova baremetal-node-show e34fdb57-b605-443a-9e43-9a874ee084db
        +---------------+----------------------------------------------------------------------------------------+
        | Property      | Value                                                                                  |
        +---------------+----------------------------------------------------------------------------------------+
        | instance_uuid | 0d0db7dc-f814-4ad4-9916-5782a4aae7a4                                                   |
        | pm_address    | None                                                                                   |
        | interfaces    | [{u'datapath_id': None, u'id': 1, u'port_no': None, u'address': u'52:54:00:61:b2:ae'}] |
        | cpus          | 1                                                                                      |
        | memory_mb     | 2048                                                                                   |
        | service_host  | undercloud-leaf                                                                        |
        | local_gb      | 20                                                                                     |
        | id            | e34fdb57-b605-443a-9e43-9a874ee084db                                                   |
        | pm_user       | None                                                                                   |
        | terminal_port | None                                                                                   |
        +---------------+----------------------------------------------------------------------------------------+






<a name=bm_mac> </a>

[back to top](#intro)

