#!bin/bash


echo "Installing all the dependencies and required materials for running the tool"
# INSTALLING  RECON DEPENDENCIES
bash install.sh 
sleep 2 

#INSTALLING THE ACTIVE RECON
bash install_tools.sh
sleep 2

# INSTALLING THE CRAZIEST ONE 
bash setup.sh
sleep 2
echo "If any tool got not install then plz install them manually for complete useage of the tool"
sleep 2
echo "Installation process for J-Recon tool was succeed"
