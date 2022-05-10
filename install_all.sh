#!bin/bash


echo "Installing all the dependencies and required materials for running the tool"
# INSTALLING  RECON DEPENDENCIES
bash install.sh 
sleep 2

#INSTALLING VULSCAN FOR CVE LOOKUP
git clone https://github.com/scipag/vulscan scipag_vulscan
ln -s `pwd`/scipag_vulscan /usr/share/nmap/scripts/vulscan    

#INSTALLING THE ACTIVE RECON
bash install_tools.sh
sleep 2

# INSTALLING THE CRAZIEST ONE 
bash setup.sh
sleep 2
echo "If any tool got not install then plz install them manually for complete useage of the tool"
sleep 2
echo "Installation process for J-Recon tool was succeed"
