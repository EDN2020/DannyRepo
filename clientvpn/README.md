# [clientvpn]?????(https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/what-is.html)

# Key considerations:

1. Separate VPC, dedicated for AWS VPN Client service, created and connected to Shared Resources VPC over VPC peering.
2. Each of supported AWS region will have 1 AWS VPN Client endpoint connected to 2 Availability Zones of associated Shared Resources VPC
3. High Availability requirement covered by connecting AWS VPN Client endpoint to 2 different Availability Zones.
4. Each of AWS VPN Client endpoints will be connected to QB Okta by SAML. Users will authenticate in QB Okta with SSO and MFA.
5. Only traffic to RDS PostgreSQL and Linux VM services will be allowed in Security Group associated with AWS VPN Client endpoints.
6. We will use Split-tunnel in AWS VPN Client solution to prevent sending internet traffic over PMcK VPN connections.
7. We will advertise only Shared Resources private networks over AWS VPN Client.
8. Users will be able to use the Firm VPN (Global Protect) and PMcK VPN solution simultaneous. PMcK VPN solution is using TCP/443 as transport thus no changes needed in the Firm VPN.
9. To help users installing AWS Client VPN and configure it for using with Platform McKinsey, we will publish a bundle with AWS Client VPN and a bundle with Platform McKinsey configuration to McKinsey App Store.

# Scope of automation:

1. McK ID provisioned, required for SAML integration.
2. AWS Client VPN endpoints provisioned supported AWS regions (us-east-1 and eu-central-1) for each of PMcK environments (dev, stg, prod) and connected to corresponding Shared Resource VPC in 2 Availability Zones.
3. AWS Client VPN endpoints configured with SAML with McK ID
4. Security Group allowing only traffic to RDS and Linux VM provisioned and associated to AWS Client VPN endpoints.
5. CloudWatch configured for each of AWS client VPN endpoint.

# Clientvpn Security Group:

1. Users will need to update the security group based on their requirements. Only allow ports of the resources you need to access. for example if the users will only access RDS instances, you should only open egress port 5432 in the clientvpn security group
```


# Known Limitations:

1. Number of concurrent client connections per Client VPN endpoint: 2000. As we have 2 Client VPN endpoint in 2 regions, our limit for client connections is 4000. Later on, we can add more Client VPN endpoints: up to 5 per region. It will increase our limit to 20,000 concurrent client connections.
2. Support of AWS Client VPN in terraform is limited at this moment. While there is open PR for this, it's for Terraform v0.12, but we are still on Terraform v0.11. Instead we are using CloudFormation over Terraform


# Mutual Authentication
To generate the server and private keys and upload them to ACM (Linux/macOS)

Clone the OpenVPN easy-rsa repo to your local computer and navigate to the easy-rsa/easyrsa3 folder.
```bash
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3
```

Initialize a new PKI environment.
```bash
 ./easyrsa init-pki
```

Build a new certificate authority (CA).
```bash
 ./easyrsa build-ca nopass
```


# Follow the prompts to build the CA.

1.	Generate the server certificate and key.
```bash
 ./easyrsa build-server-full server nopass
```

2.	Copy the server certificate and key to a custom folder and then navigate 
into the custom folder.

Before you copy the certificates and keys, create the custom folder by using the mkdir command. The following example creates a custom folder in your home directory.
```bash
 mkdir ~/custom_folder/
 cp pki/ca.crt ~/custom_folder/
 cp pki/issued/server.crt ~/custom_folder/
 cp pki/private/server.key ~/custom_folder/
 cd ~/custom_folder/
```
				
3.	Upload the server certificate and key to ACM. The following commands use the AWS CLI.
```bash
 aws acm import-certificate --certificate fileb://server.crt --private-key fileb://server.key --certificate-chain fileb://ca.crt --region region
 aws acm import-certificate --certificate
