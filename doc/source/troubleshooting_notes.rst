.. _troubleshooting_notes:

Troubleshooting notes
- Please verify your network configurations prior to the deployment.
- Please make sure all your Health check Tests are passing.
- To make sure SR-IOV is working properly, please refer to user scripts mentioned previously.
- Mellanox Plugin log file is located on each slave node on the following path:
  - /var/log/Mellanox-plugin.log
- For further information you can check the relevant logs too:
  - /var/log/docker-logs/astute/astute.log (fuel-master)
  - /var/log/dmesg (target nodes)
