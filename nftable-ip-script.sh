#!/bin/bash
function usage () {
	echo "PROGRAM USAGE!"
	echo
echo "################################"
echo "NFTables Removal CLI"
echo
echo "Provide IP as argument 1 to block the IP"
echo "Provide No argument to enter removal mode"
}
usage

IP_ALREADY_IN_SET=$(nft list set ip block_traffic blackhole |awk '/{ /,/}/' | cut -d '=' -f 2)
echo
echo "----------------------------------------------"
function show_elements () {
echo "Blackhole set Elements - "
echo
for i in "${IP_ALREADY_IN_SET[@]}";do printf "%s\n" "${i}";done 
echo
echo

}

if [[ ${IP_ALREADY_IN_SET[*]} =~ "${1}" ]]
then
	echo "$IP_ALREADY_IN_SET is already in set"
else
	echo "IP not in set continue"


fi




if [[ ${1} == "" ]];then 
	echo "Entering Removal Mode"
	nft list sets ip
	read -p 'Select set name: ' SET_NAME
	read -p 'Select IP to remove ' IP_TO_REMOVE

	nft delete element ip block_traffic $SET_NAME \{"${IP_TO_REMOVE}"\}
	if [[ $? -eq 0 ]];then echo "IP ${IP_TO_REMOVE} was Removed From Set: ${SET_NAME}"
		echo "Exitting Program."
		exit 1
	fi
else
	IP_ADDR="${1}"
	nft add element ip block_traffic blackhole \{"${IP_ADDR}"\}

        echo "IP: ${IP_ADDR} was added to drop set"
        echo "IP's in blackhole drop set cant reach the server"
		(exit 1)


fi
if [[ $? -eq 0 ]];then
show_elements
fi
