as part of the open-webui defaults we need to create a number of users/groups. these need to be idempotent. eg no writes if they already exist and are configured correctly.

these are:

A default admin user. this should be called ELRAdmin. Choose some random password during invoke-deployment and create the user and an api key. update the DATA_ROOT/credentialsopenweb-ui.txt. this file is added to .gitignore so credentials cannot be leaked. 
Create a default admin user. Use the open-webui environment variables for email, name, and password to create them at container start time. Write the credentials to `DATA_ROOT/credentials-open-webui.txt` on every deployment run so they are always current. See open-webui-users.md for the user name.

An ELR group. we will add users later to this. 
