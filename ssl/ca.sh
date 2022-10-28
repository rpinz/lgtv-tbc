#!/usr/bin/env bash
#
# OpenSSL root/intermediate Certificate Authority certificates
#         asterisk wildcard certficate
#
# https://jamielinux.com/docs/openssl-certificate-authority/
# https://mariadb.com/docs/security/data-in-transit-encryption/create-self-signed-certificates-keys-openssl/
#

#set -x

CA_DIR="/build"
CA_PATH=
CA_CRLNUMBER="01"

ROOT_CA_DIR="${CA_DIR}/root"
ROOT_CA_KEY="${ROOT_CA_DIR}/private/ca.key.pem"
ROOT_CA_CERT="${ROOT_CA_DIR}/certs/ca.cert.pem"
ROOT_CA_CONFIG="${ROOT_CA_DIR}/openssl.cnf"
ROOT_CA_BITS="4096"
ROOT_CA_DAYS="365000"
ROOT_CA_EXTENSIONS="v3_ca"

INT_CA_DIR="${CA_DIR}/intermediate"
INT_CA_KEY="${INT_CA_DIR}/private/intermediate.key.pem"
INT_CA_CSR="${INT_CA_DIR}/csr/intermediate.csr.pem"
INT_CA_CERT="${INT_CA_DIR}/certs/intermediate.cert.pem"
INT_CA_CONFIG="${INT_CA_DIR}/openssl.cnf"
INT_CA_CHAIN="${INT_CA_DIR}/certs/ca-chain.cert.pem"
INT_CA_FULLCHAIN="${INT_CA_DIR}/certs/ca-fullchain.cert.pem"
INT_CA_BITS="4096"
INT_CA_DAYS="36500"
INT_CA_EXTENSIONS="v3_intermediate_ca"

LGTV_TBC_DIR="${CA_DIR}/intermediate"
LGTV_TBC_KEY="${INT_CA_DIR}/certs/lgtv-tbc.key.pem"
LGTV_TBC_CSR="${INT_CA_DIR}/certs/lgtv-tbc.csr.pem"
LGTV_TBC_CERT="${INT_CA_DIR}/certs/lgtv-tbc.cert.pem"
LGTV_TBC_CONFIG="${INT_CA_DIR}/openssl_lgtv_tbc.cnf"
LGTV_TBC_DAYS="3650"
LGTV_TBC_BITS="2048"
LGTV_TBC_EXTENSIONS="server_cert"

is_root() {
  if [ "$(id -u)" -ne 0 ]; then
     echo "🔒 Please run $0 as root user."
     exit 1
  fi
}

setup() {
  echo "🔒 Setting up ${CA_PATH} directory"
  CA_PATH="${CA_DIR}/$1"
  mkdir -p "${CA_PATH}"
  cp "openssl_${1}.cnf" "${CA_PATH}/openssl.cnf"
  pushd "${CA_PATH}"
  mkdir -p certs crl csr newcerts private
  chmod 700 private
  touch index.txt
  echo "${CA_CRLNUMBER}" > serial
  popd
}

root_ca_key() {
  echo "🔒 Generating CA private key"
  openssl genrsa \
    -aes256 \
    -out "${ROOT_CA_KEY}" \
    "${ROOT_CA_BITS}"
  chmod 400 "${ROOT_CA_KEY}"
}

root_ca_cert() {
  echo "🔒 Generating CA X509 certificate"
  openssl req \
    -subj "/C=US/O=lgtv-tbc/CN=lgtv-tbc root CA" \
    -config "${ROOT_CA_CONFIG}" \
    -key "${ROOT_CA_KEY}" \
    -new \
    -x509 \
    -sha256 \
    -days "${ROOT_CA_DAYS}" \
    -extensions "${ROOT_CA_EXTENSIONS}" \
    -out "${ROOT_CA_CERT}"
  chmod 444 "${ROOT_CA_CERT}"
}

root_ca_verify() {
  echo "🔒 Verifying root certificate"
  openssl x509 \
    -noout \
    -text \
    -in "${ROOT_CA_CERT}"
}

root() {
  echo "🔒 /root CA"
  setup root
  pushd "${ROOT_CA_DIR}"
  root_ca_key
  root_ca_cert
  root_ca_verify
  popd
}

int_ca_key() {
  echo "🔒 Generating intermediate CA private key"
  openssl genrsa \
    -aes256 \
    -out "${INT_CA_KEY}" \
    "${INT_CA_BITS}"
  chmod 400 "${INT_CA_KEY}"
}

int_ca_csr() {
  echo "🔒 Generating intermediate CA certificate signing request"
  openssl req \
    -subj "/C=US/O=lgtv-tbc/CN=lgtv-tbc intermediate CA" \
    -config "${INT_CA_CONFIG}" \
    -key "${INT_CA_KEY}" \
    -new \
    -sha256 \
    -out "${INT_CA_CSR}"
  chmod 444 "${INT_CA_CSR}"
}

int_ca_cert() {
  echo "🔒 Generating intermediate CA certificate"
  openssl ca \
    -config "${ROOT_CA_CONFIG}" \
    -in "${INT_CA_CSR}" \
    -notext \
    -md sha256 \
    -days "${INT_CA_DAYS}" \
    -extensions "${INT_CA_EXTENSIONS}" \
    -out "${INT_CA_CERT}"
  chmod 444 "${INT_CA_CERT}"
}

