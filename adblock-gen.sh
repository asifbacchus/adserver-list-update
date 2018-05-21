#!/bin/bash

### Script to download addresses from ad-server lists and modify them for use
### in a DNSMASQ host file which will redirect those addresses to an IPv4 & IPv6
### address as specified in $ipv4addr and $ipv6addr.


## Variables used in this script
# ipv4addr and ipv6addr: suggest using the unspecified (ipv4addr="0.0.0.0",
# ipv6addr="::") address for just a 'blackhole'. If you want to forward to a
# specific server (such as your webserver, etc.) then use that address in these
# variables. If either ipv4addr or ipv6addr is blank, they will NOT be included
# in the final address list.
ipv4addr="10.0.0.1"
ipv6addr="fd9e:a15:c7a9:f233::1"
# get directory in which this script this is located and use that as the base
# directory for 'sources' and 'working' sub-directories.  This way, path
# problems are avoided when running as a cron job.
dir=$(pwd -P)
locationSourcefiles="$dir/sources"
locationWorkingfiles="$dir/working"
# Edit 'listpath' to suit your installation.  This can be any directory that
# makes sense for your setup.  On most systems, "/etc/dnsmasq.d" makes sense.
# Use a full path here to avoid problems running this script as a cron job.
listpath="$dir/lists"


## Create directories needed for this script
mkdir $locationSourcefiles
mkdir $locationWorkingfiles
mkdir $listpath


## Print to console a script intro what this script is about to do
echo "************************************************************"
echo "* Updating adserver addresses used to generate adblocking  *"
echo "* external hosts file used by DNSMASQ.                     *"
echo "* File paths can be updated in the 'Variables...' section  *"
echo "* of this script file.                                     *"
echo "************************************************************"
echo


## Download source files using wget, rename them and save to 'sources' folder
echo "Downloading ad-block list source files"
wget -t 3 -T 60 -O $locationSourcefiles/stevenblack.txt https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
wget -t 3 -T 60 -O $locationSourcefiles/malwaredomains.txt https://mirror1.malwaredomains.com/files/justdomains
wget -t 3 -T 60 -O $locationSourcefiles/sysctl.txt http://sysctl.org/cameleon/hosts
wget -t 3 -T 60 -O $locationSourcefiles/abuse-ch.txt https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist
wget -t 3 -T 60 -O $locationSourcefiles/disconnect-simple_tracking.txt https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
wget -t 3 -T 60 -O $locationSourcefiles/disconnect-simple_ad.txt https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
wget -t 3 -T 60 -O $locationSourcefiles/hostsfile-adservers.txt https://hosts-file.net/ad_servers.txt

## Cleanup the files (remove comments, errant ip addresses, etc.)
echo
echo "Cleaning up source files to remove comments, ip addresses, etc."

# stevenblack.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: get actual host entries, they start with "0.0.0.0"
# 3: don't include any hosts that end in ".0", they are interface addresses
# 4: remove address prefixes so that we are left with just the domain name
# 5: save output file in $locationWorkingfiles directory with filename
grep -v "#" $locationSourcefiles/stevenblack.txt | grep "0.0.0.0" | grep -v ".0$" | awk '{print $2}' > $locationWorkingfiles/stevenblack.txt

# malwaredomains.txt
# this file is just a list of domains with nothing else, so it's perfect as-is
# copy the file to the $locationWorkingfiles directory with the same name
cp $locationSourcefiles/malwaredomains.txt $locationWorkingfiles/malwaredomains.txt

# sysctl.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: remove address prefixes so that we are left with just the domain name
# 3: save output file in $locationWorkingfiles directory with same filename
grep -v "#" $locationSourcefiles/sysctl.txt | awk '{print $2}' > $locationWorkingfiles/sysctl.txt

# abuse-ch.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: save output file in $locationWorkingfiles directory with same filename
grep -v "#" $locationSourcefiles/abuse-ch.txt > $locationWorkingfiles/abuse-ch.txt

# disconnect-simple_tracking.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: save output file in $locationWorkingfiles directory with same filename
grep -v "#" $locationSourcefiles/disconnect-simple_tracking.txt > $locationWorkingfiles/disconnect-simple_tracking.txt

# disconnect-simple_ad.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: save output file in $locationWorkingfiles directory with same filename
grep -v "#" $locationSourcefiles/disconnect-simple_ad.txt > $locationWorkingfiles/disconnect-simple_ad.txt

# hostsfile-adservers.txt
# 1: exclude any comments as indicated by a hash symbol
# 2: exclude any lines ending in 'localhost' since those are interface addresses
# 3: remove address prefixes so that we are left with just the domain name
# 4: save output file in $locationWorkingfiles directory with filename
grep -v "#" $locationSourcefiles/hostsfile-adservers.txt | grep -v "localhost$" | awk '{print $2}' > $locationWorkingfiles/hostsfile-adservers.txt


## Combine all files, sort, remove duplicates and create a 'master-list'
echo
echo "Combining files..."
cat $locationWorkingfiles/* > $locationWorkingfiles/combined_entries.txt

echo "Removing duplicates, blank lines and sorting for readability..."
# 1: normalize end-of-line markers so duplicates are flagged properly
# 2: sort file in ascending order (default) so duplicates are listed
#      consecutively, -u option removes duplicates
# 3: remove any blank lines
# 4: save output file
sed 's/\r//' $locationWorkingfiles/combined_entries.txt | sort -u | sed '/^$/d' > $locationWorkingfiles/sorted_entries.txt
# copy file to there's one copy for ipv4 and one for ipv6
cp $locationWorkingfiles/sorted_entries.txt $locationWorkingfiles/sorted_entries6.txt

echo "Adding ipv4:$ipv4addr address prefix..."
# Add address defined in $ipv4addr before each host entry in sorted_entries.txt
# double-quotes used so the variable's value is expanded
sed "s/^/$ipv4addr /" $locationWorkingfiles/sorted_entries.txt > $locationWorkingfiles/ipv4list.txt

echo "Adding ipv6:$ipv6addr address prefix..."
# Add address defined in $ipv6addr before each host entry in sorted_entries6.txt
# double-quotes used to the variable's value is expanded
sed "s/^/$ipv6addr /" $locationWorkingfiles/sorted_entries6.txt > $locationWorkingfiles/ipv6list.txt

echo "Concatenating ipv4 and ipv6 lists and sorting for readability..."
cat $locationWorkingfiles/ipv4list.txt $locationWorkingfiles/ipv6list.txt | sort -t $' ' -k 2,2 > $listpath/adblock.dnsmasq

echo
echo "...adblock list updated..."


## Cleanup created directories and files
echo "...cleaning up"
rm -rf $locationSourcefiles
rm -rf $locationWorkingfiles


## Restart DNSmasq service so it reads the new/updated adblock.dnsmasq file
echo "Restarting DNSMASQ"
systemctl restart dnsmasq.service
echo "...done.  Please consult logs for any errors."


## Exit script gracefully
echo "...done"
exit