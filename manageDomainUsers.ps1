# Finds all users that have been inactive for 30 days or more
$InactiveUsers = Search-ADAccount -AccountInactive -Timespan '30' -usersonly -SearchBase "OU=Staff,DC=mydomain,DC=local"

# Exclude staff on vacation longer than the expiration time
foreach ($item in $InactiveUsers) {
	get-aduser $item -Properties MemberOf | 
		Where-Object {!($_.MemberOf -like "*CN=Extended Vacation*")} | 
		ForEach-Object { 
			Disable-ADAccount $_.ObjectGuid

			# Logging that the user was Disabled to a file
			Add-Content X:\Logs\ActiveDirectory\DisabledUsersMoved.txt "$(get-date) - $item was disabled automatically due to inactivity"
		}
}

# Move disabled users to Dead users folder
$DisabledUsers = Get-Aduser -Filter {(Enabled -eq 'false')} -SearchBase "OU=Staff,DC=mydomain,DC=local"
foreach ($item in $DisabledUsers) {
	# Get today's date
	$today = Get-Date -Format g

	# Flag the user as expired today, so it can be deleted after 30 days
	Set-ADAccountExpiration $item $today
	
	# Moveing the user to the Dead User OU
	Move-ADObject -Identity $item -TargetPath "OU=Deactivated Users,DC=mydomain,DC=local"

	# Logging that the user was moved to a file
	Add-Content X:\Logs\ActiveDirectory\DisabledUsersMoved.txt "$(get-date) - $item was moved to Deactivated Users"

}

# Search for users that fit the parameters and put their Profile folder location into the array
$Profilefolderlocation = Search-ADAccount -AccountExpired | Where-Object {$_.AccountExpirationDate -lt ((Get-Date).AddDays(-30))} |
	ForEach-Object {Get-ADUser $_.ObjectGuid -Properties profilePath} |
	Select-Object -ExpandProperty profilePath

# Cycle through the users and delete the profile folders belonging to the user
foreach ($item in $Profilefolderlocation) {
	$Folders = Get-Item "$item.v*"

	# Cycle through all folders if there are multiple (user.v2|user.v3 etc)
	foreach ($Folder in $Folders) {
		# Take Ownership of the Folder
		takeown /R /A /F $Folder /D N

		# Give group Administrators permission to delete folder
		icacls $Folder /grant Administrators:F /T /C

		# Deletes the folder
		Remove-Item -Path $Folder -Recurse -Force

		# Log deletion time
		Add-Content 'X:\Logs\ActiveDirectory\ExpiredUsersDeleted.txt' "$(get-date) - Profile Folder $Folder was Deleted"
	}
}

# Gets the home folder of the users that expired more than 30 days ago
$Homefolderlocation = Search-ADAccount -AccountExpired | Where-Object {$_.AccountExpirationDate -lt ((Get-Date).AddDays(-30))} |
	ForEach-Object {Get-ADUser $_.ObjectGuid -Properties homeDirectory} |
	Select-Object -ExpandProperty homeDirectory

# Cycle through the users and delete the home folder belonging to the user
foreach ($item in $Homefolderlocation) {

	# Checks if the home folder exists and if it does cycles through them
	if(Test-Path $item) {
		$Folders = Get-Item "$item"

		# Cycles through the folders that exist and deletes them
		foreach ($Folder in $Folders) {
			write-host $Folder
			# Take Ownership of the Profile Folder
			takeown /R /A /F $Folder /D N

			# Give group Administrators permission to delete folder
			icacls $Folder /grant Administrators:F /T /C

			# Deletes the folder
			Remove-Item -Path $Folder -Recurse -Force

			# Log deletion time
			Add-Content 'X:\Logs\ActiveDirectory\ExpiredUsersDeleted.txt' "$(get-date) - Home Folder $Folder was Deleted"
		}
	} else {
	Write-Host "No Folder.. for user $item"
	}
}

# Get a list of all users that expired more than 30 days ago
$ExpiredUsers = Search-ADAccount -AccountExpired | Where-Object {$_.AccountExpirationDate -lt ((Get-Date).AddDays(-30))}

# Delete Users that expired more than 30 days ago
ForEach ($item in $ExpiredUsers) {
	Remove-ADObject -Identity $item -Confirm:$false

	# Log deletion of user from domain
	Add-Content 'X:\Logs\ActiveDirectory\ExpiredUsersDeleted.txt' "Domain User $item was deleted from domain on $(get-date)"
}