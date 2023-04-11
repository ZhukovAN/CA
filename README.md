# Simple two-tier certification authority (CA)
Certificates are everywhere: currently about 80% of web sites use secure HTTPS protocol that uses certificates, people use certificates for VPN, client-side authentication, digital signatures, etc. It means that sometimes you may need to generate certificates for your own needs. If you have access to your company's certification authority then you may simply ask CA team to generate that certificate for you, but if you haven't one then certificates are to be generated manually. 

There's a lot of HOWTO's about using **OpenSSL**, but sometimes those manuals too simple like create self-signed certificate for web server. That's OK for pet projects but if you want to be sure that your application will work in the enterprise environment with strict CA policy than you need to implement more complex "chained" approach where there are to be at least one trusted root CA and one intermediate CA.

This repository is about how to create your own two-tier CA hierarchy that allows you to use bash scripts to generate certificates for different purposes like server- or client-side SSL authentication, VPN, etc.

# Prerequisites
``` bash
# Need keytool from JRE
apt install default-jre
# Need uuidgen to generate unique identifiers
apt-get install uuid-runtime
```

# How to start
Clone or download this repository as zip file. There'll be two folders inside: RootCA and Intermediate CA. Root CA allows you to sign certificate signing request and generate Intermediate CA certificate. Intermediate CA used to generate end-user certificates. 

Both CA's bin folder contain set of configuration files that define certificate parameters like key length, validity period, subject, etc. If you want to use different parameters feel free to change corresponding `*.conf` files.

## Initialize Root CA
> Predefined root CA organization name is "Domain.ORG" and common name is "Domain.ORG Root CA". You may change these values in `[ca_dn]` section of `RootCA/bin/ca.conf` file if you want to.

Execute `01.init.sh` script in RootCA/bin folder:
```
cd RootCA/bin
./01.init.sh
```
This will initialize internal Root CA data structures, generate Root CA key pair and certificate signing request (CSR), sign that CSR using own private key and create first empty certificate revocation list (CRL):
```
$ ./01.init.sh
Using CA_HOME=/cygdrive/c/DATA/TEMP/20220713/RootCA
Generating RSA private key, 4096 bit long modulus (2 primes)
......................................................................................................................................................................++++
...................................................................................................................................................................................++++
e is 65537 (0x010001)
Using configuration from /cygdrive/c/DATA/RootCA/bin/ca.conf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 8052654775772005552 (0x6fc0c6da90be44b0)
        Validity
            Not Before: Jul 13 06:33:55 2022 GMT
            Not After : Jul 13 06:33:55 2042 GMT
        Subject:
            organizationName          = Domain.ORG
            commonName                = Domain.ORG Root CA
        X509v3 extensions:
            X509v3 Key Usage: critical
                Certificate Sign, CRL Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier:
                56:BE:8A:E6:F1:90:C0:5F:B6:07:02:0B:3D:65:B5:7E:FE:77:31:E2
            X509v3 Authority Key Identifier:
                keyid:56:BE:8A:E6:F1:90:C0:5F:B6:07:02:0B:3D:65:B5:7E:FE:77:31:E2

Certificate is to be certified until Jul 13 06:33:55 2042 GMT (7305 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
```

### Root CA files and folder structure
Files and folders generated during initialization process are:
- **RootCA/certs** --- Root CA certificates stored as DER- and PEM files
- **RootCA/db** --- Internal OpenSSL database files
- **RootCA/private** --- Root CA's *unencrypted* private key stored as PEM file
- **RootCA/newcerts** --- certificates, signed by Root CA. Usually there're two files here only: self-signed Root CA certificate and Intermediate CA certificate signed by Root CA. These certificates are stored in PEM format
- **RootCA.der.crl** and **RootCA.pem.crl** --- Root CA certificate revocation lists stored as DER- and PEM files

## Initialize Intermediate CA
> As with Root CA you may also change intermediate CA's organization and common names in `[ca_dn]` section of `IntermediateCA/bin/ca.conf` file.

Execute `01.init.sh` script in IntermediateCA/bin folder:
```
cd ../../IntermediateCA/bin
./01.init.sh
```
This will initialize internal Root CA data structures, generate Root CA key pair and certificate signing request (CSR), sign that CSR using own private key and create first empty certificate revocation list (CRL):
```
$ ./01.init.sh
Using CA_HOME=/cygdrive/c/DATA/TEMP/20220713/IntermediateCA
Generating RSA private key, 4096 bit long modulus (2 primes)
...................................................................................................++++
...............++++
e is 65537 (0x010001)
Using configuration from /cygdrive/c/DATA/TEMP/20220713/RootCA/bin/ca.conf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 8052654775772005553 (0x6fc0c6da90be44b1)
        Validity
            Not Before: Jul 13 06:55:01 2022 GMT
            Not After : Jul 13 06:55:01 2042 GMT
        Subject:
            organizationName          = Domain.ORG
            commonName                = Domain.ORG Intermediate CA
        X509v3 extensions:
            X509v3 Key Usage: critical
                Certificate Sign, CRL Sign
            X509v3 Basic Constraints: critical
                CA:TRUE, pathlen:0
            X509v3 Subject Key Identifier:
                2B:07:05:A7:29:3D:08:6A:06:EA:36:BD:BF:59:21:0D:35:14:CF:20
            X509v3 Authority Key Identifier:
                keyid:56:BE:8A:E6:F1:90:C0:5F:B6:07:02:0B:3D:65:B5:7E:FE:77:31:E2

Certificate is to be certified until Jul 13 06:55:01 2042 GMT (7305 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
```
### Intermediate CA files and folder structure
Files and folders generated during initialization process are the same as those after Root CA initialization. There's only difference with folder **IntermediateCA/out/${certificate.serial}** --- it contains generated CSR's, certificates, keys etc.