```

# Import Using the Console

The following example shows how to import a certificate using the AWS Management Console.
1.	Open the ACM console at https://console.aws.amazon.com/acm/home. If this is your first time using ACM, look for the AWS Certificate Manager heading and choose the Get started button under it.

2.	Choose Import a certificate.
3.	Do the following:
a.	For Certificate body, paste the PEM-encoded certificate to import.
b.	For Certificate private key, paste the PEM-encoded, unencrypted private key that matches the certificate's public key.

# Important
Currently, Services Integrated with AWS Certificate Manager support only the RSA_1024 and RSA_2048 algorithms.
c.	(Optional) For Certificate chain, paste the PEM-encoded certificate chain.
4.	Choose Review and import.
5.	Review the information about your certificate, then choose Import.

# Import Using the AWS CLI
The following example shows how to import a certificate using the AWS Command Line Interface (AWS CLI). The example assumes the following:
•	The PEM-encoded certificate is stored in a file named Certificate.pem.
•	The PEM-encoded certificate chain is stored in a file named CertificateChain.pem.
•	The PEM-encoded, unencrypted private key is stored in a file named PrivateKey.pem.
To use the following example, replace the file names with your own and type the command on one continuous line. The following example includes line breaks and extra spaces to make it easier to read.
```bash
 aws acm import-certificate --certificate file://Certificate.pem
                             --certificate-chain file://CertificateChain.pem
                             --private-key file://PrivateKey.pem
```

If the import-certificate command is successful, it returns the Amazon Resource Name (ARN) of the imported certificate.

For Windows OS
The following procedure installs the OpenVPN software, and then uses it to generate the server and client certificates and keys.
To generate the server and client certificates and keys and upload them to ACM
1.	Go to the OpenVPN Community Downloads page and download the Windows installer for your version of Windows.
2.	Run the installer. On the first page of the OpenVPN Setup Wizard, choose Next.
3.	On the License Agreement page, choose I Agree.
4.	On the Choose Components page, choose EasyRSA 2 Certificate Management Scripts. Choose Next, and then choose Install.
5.	Choose Next, and then Finish to complete the installation.
6.	Open the command prompt as an Administrator, navigate to the OpenVPN directory, and run init-config.
```powershell
C:\> cd \Program Files\OpenVPN\easy-rsa
C:\> init-config
```

7.	Open the vars.bat file using Notepad.
```powershell
C:\> notepad vars.bat
```

8.	In the file, do the following and save your changes.
•	For set KEY_SIZE, change the value to 2048.
•	Provide values for the following parameters. Do not leave any of the values blank.
o	KEY_COUNTRY
o	KEY_PROVINCE
o	KEY_CITY
o	KEY_ORG
o	KEY_EMAIL
9.	In the command line, run the vars.bat file and then run clean-all.
```powershell
C:\> vars
C:\> clean-all
```

10.	Build a new certificate authority (CA).
```powershell
C:\> build-ca
```
Follow the prompts to build the CA. You can leave the default values for all of the fields. If you prefer, you can change the Common Name to the server's domain name, for example, server.example.com.
11.	Generate the server certificate and key.
```powershell
C:\> build-key-server server
```
Follow the prompts to generate the certificate and key. You can leave the default values for all of the fields, except Common Name. For this field, you must specify a server domain in a domain name format. For example, server.example.com.
When prompted to sign the certificate, enter y for both prompts.
12.	Generate the client certificate and key.
```powershell
C:\> build-key client
```
Follow the prompts to generate the certificate and key. You can leave the default values for all of the fields, except Common Name. For this field, you must specify a client domain in a domain name format. For example, client.example.com.
When prompted to sign the certificate, enter y for both prompts.
You can optionally repeat this step for each client (end user) that requires a client certificate and key.
13.	Upload the server certificate and key and the client certificate and key to ACM. The following commands use the AWS CLI.
```powershell
C:\> aws acm import-certificate --certificate fileb://"C:\Program Files\OpenVPN\easy-rsa\keys\server.crt" --private-key fileb://"C:\Program Files\OpenVPN\easy-rsa\keys\server.key" --certificate-chain fileb://"C:\Program Files\OpenVPN\easy-rsa\keys\ca.crt" --region region
C:\> aws acm import-certificate --certificate fileb://"C:\Program Files\OpenVPN\easy-rsa\keys\client.crt" --private-key fileb://"C:\Program Files\OpenVPN\easy-rsa\keys\client.key" --certificate-chain fileb://"C:\Program Files\OpenVPN\easy-rsa\keys\ca.crt"  --region region
```

To upload the certificates using the ACM console, see Import a Certificate in the AWS Certificate Manager User Guide.
