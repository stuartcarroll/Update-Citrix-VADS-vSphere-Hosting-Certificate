Legacy script but still working for on premises Citrix VADS - This downloads and imports the vCenter certificate to existing Citrix VADS hosting connections. For use when vCenter certificates change.
This script will

- Interrogate DDCs for existing vSphere hosting connections

- Extract the vCenter URL

- Download the SSL certificate installed on the vCenter

- Install the certificate into the 'Trusted People' store for the local machine

- Compare the SSL thumbprint from the existing hosting connection to the downloaded certificate

- if the thumbprint is different it will update the thumprint on the hosting connection