##  Generate certificate
There're several bash scripts in IntermediateCA/bin folder that are used to issue certificates:
 - **ssl.client.sh** --- generates certificate for client authentication on SSL server
 - **ssl.server.sh** --- generates certificate for SSL server
 - **vpn.client.sh** and **vpn.server.sh** --- generates certificate for OpenVPN client and server

To generate certificate you need to edit corresponding `*.conf` file and execute bash script. For example, to generate SSL server certificate you need to open `ssl.server.conf` file and:
- set DNS name in `subjectAltName` in `[v3_req]` section. This value must conform your web server DNS name
- (optionally) set organization- and common name fields in `[req_dn]` section

After that execute `ssl.server.sh` script:
```
$ ./ssl.server.sh
Using CA_HOME=/cygdrive/c/DATA/TEMP/20220713/IntermediateCA
Generating a RSA private key
...............................................++++
............++++
writing new private key to '/cygdrive/c/DATA/TEMP/20220713/IntermediateCA/temp/ssl.server.pem.key'
-----
Using configuration from /cygdrive/c/DATA/TEMP/20220713/IntermediateCA/bin/ca.conf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 1414102274214019477 (0x139fe686b2994195)
        Validity
            Not Before: Jul 13 07:26:34 2022 GMT
            Not After : Jul 12 07:26:34 2032 GMT
        Subject:
            organizationName          = Domain.ORG
            commonName                = Domain.ORG CI server #01
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Basic Constraints:
                CA:FALSE
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Subject Key Identifier:
                67:78:6E:B3:2D:DA:1A:86:C6:1D:EF:33:F8:F5:3F:CB:5F:AA:DA:4D
            X509v3 Authority Key Identifier:
                keyid:2B:07:05:A7:29:3D:08:6A:06:EA:36:BD:BF:59:21:0D:35:14:CF:20

            X509v3 Subject Alternative Name:
                DNS:*.domain.org, DNS:localhost
            Netscape Cert Type:
                SSL Server
Certificate is to be certified until Jul 12 07:26:34 2032 GMT (3652 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
Certificate was added to keystore
Certificate was added to keystore
Certificate was added to keystore
Certificate was added to keystore
Importing keystore ssl.server.brief.pfx to private.jks...
Entry for alias ssl server certificate successfully imported.
Import command completed:  1 entries successfully imported, 0 entries failed or cancelled

Warning:
The JKS keystore uses a proprietary format. It is recommended to migrate to PKCS12 which is an industry standard format using "keytool -importkeystore -srckeystore private.jks -destkeystore private.jks -deststoretype pkcs12".
Importing keystore private.jks to private.p12...
Entry for alias intermediateca successfully imported.
Entry for alias rootca successfully imported.
Entry for alias ssl server certificate successfully imported.
Import command completed:  3 entries successfully imported, 0 entries failed or cancelled
```
### Generated files
Files generated during certificate generation process are copied into **IntermediateCA/out/${certificate.serial}** folder. Some files are hold private keys and use P@ssw0rd for protection:
- **ca.chain.pem.crt** --- PEM-encoded CA certificates chain file that includes Root CA and Intermediate CA certificates
- **trust.jks** --- Java keystore file that contains two CA certificates marked as trusted
- **private.jks** --- Java keystore file that contains two CA certificates marked as trusted and generated certificate and key
- **private.p12** --- Java Keytool clone of JKS keystore that uses PKCS#12 format instead of proprientary JKS. Contents are the same as for private.jks
- **ssl.server.brief.pem** and **ssl.server.brief.pfx**  --- PKCS#12-encoded certificate / key container. **Doesn't** contain CA certificates
- **ssl.server.full.pem** and **ssl.server.full.pfx**  --- PKCS#12-encoded certificate / key container. **Does** contain CA certificates
- **ssl.server.der.crt** and **ssl.server.pem.crt**  --- generated certificate stored as DER- and PEM files
- **ssl.server.pem.csr**  --- certificate signing request stored as PEM file
- **ssl.server.pem.key**  --- *unencrypted* certificate private key
