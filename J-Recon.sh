#!/bin/bash

echo -n "Enter your domain "
read domain
echo -n "Enter power potential low / high "
read power
sleep 1

echo -n " IS YOUR TARGET RUNS ON WORDPRESS  YES / NO "
read TARGET
 sleep 1

if [ "power" = "low" ];
then 
  bash Jerry.sh -d $domain && bash Z-Recon.sh -d $domain -r
else
  bash Jerry.sh -d $domain -knapb  && bash Z-Recon.sh -d $domain -a --deep
fi

sleep 2

if [ "TARGET" = "yes" ];
then
  php wphunter.php https://$domain && wpsan --url https://$domain -eu vt vp -o "/Recon/wordpress.txt" 
else
  echo "ITS NOT A WORDPRESS SITE "
fi
