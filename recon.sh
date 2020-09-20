#!/bin/bash

YELLOW="\033[1;33m"
GREEN="\033[0;32m"
domain=$1
wordlist="$HOME/SecLists/Discovery/DNS/all.txt"
resolvers="$HOME/resolvers.txt"
slack_url=""

displaylogo(){
    apt install figlet > /dev/null 2>&1
figlet recon.sh
        echo -e "               version 2.0 $YELLOW@blackmarketer"
}
displaylogo

checkArguments() {
		if [[ -z $domain ]]; then
			echo -e "$GREEN Usage: ./recon <domain.com>"
			exit 1
		fi
}
makedir() {
mkdir -p $domain $domain/sources $domain/recon $domain/nuclei $domain/recon/wayback $domain/recon/gf
}
makedir

gatherfiles() {
    
	echo -e "$GREEN Get fresh working resolvers and wordlist"
	
	wget -q https://raw.githubusercontent.com/BBerastegui/fresh-dns-servers/master/resolvers.txt -O $HOME/resolvers.txt
	wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/dns-Jhaddix.txt -O $HOME/all.txt
}
gatherfiles

subdomin_enum(){
subfinder -d $domain -o $domain/sources/subfinder.txt

assetfinder -subs-only $domain | tee $domain/sources/assetfinder.txt

amass enum -passive -d $domain -o $domain/sources/passive.txt

shuffledns -d $domain -w $wordlist -r $resolvers -o $domain/sources/shuffledns.txt

}
subdomin_enum

listing(){

cat $domain/sources/*.txt > $domain/sources/all.txt
}
listing

resolving(){
shuffledns -d $domain -list $domain/sources/all.txt -o $domain/domains.txt -r $resolvers
}
resolving

httpx(){
cat $domain/domains.txt | httpx -threads 200 -o $domain/recon/httpx.txt
}
httpx

nuclei(){
echo -e "$YELLOW Nuclei CVEs Detection"

nuclei -l $domain/recon/httpx.txt -t $HOME/nuclei-templates/cves/ -o $domain/nuclei/cve.txt

echo -e "$YELLOW Nuclei takeover Detection"

nuclei -l $domain/recon/httpx.txt -t $HOME/nuclei-templates/subdomain-takeover/ -o $domain/nuclei/takeover.txt

echo -e "$YELLOW Nuclei vulnerabilities Detection"

nuclei -l $domain/recon/httpx.txt -t $HOME/nuclei-templates/vulnerabilities/ -o $domain/nuclei/vulnerabilities.txt

echo -e "$YELLOW Nuclei files Detection"

nuclei -l $domain/recon/httpx.txt -t $HOME/nuclei-templates/files/ -o $domain/nuclei/files.txt

echo -e "$YELLOW Nuclei misconfiguration Detection"

nuclei -l $domain/recon/httpx.txt -t $HOME/nuclei-templates/security-misconfiguration/ -o $domain/nuclei/misconfiguration.txt

echo -e "$YELLOW Nuclei technologies Detection"

nuclei -l $domain/recon/httpx.txt -t $HOME/nuclei-templates/technologies/ -o $domain/nuclei/technologies.txt

echo -e "$YELLOW Nuclei panels Detection"

nuclei -l $domain/recon/httpx.txt -t $HOME/nuclei-templates/panels/ -o $domain/nuclei/panels.txt

}
nuclei

waybackurl(){
cat $domain/doamins.txt | waybackurls | tee $domain/recon/wayback/tmp.txt

cat $domain/recon/wayback/tmp.txt | egrep -v "\.woof |\.tff|\.svg|\.eot|\.png|\.jpg|\.jpeg|\.css|\.ico|\.gif" | sed 's/:80//g;s/:443//g' | sort -u >> $domain/recon
/wayback/wayback.txt

rm $domain/recon/wayback/tmp.txt
}
waybackurl

ffuf(){
ffuf -c -u "FUZZ" -w $domain/recon/wayback/wayback.txt -of csv -o $domain/recon/wayback/val-tmp.txt
cat $domain/recon/wayback/val-tmp.txt | grep http | awk -F "," '{print $1}' > $domain/recon/wayback/valid.txt

rm $domain/recon/wayback/val-tmp.txt
}
ffuf

notifySlack(){
echo -e "$GREEN Trigger Slack Notification"
takeover="$($domain/nuclei/takeover.txt | wc -l)"
totalsum=$(cat $domain/recon/httpx.txt | wc -l)
intfiles=$(cat $domain/nuclei/*.txt | wc -l)
nucleiCveScan="$(cat $domain/nuclei/cve.txt)"
nucleiFileScan="$(cat $domain/nuclei/files.txt)"
nucleiVulnscan="$(cat $domain/nuclei/vulnerabilities.txt)"
nucleiTechscan="$(cat $domain/nuclei/technologies.txt | wc -l)"
nucleiMisconfscan="$(cat $domain/nuclei/misconfiguration.txt | wc -l)"
nucleiPanelscan="$(cat $domain/nuclei/panels/panels.txt | wc -l)"

curl -s -X POST -H 'Content-type: application/json' --data '{"text":"Found '$totalsum' live hosts for '$domain'"}' $slack_url 2 > /dev/null
curl -s -X POST -H 'Content-type: application/json' --data '{"text":"Found '$intfiles' interesting files using nuclei"}' $slack_url 2 > /dev/null
curl -s -X POST -H 'Content-type: application/json' --data '{"text":"Found '$takeover' subdomain takeovers on '$domain'"}' $slack_url 2 > /dev/null
curl -s -X POST -H 'Content-type: application/json' --data "{'text':'CVEs found for $domain: \n $nucleiCveScan'}" $slack_url 2>/dev/null
curl -s -X POST -H 'Content-type: application/json' --data "{'text':'Files for $domain: \n $nucleiFileScan'}" $slack_url 2>/dev/null
curl -s -X POST -H 'Content-type: application/json' --data "{'text':'vulnerabilities Found for $domain: \n $nucleiVulnscan'}" $slack_url 2>/dev/null
curl -s -X POST -H 'Content-type: application/json' --data "{'text':'technologies Found for $domain: \n $nucleiTechscan'}"$slack_url 2>/dev/null
curl -s -X POST -H 'Content-type: application/json' --data "{'text':'misconfiguration Found for $domain: \n $nucleiMisconfscan'}" $slack_url 2>/dev/null
curl -s -X POST -H 'Content-type: application/json' --data "{'text':'Panels Found for $domain: \n $nucleiPanelscan'}" $slack_url 2>/dev/null
echo -e "$GREEN Done."
}
notifySlack