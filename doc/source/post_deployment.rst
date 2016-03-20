.. _post_deployment:

Post-deployment SR-IOV test scripts
===================================

In order to test that SR-IOV is working properly **after** deploying an OpenStack environment **successfully**, a couple of scripts have been added under /sbin/:

**Note**: Please use the 2 last commands with caution.

- **upload_sriov_cirros **
Uploads a pre-configured Mellanox Cirros image to glance images list.

- **start_sriov_vm**
For starting a VM with direct port from previous image. In order to test that SR-IOV is working properly, start two SR-IOV VM.s and make sure you have ping between these nodes. Assumes upload_sriov_cirros was executed before.

- **delete_sriov_ports**
Deletes all SR-IOV ports created in previous scripts.

- **delete_all_glance_images**
Deletes all Glance images.

