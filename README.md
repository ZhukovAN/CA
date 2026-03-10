# Simple two-tier certification authority (CA)

Certificates are everywhere: currently about 80% of web sites use secure HTTPS protocol that uses certificates, people use certificates for VPN, client-side authentication, digital signatures, etc. It means that sometimes you may need to generate certificates for your own needs. If you have access to your company's certification authority then you may simply ask CA team to generate that certificate for you, but if you haven't one then certificates are to be generated manually using OpenSSL tool. 

There's a lot of HOWTO's about using OpenSSL, but sometimes those manuals are trivial like create self-signed certificate for web server. That's OK for pet projects, but if you want to be sure that your application will work in the enterprise environment with strict CA policy than you need to implement more complex "chained" approach where there are to be at least one trusted root CA and one intermediate CA.

This repository is about how to create your own two-tier CA hierarchy that allows you to use dockerized bash scripts to generate certificates for different purposes like SSL server and additional intermediate certification authority.

## Build CA image using Docker
``` bash
docker build --tag ptdemo/ca:latest .
```

## Configure CA

Create container and init its data and configuration folders:

``` bash
docker create \
  --volume ptdemo-ca-data:/var/lib/ca \
  --volume ptdemo-ca-config:/etc/ca:ro \
  ptdemo/ca:latest
```

Edit `/etc/ca/environment.conf` file and set organization name and common names for root and intermediate repository:

```
ORGANIZATION                = Domain.ORG
ROOT_CA_CN                  = $ORGANIZATION company Root CA
INTERMEDIATE_CA_CN          = $ORGANIZATION company Intermediate CA
```

## Use CA image

When started, CA image container checks its mapped `/var/lib/ca/data` folder for a presence of a root- and intermediate CA private keys. If those are not found, CA data initialization procedure is started. That procedure includes:
- CA files / folder structure creation:
    - `${CA}/data/certs`: DER- and PEM-encoded CA certificates;
    - `${CA}/data/crl`: DER- and PEM-encoded certificate revocation lists (CRL);
    - `${CA}/data/db`: internal OpenSSL database files that store serial numbers, certificate lists etc.;
    - `${CA}/data/out`: certificates signed by CA, see details [here](#generated-files);
    - `${CA}/data/private`: unencrypted PEM-encoded CA private key
- generation of root CA self-signed certificate;
- generation of intermediate CA certificate signing request (CSR);
- sign intermediate CA's CSR with root CA private key
- CRL generation for both root and intermediate CA

CA data files include configuration settings, internal entities like keys, certificates database, serials etc., and certificates signed by corresponding CA. Those files are stored in `/etc/ca/conf` and `/var/lib/ca/data` folders and should use Docker's named folders to persist values between CA image runs.
After startup procedure container's entry point script executes certificate generation task. Currently only SSL server certificate task is supported

### Generate SSL server certificate

Following command generates SSL server certificate with subjectAlternativeName set to `DNS:*.ptdemo.local` value:

``` bash
docker run --rm -it \
  --volume ptdemo-ca-data:/var/lib/ca \
  --volume ptdemo-ca-config:/etc/ca:ro \
  ptdemo/ca:latest \
  generateSslServerCertificate "DNS:*.ptdemo.local"
```

### Generate "out of scope" intermediate CA certificate

Sometimes we need to generate private key and intermediate CA certificate for out of scope certificate operations. For example, we may need to provide Kubernetes with trusted intermediate certificate and key to generate bunch of certificates for automated ETCD, API server, kubelets etc. certificate provisioning during cluster initialization phase. Following command generates root CA's subordinate authority certificate and key with subject set to `PTDemo.LOCAL K8s Intermediate CA` value:

``` bash
docker run --rm -it \
  --volume ptdemo-ca-data:/var/lib/ca \
  --volume ptdemo-ca-config:/etc/ca:ro \
  ptdemo/ca:latest \
  generateIntermediateCaCertificate "PTDemo.LOCAL K8s Intermediate CA"
```

## Generated files

Files generated during certificate generation process are copied into container's `/var/lib/ca/data/${CA}/out/${serial}` folder. Some files are hold private keys and use P@ssw0rd for protection. For SSL server certificates following files are generated:
- `key.pem` - unencrypted certificate private key;
- `csr.pem` - certificate signing request stored as PEM file;
- `server.crt` and `server.pem` - generated certificate stored as DER- and PEM files;
- `server.brief.pem` and `server.brief.pfx` - PKCS#12-encoded certificate / key container. Doesn't contain CA certificates;
- `server.full.pem` and `server.full.pfx` - PKCS#12-encoded certificate / key container. Includes full CA certificate chain;
- `ca.pem` - PEM-encoded CA certificates chain file that includes both root- and intermediate CA certificates;
- `trust.jks` - Java keystore file that contains two CA certificates marked as trusted;
- `private.jks` - Java keystore file that contains two CA certificates marked as trusted and generated certificate and key;
- `private.p12` - Java Keytool clone of JKS keystore that uses PKCS#12 format instead of proprientary JKS. Contents are the same as for `private.jks`;
