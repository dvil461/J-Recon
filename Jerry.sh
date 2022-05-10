#!/bin/bash
echo "
 Jerry

"

help(){
  echo "
Usage: ./Jerry.sh [options] -d domain.com
Options:
    -h            Display this help message.
    -k            Run Knockpy on the domain.
    -n            Run Nmap on all subdomains found.
    -a            Run Arjun on all subdomains found.
    -p            Run Photon crawler on all subdomains found.
    -b            Run Custom Bruteforcer to find subdoamins.

  Target:
    -d            Specify the domain to scan.

Example:
    ./Jerry.sh -d hackerone.com
"
}

POSITIONAL=()

if [[ "$*" != *"-d"* ]]
then
	help
  exit
fi

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    help
    exit
    ;;
    -d|--domain)
    d="$2"
    shift
    shift
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo "Starting SubEnum $d"

echo "Creating directory"
set -e
#if [ ! -d $PWD/J-Recon ]; then
#	mkdir Recon
#fi
if [ ! -d $PWD/J-Recon/$d ]; then
	mkdir Recon/$d
fi
source tokens.txt

echo "Starting our subdomain enumeration force..."

echo "Starting Sublist3r..."
sublist3r -d "$d" -o Recon/$d/fromsublister.txt

echo "Amass turn..."
amass enum --passive -d $d -o Recon/$d/fromamass.txt

echo "Starting subfinder..."
subfinder -d $d -o Recon/$d/fromsubfinder.txt -v --exclude-sources dnsdumpster

echo "Starting assetfinder..."
assetfinder --subs-only $d > Recon/$d/fromassetfinder.txt

echo "Starting aquatone-discover"
aquatone-discover -d $d --disable-collectors dictionary -t 300
rm -rf amass_output
cat ~/aquatone/$d/hosts.txt | cut -f 1 -d ',' | sort -u >> Recon/$d/fromaquadiscover.txt
rm -rf ~/aquatone/$d/

echo "Starting github-subdomains..."
python3 github-subdomains.py -t $github_token_value -d $d | sort -u >> Recon/$d/fromgithub.txt

echo "Starting findomain"
export findomain_fb_token="$findomain_fb_token"
export findomain_spyse_token="$findomain_spyse_token"
export findomain_virustotal_token="$findomain_virustotal_token"

./findomain -t $d -r -u Recon/$d/fromfindomain.txt

nl=$'\n'
echo "Starting bufferover"
curl "http://dns.bufferover.run/dns?q=$d" --silent | jq '.FDNS_A | .[]' -r 2>/dev/null | cut -f 2 -d',' | sort -u >> Recon/$d/frombufferover-dns.txt
echo "$nl"
echo "Bufferover DNS"
echo "$nl"
cat Recon/$d/frombufferover-dns.txt
curl "http://dns.bufferover.run/dns?q=$d" --silent | jq '.RDNS | .[]' -r 2>/dev/null | cut -f 2 -d',' | sort -u >> Recon/$d/frombufferover-dns-rdns.txt
echo "$nl"
echo "Bufferover DNS-RDNS"
echo "$nl"
cat Recon/$d/frombufferover-dns-rdns.txt
curl "http://tls.bufferover.run/dns?q=$d" --silent | jq '. | .Results | .[]'  -r 2>/dev/null | cut -f 3 -d ',' | sort -u >> Recon/$d/frombufferover-tls.txt
echo "$nl"
echo "Bufferover TLS"
echo "$nl"
cat Recon/$d/frombufferover-tls.txt

if [[ "$*" = *"-b"* ]]
then
  echo "Starting our custom bruteforcer"
  for sub in $(cat subdomains.txt); do echo $sub.$d >> /tmp/sub-$d.txt; done
  ./massdns/bin/massdns -r massdns/lists/resolvers.txt -s 1000 -q -t A -o S -w /tmp/subresolved-$d.txt /tmp/sub-$d.txt
  rm /tmp/sub-$d.txt
  awk -F ". " "{print \$d}" /tmp/subresolved-$d.txt | sort -u >> Recon/$d/fromcustbruter.txt
  rm /tmp/subresolved-$d.txt
