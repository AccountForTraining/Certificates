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

preparation_folder () {
  work_dir="$(pwd)/${1}"
  mkdir $work_dir && cd $work_dir
  cp ${home_dir}/openssl.cnf .
  create_files
  openssl genrsa -out private.pem &> /dev/null
}


root=CA

intermediates=(intermediate proxy)

server_certs=(iwtm iwtm-node mail)


# Main code

# ----- generate CA -----
preparation_folder CA
create_certificate "v3_ca" "CA" "-x509"
cd $certs_dir

# ----- generate intermediate -----
for cert in ${intermediates[@]}
do
  preparation_folder $cert
  create_certificate "v3_intermediate_ca" ${cert} "-new"
  cd ../${root}
  sign_certificate "v3_intermediate_ca"
  cd $certs_dir
done


for cert in ${server_certs[@]}
do
  preparation_folder $cert
  
  create_certificate "server_cert" ${cert} "-new"
  cd ../${intermediates[0]}
  sign_certificate "server_cert"
  cd $certs_dir
done