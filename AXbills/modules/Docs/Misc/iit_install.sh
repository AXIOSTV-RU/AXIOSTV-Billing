#!/bin/sh
# ABILLS IIT library install
#
#***********************************************************

LIB_URL="https://iit.com.ua/download/EUSignCP-Perl-20230217.zip"
DOWNLOAD_DIRECTORY="/tmp/iit"
LIBRARY_DIRECTORY="/tmp/iit/library"
BITS=$(getconf LONG_BIT)

mkdir -p "${DOWNLOAD_DIRECTORY}"
mkdir -p "${LIBRARY_DIRECTORY}"

echo "Downloading library zip..."
if ! wget -P "${DOWNLOAD_DIRECTORY}" "${LIB_URL}"; then
  echo "Failed to download the zip archive."
  exit 1
fi

echo "Extracting zip archive..."
if ! unzip -q "${DOWNLOAD_DIRECTORY}/EUSignCP-Perl-20230217.zip" -d "${DOWNLOAD_DIRECTORY}"; then
  echo "Failed to extract the zip archive."
  exit 1
fi

echo "Downloaded EUSignCP-Perl-20230217.zip."

if [ "${BITS}" -eq 64 ]; then
  tar -xvf "${DOWNLOAD_DIRECTORY}/Modules/euscpp.64.tar" -C "${LIBRARY_DIRECTORY}"
else
  tar -xvf "${DOWNLOAD_DIRECTORY}/Modules/euscpp.tar" -C "${LIBRARY_DIRECTORY}"
fi

echo "Extracted euscpp.tar iit library"

echo "Installing packages"
sudo apt update
sudo apt-get install libextutils-makemaker-cpanfile-perl
sudo apt-get install build-essential
echo "Finished installing packages"

# code from library install.sh file
LIB_PATH="/auto/euscpp"
INSTALL_FOLDER=$(perl -MConfig -e 'print($Config{"installsitearch"})')
MODULES_INSTALL_FOLDER="${INSTALL_FOLDER}${LIB_PATH}"

cd /tmp/iit/library/

perl Makefile.PL
make
sudo make install
sudo chmod 0666 "$MODULES_INSTALL_FOLDER/osplm.ini"

CA_CERTIFICATES_URL="https://iit.com.ua/download/productfiles/CACertificates.p7b"

echo "Downloading the file CACertificates.p7b..."
wget "$CA_CERTIFICATES_URL"

certificates_directory="/var/certificates"

if [ -d "$certificates_directory" ]; then
    echo "Repository $repo_directory exists. Moving the file..."
    mv CACertificates.p7b "$certificates_directory/"
    echo "File CACertificates.p7b moved to $certificates_directory/"
else
    echo "Warning: Repository $certificates_directory does not exist. The file was not moved."
fi

CAS_JSON_URL="https://iit.com.ua/download/productfiles/CAs.json"

echo "Downloading the file CAs.json..."
wget "$CAS_JSON_URL"
