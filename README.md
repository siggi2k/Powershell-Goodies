# createADUSer
Makes user creation a little bit easier

This script adds a user to the active directory and places the user in the correct ou
1. Gather information needed about user
2. Create the user if the username is available
3. sets the user principal name according to what domain user is part of
4. The user is added to base group and group belonging to the users department
5. If the user needs an office 365 subscription the user is added to the OU that is synchronized to the tenant
6. If user needs office 365 subscription it is given a license in the Office 365 tenant

# manageDomainUsers
Something to make Domain User Management a bit easier

This script takes a few steps to make life managing an active directory a bit easier.
1. Disables all users that have been inactive for 30 days or more (Excludes users from group "Extended Vacation")
2. Moves all disabled users to a new OU specifically for disabled users and marks them as expired as of time of running
3. Deletes home and profile folders belonging to the users 30 days after expiry
4. Deletes the User from the active directory 30 days after expiry
5. Sends a push notification through Pushbullet on automatic archival and deletion

This is all logged in 2 seperate text files.

# checkSSLCert
Alerts if a website's SSL Certificate will expire in set number of days

1. Checks when SSL Certificates for websites in array expire
2. Sends a push notification through Pushbullet when a SSL Certificate will expire within set amount of days (default 30)