* OIDC Authentication: Run vault login -method=oidc to authenticate via your browser and store a session token in your local environment.
* Config Parsing: Use a PowerShell script to extract the Common Name and certificate metadata from your local OpenSSL csr.conf file.
* Session Integration: The script retrieves the active OIDC token from ~/.vault-token to authorize the subsequent REST API calls to Vault.
* Internal CSR Generation: Submit a POST request to the PKI Secrets Engine to generate a new private key and CSR directly within Vault.
* File Export: Save the PEM-encoded CSR returned by the Vault API to a local file for submission to your Root Certificate Authority.


Bam vendor cert problem solved.

Now into eks Isra.
