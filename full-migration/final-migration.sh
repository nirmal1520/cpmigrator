#!/bin/bash

# Includes
source includes.sh

# Set destination server variables
destinationIP=$(cat $path/full-migration/destination-files/destinationIP)
destinationPASS=$(cat $path/full-migration/destination-files/destinationPASS)
destinationPORT=$(cat $path/full-migration/destination-files/destinationPORT)
destinationUSER=$(cat $path/full-migration/destination-files/destinationUSER)

disable_services (){
	# Turn off services on source server
	menu_prep
	export text1="Temporarily disabling services on source server ..."
	submenu
	/usr/local/cpanel/bin/tailwatchd --disable=Cpanel::TailWatch::ChkServd
	/etc/init.d/httpd stop
	/etc/init.d/exim stop
	/etc/init.d/cpanel stop
}

databases () {
	# Will need to have an option to handle users that didn't originally copy (caught by the 'preliminary' function)
	# Dump the databases
	menu_prep
	export text1="Dumping the databases to /home/dbdumps ..."
	submenu
	test -d /home/dbdumps && mv /home/dbdumps{,.`date +%F`.bak}
	mkdir /home/dbdumps
	for db in `mysql -Ns -e "show databases"|egrep -v "test|information_schema|cphulkd|eximstats|horde|leechprotect|modsec|mysql|roundcube|^test$"`;do echo $db;mysqldump $db > /home/dbdumps/$db.sql;done
	# Copy the databases
	menu_prep
	export text1="Copying the database dumps to the destination server ..."
	submenu
	ssh -Tq $destinationUSER@$destinationIP -p$destinationPORT /bin/bash <<EOF
test -d /home/dbdumps && mv /home/dbdumps{,.`date +%F`.bak}
EOF
	rsync -avHP -e "ssh -p$destinationPORT" /home/dbdumps root@$destinationIP:/home/
}

restore_dbs () {
        menu_prep
        export text1="Starting a restore of the databases ..."
        submenu
	# This needs to go into a script that gets copied over and run in the screen session
        ssh -Tq $destinationUSER@$destinationIP -p$destinationPORT /bin/bash <<EOF
test -d /home/prefinalsyncdbs && mv /home/prefinalsyncdbs{,.`date +%F`.bak}
mkdir /home/prefinalsyncdbs
screen -S "restore_dbs" -d -m `cd /home/dbdumps;for each in *.sql;do echo ${each%.*};mysqldump ${each%.*} > /home/prefinalsyncdbs/$each;mysql ${each%.*} < /home/dbdumps/$each;done`
exit
EOF
}

homedirs () {
	# This needs to either split into a separate process, or run in another screen session, so the databases can be restored while this is running
	menu_prep
	export text1="Rsyncing the homedirs ..."
	submenu
	for each in `\ls -A /var/cpanel/users`;do rsync -avHP -e 'ssh -pdestinationPORT' /home/$each/ root@$destinationIP:/home/$each/ --update;done
	rsync -avHP -e 'ssh -p$destinationPORT' /usr/local/cpanel/3rdparty/mailman root@$destinationIP:/usr/local/cpanel/3rdparty/
	rsync -avHP -e 'ssh -pdestinationPORT' /var/spool root@$destinationIP:/var/
}

db_check () {
        menu_prep
        export text1="Checking to see if databases have finished restoring ..."
        submenu
        rsync -avHl -e "ssh -p $destinationPORT" $path/full-migration/scripts/db-watcher.sh $destinationUSER@$destinationIP:/home/temp/ --progress
        ssh -Tq $destinationUSER@$destinationIP -p$destinationPORT /bin/bash <<EOF
/home/temp/db-watcher.sh
exit
EOF
	echo
	echo "Databases restored."
	sleep 2
}

forward () {
	menu_prep
	export text1="Setting up DNS forwarding ..."
	submenu
	/etc/init.d/named stop
	mv /var/named{,.`date +%H%M`.bak}
	mkdir /var/named
	chown root:named /var/named
	rsync -avHP -e 'ssh -p$destinationPORT' root@$destinationIP:/var/named/ /var/named/
	/etc/init.d/named start
	rndc reload
}

remove_dumps () {
	menu_prep
	export text1="Removing Mysql dumps ..."
	submenu
	rm -f /home/dbdumps/*.sql
	rmdir /home/dbdumps
ssh -Tq $destinationUSER@$destinationIP -p$destinationPORT /bin/bash <<EOF
rm -f /home/dbdumps/*.sql
rmdir /home/dbdumps
EOF
}

restart_services () {
	menu_prep
	export text1="Restarting services ..."
	submenu
	/etc/init.d/cpanel start
	/etc/init.d/exim start
	/etc/init.d/httpd start
	/usr/local/cpanel/bin/tailwatchd --enable=Cpanel::TailWatch::ChkServd
}

source ~/.bash_profile 2>&1 >/dev/null
clear
# Options menu using dialog (ncurses utility for bash)
cmd=(dialog --separate-output --checklist "Select Final Sync Options:" 22 76 16)
options=(1 "Disable source server services" on    # any option can be set to default to "on"
         2 "Dump and copy databases" on
	 3 "Restore databases" on
         4 "Rsync home directories" on
	 5 "Verify databases have finished restoring" on
         6 "Forward DNS from source server to destination server" on
         7 "Remove database dumps" on
         8 "Restart source server services" on)
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
for choice in $choices
do
    case $choice in
        1)
            disable_services
            ;;
        2)
            databases
            ;;
        3)
            restore_dbs
            ;;
	4)
	    homedirs
	    ;;
	5)
	    db_check
	    ;;
        6)
            forward
            ;;
        7)
            remove_dumps
            ;;
        8)
            restart_services
            ;;
    esac
done

