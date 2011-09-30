# cpMigrator: An automated migration script for cPanel migrations #

_Info: This script is currently under development, so it is not quite ready for prime time. Updates will be made here as it progresses._

## Current or Intended Abilities

### Full Migration

This is the first, and primary function of the script; to handle full migrations with root SSH access. As of right now, it does or will do the following.

1. Asks for and stores IP addresses, ports, and passwords for both the source and destination servers.

2. Determines where the script is being run from. (source, destination, workstation, or other) Once this determination is made, the script will configure itself to run from that location.

3. SSH keys are automatically setup.

    * Steps 4-14 are optional, so the migration can be run in a variety of configuration, as is often necessary. 

4. Displays basic information about both server environments.

5. Does preliminary checks for existing cpanel accounts and domains on the destination server (if found, looks for conflicts), available IPs (makes sure there are enough for dedicated IPs on source server), and nameservers. This information is displayed, and the tech can choose to continue once changes are made, or override and continue anyways.

6. Lowers TTLs

7. Checks for use of remote nameservers.

8. Updates rsync.

9. Matches Easy Apache configurations, and copies over cPanel packages and features.

10. Packages accounts.

11. Copies packages accounts to the destination server.

12. Checks to verify the Easy Apache has finished running on the destination server, and then restores the accounts.

13. Rsyncs the home directories from the source server to the destination server.

14. Prepares the destination server for testing by providing links the customer can access for hosts file modification and testing.

_After this point it will wait until it is prompted to complete the final sync, which does a standard final sync, and can setup DNS to forward from the source server to the destination server._

### Partial Migration

This will be mostly the same as the full migration, only it will handle a specific list of users or domains. Also, it will be expecting to see accounts and domains setup on the source server, and set the default options accordingly.

### Single Migration

This will migrate a single cPanel account, but will have additional options available if they are needed.

### Resume Migration

This will resume a migration that has been stopped. It is planned that a migration can be resumed from any location as long as you copy the files. (ie You complete the initial migration from the source server, and then run the final sync from the destination server) 