#!/bin/bash

### Script to download addresses from ad-server lists and modify them for use in
### a DNSMASQ host file which will redirect those addresses to 0.0.0.0

## Variables used in this script
dummyaddr = "0.0.0.0"   # suggest using a non-routable address here to avoid waiting on localhost timouts
listpath = "."


## Download source files using wget, rename them and save to 'sources' folder
echo "Downloading ad-block list source files"
wget -t 3 -T 60 -P sources -O stevenblack.txt https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
wget -t 3 -T 60 -P sources -O malwaredomains.txt https://mirror1.malwaredomains.com/files/justdomains
wget -t 3 -T 60 -P sources -O sysctl.txt http://sysctl.org/cameleon/hosts
wget -t 3 -T 60 -P sources -O abuse-ch.txt https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist
wget -t 3 -T 60 -P sources -O disconnect-simple_tracking.txt https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
wget -t 3 -T 60 -P sources -O disconnect-simple_ad.txt https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
wget -t 3 -T 60 -P sources -O hostsfile-adservers.txt https://hosts-file.net/ad_servers.txt

## Cleanup the files (remove comments, errant ip addresses, etc.)
echo "Cleaning up source files to remove comments, ip addresses, etc."

# stevenblack.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: get actual host entries which are being redirected, the line starts with "0.0.0.0"
# 3: don't include any refernces to hosts that end in ".0" since those are interface addresses
# 4: remove address prefixes so that we are left with just the domain name
# 5: save output file in working directory with filename
grep -v "#" sources/stevenblack.txt | grep "0.0.0.0" | grep -v ".0$" | awk '{print $2}' > working/stevenblack.txt

# malwaredomains.txt
# this file is just a list of domains with nothing else, so it's perfect as-is
# copy the file to the working directory with the same name
cp source/malwaredomains.txt working/malwaredomains.txt

# sysctl.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: remove address prefixes so that we are left with just the domain name
# 3: save output file in working directory with same filename
grep -v "#" sources/sysctl.txt | awk '{print $2}' > working/sysctl.txt

# abuse-ch.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: save output file in working directory with same filename
grep -v "#" sources/abuse-ch.txt > working/abuse-ch.txt

# disconnect-simple_tracking.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: save output file in working directory with same filename
grep -v "#" sources/disconnect-simple_tracking.txt > working/disconnect-simple_tracking.txt

# disconnect-simple_ad.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: save output file in working directory with same filename
grep -v "#" sources/disconnect-simple_ad.txt > working/disconnect-simple_ad.txt

# hostsfile-adservers.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: exclude any lines ending in 'localhost' since those are interface addresses
# 3: remove address prefixes so that we are left with just the domain name
# 4: save output file in working directory with filename
grep -v "#" sources/hostsfile-adservers.txt | grep -v "localhost$" | awk '{print $2}' > working/hostsfile-adservers.txt


## Combine all files, sort, remove duplicates and create a 'master-list'
echo "Combining files..."
cat working/* > working/combined_entries.txt

echo "Removing duplicates, blank lines and sorting for readability..."
# 1: sort file in ascending order (default) so duplicates are listed consecutively
# 2: remove adjacent duplicate entries (that's why we sorted in 1 above)
# 3: remove any blank lines
# 4: save output file
sort working/combined_entries.txt | uniq | sed '/^$/d' > sorted_entries.txt

echo "Adding proper address prefix..."
# Add address as defined in $dummyaddr before each host entry
# double-quotes used so the variable's value is expanded into the statement
sed "s/^/$dummyaddr /" sorted_entries.txt > "$listpath/adblock.dnsmasq"

echo "...adblock list updated"