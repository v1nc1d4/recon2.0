#!/bin/bash

YELLOW="\033[1;33m"
GREEN="\033[0;32m"
displaylogo(){
    apt install figlet > /dev/null 2>&1
figlet recon.sh
        echo -e "               version 2.0 $YELLOW@blackmarketer"
}
displaylogo

basicRequirements() {
echo -e "$GREEN This script will install the required dependencies to run recon.sh..."
echo -e "$GREEN It will take a while..."
cd "$HOME" || return
sleep 1
git clone https://github.com/blackmarketer/recon2.0
mkdir -p "$HOME"/go
mkdir -p "$HOME"/go/src
mkdir -p "$HOME"/go/bin
mkdir -p "$HOME"/go/pkg
sudo chmod u+w .
}
basicRequirements

golangInstall() {
echo -e "$YELLOW Installing and setting up Go.."
if [[ $(go version | grep -o '1.14') == 1.14 ]]; then
echo -e "$YELLOW Go is already installed, skipping installation"
else
cd "$HOME" || return
	git clone https://github.com/udhos/update-golang
	cd "$HOME"/update-golang || return
	sudo bash update-golang.sh
	sudo cp /usr/local/go/bin/go /usr/bin/ 
	echo -e "$GREEN Done."
fi

echo -e "$GREEN Adding recon alias & Golang to "$HOME"/.bashrc.."
sleep 1
configfile="$HOME"/.bashrc

if [ "$(cat "$configfile" | grep '^export GOPATH=')" == "" ]; then
		echo export GOPATH='$HOME'/go >>"$HOME"/.bashrc
fi

if [ "$(echo $PATH | grep $GOPATH)" == "" ]; then
		echo export PATH='$PATH:$GOPATH'/bin >>"$HOME"/.bashrc
fi

if [ "$(cat "$configfile" | grep '^alias recon=')" == "" ]; then
		echo "alias recon=$HOME/recon2.0/recon.sh" >>"$HOME"/.bashrc
fi

bash /etc/profile.d/golang_path.sh

source "$HOME"/.bashrc

cd "$HOME" || return
echo -e "$YELLOW Golang has been configured."
}
golangInstall

golangTools() {
echo -e "$YELLOW Installing subfinder.."
GO111MODULE=auto go get -u -v github.com/projectdiscovery/subfinder/cmd/subfinder

echo -e "$YELLOW Installing Httpx"
GO111MODULE=auto go get -u -v github.com/projectdiscovery/httpx/cmd/httpx

echo -e "$YELLOW Installing assetfinder.."
go get -u -v github.com/tomnomnom/assetfinder

echo -e "$YELLOW Installing Shuffledns"
GO111MODULE=on go get -u -v github.com/projectdiscovery/shuffledns/cmd/shuffledns

echo -e "$YELLOW Installing ffuf"
go get -u -v github.com/ffuf/ffuf

echo -e "$YELLOW Installing Amass.."
GO111MODULE=on go get -v github.com/OWASP/Amass/v3/...

echo -e "$YELLOW Installing nuclei"
GO111MODULE=on go get -u -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei

echo -e "$YELLOW Installing waybackurls"
go get github.com/tomnomnom/waybackurls
}
golangTools

additionalTools() {
echo -e "$GREEN Installing massdns.."
if [ -e /usr/local/bin/massdns ]; then
		echo -e "$GREEN Already installed."
else
	cd "$HOME" || return
	git clone https://github.com/blechschmidt/massdns.git
	cd "$HOME"/massdns || return
	echo -e "$GREEN Running make command for massdns.."
	make -j
	sudo cp "$HOME"/massdns/bin/massdns /usr/local/bin/
	echo -e "$GREEN Done."
fi

echo -e "$YELLOW Installing nuclei-templates.."
nuclei -update-templates
}
additionalTools

finalizeSetup() {
echo -e "$GREEN Finishing up.."
displayLogo
source "$HOME"/.bashrc || return
echo -e "[$GREEN+$RESET] Installation script finished! "
}