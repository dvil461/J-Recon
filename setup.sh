pip3 install -r requirements.txt
chmod +x Jerry.sh

#Tools

echo "Installing subfinder"

apt-get install subfinder
#knock.py

git clone https://github.com/guelfoweb/knock.git
cd knock
pip3 install -r requirements.txt
mv knockpy.py /usr/bin

#arjun
apt-get install arjun

#Photon
git clone https://github.com/s0md3v/Photon.git

#Sublist3r
apt-get install sublist3r

#dirsearch
apt-get install dirsearch

#subdomain-takeover
git clone https://github.com/antichown/subdomain-takeover.git

#Aquatone
echo "Installing Aquatone-discover"
wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip
unzip aquatone_linux_amd64_1.7.0.zip
mv aquatone /usr/bin

#Amass
echo "Installing Amass"

#cloning massdns
git clone https://github.com/blechschmidt/massdns.git

if [[ $(uname) = 'Darwin' ]]
then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  brew tap caffix/amass
  brew install amass findomain nmap

  echo "Installing MassDNS"
  cd massdns; make nolinux; cd ..

else
  sudo apt-get update
  sudo apt-get install -y amass nmap golang

  echo "Installing Findomain"
  wget https://github.com/Edu4rdSHL/findomain/releases/latest/download/findomain-linux
  chmod +x findomain-linux
  mv findomain-linux findomain

  echo "Installing MassDNS"
  cd massdns; make; cd ..

fi

go get -u github.com/tomnomnom/httprobe