fi
cat Recon/$d/*.txt | grep $d | grep -v '*' | sort -u  >> Recon/$d/alltogether.txt

echo "Deleting other(older) results"
rm -rf Recon/$d/from*

echo "Resolving - Part 1"
./massdns/bin/massdns -r massdns/lists/resolvers.txt -s 1000 -q -t A -o S -w /tmp/massresolved1.txt Recon/$d/alltogether.txt
awk -F ". " "{print \$1}" /tmp/massresolved1.txt | sort -u >> Recon/$d/resolved1.txt
rm /tmp/massresolved1.txt
rm Recon/$d/alltogether.txt

echo "Removing wildcards"
python3 wildcrem.py Recon/$d/resolved1.txt >> Recon/$d/resolved1-nowilds.txt
rm Recon/$d/resolved1.txt

echo "Starting AltDNS..."
altdns -i Recon/$d/resolved1-nowilds.txt -o Recon/$d/fromaltdns.txt -t 300

echo "Resolving - Part 2 - Altdns results"
./massdns/bin/massdns -r massdns/lists/resolvers.txt -s 1000 -q -o S -w /tmp/massresolved1.txt Recon/$d/fromaltdns.txt
awk -F ". " "{print \$1}" /tmp/massresolved1.txt | sort -u >> Recon/$d/altdns-resolved.txt
rm /tmp/massresolved1.txt
rm Recon/$d/fromaltdns.txt

echo "Removing wildcards - Part 2"
python3 wildcrem.py Recon/$d/altdns-resolved.txt >> Recon/$d/altdns-resolved-nowilds.txt
rm Recon/$d/altdns-resolved.txt

cat Recon/$d/*.txt | sort -u >> Recon/$d/alltillnow.txt
rm Recon/$d/altdns-resolved-nowilds.txt
rm Recon/$d/resolved1-nowilds.txt

echo "Starting DNSGEN..."
dnsgen Recon/$d/alltillnow.txt >> Recon/$d/fromdnsgen.txt

echo "Resolving - Part 3 - DNSGEN results"
./massdns/bin/massdns -r massdns/lists/resolvers.txt -s 1000 -q -t A -o S -w /tmp/massresolved1.txt Recon/$d/fromdnsgen.txt
awk -F ". " "{print \$1}" /tmp/massresolved1.txt | sort -u >> Recon/$d/dnsgen-resolved.txt
rm /tmp/massresolved1.txt
#rm /tmp/forbrut.txt
rm Recon/$d/fromdnsgen.txt

echo "Removing wildcards - Part 3"
python3 wildcrem.py Recon/$d/dnsgen-resolved.txt >> Recon/$d/dnsgen-resolved-nowilds.txt
rm Recon/$d/dnsgen-resolved.txt

cat Recon/$d/alltillnow.txt | sort -u >> Recon/$d/$d.txt
rm Recon/$d/dnsgen-resolved-nowilds.txt
rm Recon/$d/alltillnow.txt

echo "Appending http/s to hosts"
for i in $(cat Recon/$d/$d.txt); do echo "http://$i" && echo "https://$i"; done >> Recon/$d/with-protocol-domains.txt
cat Recon/$d/$d.txt | ~/go/bin/httprobe | tee -a Recon/$d/alive.txt

echo "Taking screenshots..."
cat Recon/$d/with-protocol-domains.txt | aquatone -ports xlarge -out Recon/$d/aquascreenshots

if [[ "$*" = *"-a"* ]]
then
	cat Recon/$d/$d.txt | ~/go/bin/httprobe | tee -a Recon/$d/alive.txt
	arjun -i Recon/$d/alive.txt -m get -o Recon/$d/arjun_out.txt
fi


echo "Total hosts found: $(wc -l Recon/$d/$d.txt)"

if [[ "$*" = *"-n"* ]]
then
	echo "Starting Nmap"
  if [ ! -d $PWD/Recon/$d/nmap ]; then
  	mkdir Recon/$d/nmap
  fi
	for i in $(cat Recon/$d/$d.txt); do nmap -sC -sV $i -o Recon/$d/nmap/$i.txt; done
fi

if [[ "$*" = *"-p"* ]]
then
	echo "Starting Photon Crawler"
  if [ ! -d $PWD/Recon/$d/photon ]; then
  	mkdir Recon/$d/photon
  fi
	for i in $(cat Recon/$d/$d.txt); do python3 Photon/photon.py -u $i -o Recon/$d/photon/$i -l 2 -t 50; done
fi

echo "Checking for Subdomain Takeover"
python3 subdomain-takeover/takeover.py -d $d -f Recon/$d/$d.txt -t 20 | tee Recon/$d/subdomain_takeover.txt

echo "Starting DirSearch"
if [ ! -d $PWD/Recon/$d/dirsearch ]; then
	mkdir Recon/$d/dirsearch
fi
#for i in $(cat Recon/$d/$d.txt); do
 #  dirsearch -e php,asp,aspx,jsp,html,zip,jar -t 80 -u $i -o "Recon/$d/dirsearch/$i.txt"; done

echo "Finished successfully."
