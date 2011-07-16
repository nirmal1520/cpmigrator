#!/bin/bash
# This script is initiated from init.sh
# This is the second script to run for a full migration, right after migration-details.sh
clear

# Set Path
path=`pwd`

# Clear potentially full flat file
[ -f $path/full-migration/workstation-check/workstation ] && cat /dev/null > $path/full-migration/workstation-check/workstation

# Inform user of current status
echo "Checking Server Locations ..."
sleep 2

# Set Variables
ip=$([ -f /var/cpanel/mainip ] && cat /var/cpanel/mainip)
sourceip=$(cat $path/full-migration/source-files/sourceIP)
destinationip=$(cat $path/full-migration/destination-files/destinationIP) 

# Checking current server IP against IPs provided in migration-details.sh

# Checks against source server IP
if [[ $ip == $sourceip ]]; then
	echo "This is the source server"
	echo "Configuring migration for control from source server ..."
	sleep 2 
	cat /dev/null > $path/full-migration/location
	echo "source" > $path/full-migration/location
fi

# Checks against destination server IP
if [[ $ip == $destinationip ]]; then
	echo "This is the destination server" 
	echo "Configuring migration for control from destination server ..."
	sleep 2
	cat /dev/null > $path/full-migration/location
	echo "destination" > $path/full-migration/location
fi

# If it does not match source or destination IPs, but server is running cpanel,
# configures migration to be run from a third-party server
if [[ $ip != $sourceip ]] && [[ $ip != $destinationip ]] && [[ -n $ip ]]; then
        echo "ATTENTION: This is neither the source or destination servers,"
        echo "but is running cPanel."
        echo ""
        echo "Configuring migration for control from third party server..."
        echo
	cat /dev/null > $path/full-migration/location
	echo "thirdparty" > $path/full-migration/location
	sleep 2
fi

# If it does not match source or destination IPs, and is not running Cpanel,
# asks admin if script is being run from a workstation.
if [[ $ip != $sourceip ]] && [[ $ip != $destinationip ]] && [[ -z $ip ]]; then
	echo "ATTENTION: This is neither the source or destination servers,"
	echo "and does not appear to be running cPanel."
	echo ""
	echo "Is this a workstation?"
	echo
	if [ -z $workstation ]; then
                echo -n "Please type yes or no: "
                read workstation
        fi
	# Is a workstation. Determines workstation IP
	if [[ $workstation == yes ]]; then
		echo
		bash $path/full-migration/workstation-check/workstation-check.sh
		cat /dev/null $path/full-migration/location
		echo "workstation" > $path/full-migration/location
		echo
		echo "Configuring migration to run from workstation..."
		sleep 2
		echo
		# Will likely need different configs for different linux flavors (main ones)
		# Also will need to check for necessary dependencies
	fi
	# Not a workstation. Not compatible. Exits script
	if [[ $workstation == no ]]; then
		# Use this to lock out the migration from running on this setup.
		touch $path/full-migration/workstation-check/workstation
                echo "0" > $path/full-migration/workstation-check/workstation
		echo
		echo "This migration script has not been tested with this setup."
		echo "Please try running this from your workstation, the source server,"
		echo "the destination server, or another server running cPanel."
		echo
		echo "Script is now exiting..."
		sleep 2
		exit 0
	fi
	# Not an available option 
	if [[ $workstation != yes ]] && [[ $workstation != no ]]; then
		echo 
		echo "Not a valid option!"
		echo
		echo "Script is now exiting..."
		sleep 2
		exit 0
	fi	
fi

# Script End. Returns to init.sh