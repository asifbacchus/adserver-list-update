#!/bin/bash

### Script to download addresses from ad-server lists and modify them for use
### in a DNSMASQ host file which will redirect those addresses to an IPv4 & IPv6
### address as specified in $ipv4addr and $ipv6addr.


## Variables used in this script
# ipv4addr and ipv6addr: suggest using the unspecified (ipv4addr="0.0.0.0",
# ipv6addr="::") address for just a 'blackhole'. If you want to forward to a
# specific server (such as your webserver, etc.) then use that address in these
# variables. If either ipv4addr or ipv6addr is blank, they will NOT be included
# in the final address list.  Variables can be made blank by either setting them
# equal to "" or having nothing after the equal sign.  Please note: blank and
# the undefined parameter (0.0.0.0 or ::) are NOT the same!
ipv4addr="0.0.0.0"
ipv6addr="::"
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

# Test whether IPv4 redirect addresses are needed based on whether the
# $ipv4addr variable is null.
if [ "$ipv4addr" ]
then
    sed 's/\r//' $locationWorkingfiles/combined_entries.txt | sort -u | sed '/^$/d' > $locationWorkingfiles/sorted_entries4.txt
    echo "Adding ipv4:$ipv4addr address prefix..."
    # Add address defined in $ipv4addr before each host entry in
    # sorted_entries4.txt. Double-quotes mean the variable's value is used.
    sed "s/^/$ipv4addr /" $locationWorkingfiles/sorted_entries4.txt > $locationWorkingfiles/ipv4list.txt
    echo "...done"
else
    echo "ipv4addr was not specified (null) so the adblock list will not"
    echo "have an IP4 redirect."
    # create a zero length file for debugging and to avoid the error message
    # (which can be safely disregarded anyways) in the concatenation process.
    touch ipv4list.txt
fi

# Test whether IPv6 redirect addresses are needed based on whether the
# $ipv6addr variable is null.
if [ "$ipv6addr" ]
then
    sed 's/\r//' $locationWorkingfiles/combined_entries.txt | sort -u | sed '/^$/d' > $locationWorkingfiles/sorted_entries6.txt
    echo "Adding ipv6:$ipv6addr address prefix..."
    # Add address defined in $ipv6addr before each host entry in
    # sorted_entries6.txt. Double-quotes mean the variable's value is used.
    sed "s/^/$ipv6addr /" $locationWorkingfiles/sorted_entries6.txt > $locationWorkingfiles/ipv6list.txt
    echo "...done"
else
    echo "ipv6addr was not specified (null) so the adblock list will not"
    echo "have an IP6 redirect."
    # create a zero length file for debugging and to avoid the error message
    # (which can be safely disregarded anyways) in the concatenation process.
    touch ipv6list.txt
fi

# The previous step created zero-length files if $ipv4addr or $ipv6addr was
# null. This avoids cat throwing an error here.  However, even if the error was
# thrown, the concatenation process still works anyways, so the zero-length
# files are only useful when debugging (or playing with) this script just to
# have a record that one of the variables was indeed null.
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