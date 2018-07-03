# manageDomainUsers
Something to make Domain User Management a bit easier

This script takes a few steps to make life managing an active directory a bit easier.
1. Disables all users that have been inactive for 30 days or more (Excludes users from group "Extended Vacation")
2. Moves all disabled users to a new OU specifically for disabled users and marks them as expired as of time of running
3. Deletes home and profile folders belonging to the users 30 days after expiry
4. Deletes the User from the active directory 30 days after expiry

This is all logged in 2 seperate text files.