int_ca_verify() {
  echo "🔒 Verifying intermediate certificate"
  openssl x509 \
    -noout \
    -text \
    -in "${INT_CA_CERT}"

  echo "🔒 Verifying intermediate certificate against root certificate"
  pushd "${CA_DIR}"
  openssl verify \
    -CAfile "${ROOT_CA_CERT}" \
    "${INT_CA_CERT}"
  popd
}

chain() {
  cat "${INT_CA_CERT}" > "${INT_CA_CHAIN}"
  cat "${INT_CA_CERT}" "${ROOT_CA_CERT}" > "${INT_CA_FULLCHAIN}"
  chmod 444 "${INT_CA_CHAIN}" "${INT_CA_FULLCHAIN}"
}

intermediate() {
  echo "🔒 Intermediate CA"
  setup intermediate
  pushd "${INT_CA_DIR}"
  echo "${CA_CRLNUMBER}" > crlnumber
  int_ca_key
  int_ca_csr
  int_ca_cert
  int_ca_verify
  popd
  chain
}

lgtv_tbc_key() {
  echo "🔒 Generating lgtv_tbc private key and certificate request"
  openssl genrsa \
    -out "${LGTV_TBC_KEY}" \
    "${LGTV_TBC_BITS}"
  chmod 400 "${LGTV_TBC_KEY}"
}

lgtv_tbc_csr() {
  echo "🔒 Generating lgtv_tbc X509 certificate signing request"
  openssl req \
    -new \
    -nodes \
    -key "${LGTV_TBC_KEY}" \
    -out "${LGTV_TBC_CSR}" \
    -subj "/CN=lgtvsdp.com" \
    -config "${LGTV_TBC_CONFIG}"
  chmod 444 "${LGTV_TBC_CSR}"
}

lgtv_tbc_cert() {
  echo "🔒 Generating lgtv_tbc X509 certificate"
  openssl ca \
    -in "${LGTV_TBC_CSR}" \
    -notext \
    -md sha256 \
    -days "${LGTV_TBC_DAYS}" \
    -extensions "${LGTV_TBC_EXTENSIONS}" \
    -out "${LGTV_TBC_CERT}" \
    -config "${LGTV_TBC_CONFIG}"
  chmod 444 "${LGTV_TBC_CERT}"
}

lgtv_tbc_verify() {
  echo "🔒 Verifying lgtv_tbc certificate"
  openssl x509 \
    -noout \
    -text \
    -in "${LGTV_TBC_CERT}"

  echo "🔒 Verifying lgtv_tbc certificate against full chain"
  pushd "${CA_DIR}"
  openssl verify \
    -CAfile "${INT_CA_FULLCHAIN}" \
    "${LGTV_TBC_CERT}"
  popd
}

lgtv_tbc() {
  echo "🔒 lgtv_tbc"
  cp "openssl_lgtv_tbc.cnf" "${LGTV_TBC_CONFIG}"
  pushd "${LGTV_TBC_DIR}"
  lgtv_tbc_key
  lgtv_tbc_csr
  lgtv_tbc_cert
  lgtv_tbc_verify
  popd
}

archive() {
  echo "🔒 archiving certificates"
  pushd "${CA_DIR}"
  mkdir -p ssl
  cp root/private/ca.key.pem ssl/root.key.pem
  cp root/certs/ca.cert.pem ssl/root.cert.pem
  cp intermediate/private/intermediate.key.pem ssl/intermediate.key.pem
  cp intermediate/certs/intermediate.cert.pem ssl/intermediate.cert.pem
  cp root/certs/ca.cert.pem ssl/LG_TV_TakeBackControl_Root.crt
  cp intermediate/certs/intermediate.cert.pem ssl/LG_TV_TakeBackControl_Intermediate.crt
  cp intermediate/certs/ca-fullchain.cert.pem ssl/ca-fullchain.cert.pem
  cp intermediate/certs/ca-chain.cert.pem ssl/ca-chain.cert.pem
  cp intermediate/certs/lgtv-tbc.key.pem ssl/lgtv-tbc.key.pem
  cp intermediate/certs/lgtv-tbc.csr.pem ssl/lgtv-tbc.csr.pem
  cp intermediate/certs/lgtv-tbc.cert.pem ssl/lgtv-tbc.cert.pem
  tar cfJ ssl.tar.xz \
    ssl/root.key.pem \
    ssl/root.cert.pem \
    ssl/intermediate.key.pem \
    ssl/intermediate.cert.pem \
    ssl/LG_TV_TakeBackControl_Root.crt \
    ssl/LG_TV_TakeBackControl_Intermediate.crt \
    ssl/ca-fullchain.cert.pem \
    ssl/ca-chain.cert.pem \
    ssl/lgtv-tbc.key.pem \
    ssl/lgtv-tbc.csr.pem \
    ssl/lgtv-tbc.cert.pem
  popd
  mv "${CA_DIR}/ssl" build
  mv "${CA_DIR}/ssl.tar.xz" ../nginx
}

# setup directories
#is_root

# create root CA
root

# create intermediate CA
intermediate

# create lgtv_tbc
lgtv_tbc

# create tarball of certs
archive
