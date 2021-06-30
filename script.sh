#/bin/bash
certs_dir="/etc/pki1/"
home_dir=$(pwd)

value_subj="/C=RU/ST=Moscow\
/L=Moscow/O=WunderWafli\
/OU=IT/CN=?\
/emailAddress=supoort@demo.lab"

if ! [[ -d $certs_dir ]]; then
  mkdir -p $certs_dir
  cd $certs_dir
else
  echo "directory exists"
  exit 1
fi

create_certificate () {
  export SSLSAN="email:support@demo.lab,DNS:${2},DNS:${2}.demo.lab"
  openssl req \
    -config openssl.cnf \
    ${3} \
    -nodes \
    -extensions $1 \
    -subj ${value_subj/\?/${2}} \
    -key private.pem \
    -out public.pem
}

sign_certificate () {
  openssl ca \
    -config openssl.cnf \
    -notext \
    -extensions $1 \
    -in "${work_dir}/public.pem" \
    -out "${work_dir}/public.pem"
}

create_files () {
  mkdir crl certs requests newcerts
  touch index.txt index.txt.attr
  echo 01 > serial
}


for cert in ${certs[@]}
do
  work_dir="$(pwd)/${cert}"
  mkdir $work_dir && cd $work_dir
  cp ${home_dir}/openssl.cnf .
  create_files
  openssl genrsa -out private.pem &> /dev/null

  if [[ $cert == "CA" ]]; then
    create_certificate "v3_ca" "CA" "-x509"
  elif [[ $cert == "intermediate" || $cert == "squid" ]]; then
    create_certificate "v3_intermediate_ca" ${cert} "-new"
    cd ../CA
    sign_certificate "v3_intermediate_ca"
  else
    create_certificate "server_cert" ${cert} "-new"
    cd ../intermediate
    sign_certificate "server_cert"
  fi

  cd $certs_dir
done