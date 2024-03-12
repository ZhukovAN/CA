# Simple two-tier certification authority (CA)
Certificates are everywhere: currently about 80% of web sites use secure HTTPS protocol that uses certificates, people use certificates for VPN, client-side authentication, digital signatures, etc. It means that sometimes you may need to generate certificates for your own needs. If you have access to your company's certification authority then you may simply ask CA team to generate that certificate for you, but if you haven't one then certificates are to be generated manually using OpenSSL tool. 

There's a lot of HOWTO's about using OpenSSL, but sometimes those manuals are trivial like create self-signed certificate for web server. That's OK for pet projects, but if you want to be sure that your application will work in the enterprise environment with strict CA policy than you need to implement more complex "chained" approach where there are to be at least one trusted root CA and one intermediate CA.

This repository is about how to create your own two-tier CA hierarchy that allows you to use bash scripts to generate certificates for different purposes like server- or client-side SSL authentication, VPN, etc.

## Build CA image using Docker
### Use predefined CA name PTDemo.LOCAL
``` bash
docker build --tag ptdemo/ca:latest .
```
### Use custom CA name like e.g. YourDomain.ORG
``` bash
docker build \
  --build-arg ORGANIZATION=YourDomain.ORG \
  --tag yourdomain/ca:latest .
```
## Use CA image
When started, CA image container checks its mapped `/opt/ca/data` folder for a presence of a root- and intermediate CA private keys. If those are not found, CA data initialization procedure is started. That procedure includes:
- CA files / folder structure creation;
- generation of root CA self-signed certificate;
- generation of intermediate CA certificate signing request;
- sign intermediate CA's CSR with root CA private key
- CRL generation for both CA

CA data files include configuration settings, internal entities like keys, certificates database, serials etc., and certificates issued by corresponding CA. Those files are stored in `/opt/ca/conf` and `/opt/ca/data` folders and should use Docker's named folders to persist values between CA image runs.
After startup check container's entry point script executes certificate generation task. Currently only SSL server certificate task is supported
### Generate SSL server certificate
Following command generates SSL server certificate with subjectAlternativeName set to `DNS:*.ptdemo.local` value
``` bash
docker run --rm -it \
  --volume ptdemo-ca-conf:/opt/ca/conf \
  --volume ptdemo-ca-data:/opt/ca/data \
  ptdemo/ca:latest \
  generateSslServerCertificate DNS:*.ptdemo.local
```
### Generated files
Files generated during certificate generation process are copied into container's `/opt/ca/data/intermediate-ca/out/${serial}` folder. Some files are hold private keys and use P@ssw0rd for protection:
- `key.pem` - unencrypted certificate private key
- `csr.pem` - certificate signing request stored as PEM file
- `server.crt` and `server.pem` - generated certificate stored as DER- and PEM files
- `server.brief.pem` and `server.brief.pfx` - PKCS#12-encoded certificate / key container. Doesn't contain CA certificates
- `server.full.pem` and `server.full.pfx` - PKCS#12-encoded certificate / key container. Does contain CA certificates
- `ca.pem` - PEM-encoded CA certificates chain file that includes both root- and intermediate CA certificates
- `trust.jks` - Java keystore file that contains two CA certificates marked as trusted
- `private.jks` - Java keystore file that contains two CA certificates marked as trusted and generated certificate and key
- `private.p12` - Java Keytool clone of JKS keystore that uses PKCS#12 format instead of proprientary JKS. Contents are the same as for `private.jks`
