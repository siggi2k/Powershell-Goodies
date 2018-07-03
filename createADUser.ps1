Import-Module activedirectory
Import-Module MsOnline
Import-Module ADSync

# Get information to create the user
$firstName = Read-Host -Prompt 'Users First Name'
$surName = Read-Host -Prompt 'Users Last Name'
$fullName = $FirstName + ' ' + $Surname
$username = Read-Host -Prompt 'Login name, f.e. "john"'
$upname = $username + '@' + $activeDomain
$path = ''

# Check if the username is available
try {
    get-aduser $username -ErrorAction SilentlyContinue
    Write-Host "`n Username is not available `n"
    return
}
catch {
    Write-Host "`n user $username will be created`n"
}

# Set wich part of the company the user is part of
Write-Host "What will be the users active domain? `n 1. domainone.com `n 2. domaintwo.com `n"
do {
    $activeDomain = Switch(Read-Host) {
        1 {"domainone.com"}
        2 {"domaintwo.com"}
    } 
} until (($activeDomain -eq "domainone.com") -or ($activeDomain -eq "domaintwo.com"))

$upname = $username + '@' + $activeDomain

Write-Host "Does the user need an Office365 Subscription?"
do {
    switch(Read-Host "(Y/N)") {
        Y {$path = 'OU=Office,OU=Staff,DC=mydomain,DC=local'}
        N {$path = 'OU=Staff,DC=mydomain,DC=local'}
    }
} until (($path -eq 'OU=Office,OU=Staff,DC=mydomain,DC=local') -or ($path -eq 'OU=Staff,DC=mydomain,DC=local'))

do {
    $userGroup = switch(Read-Host "What group does the user belong to? `n 1. Finance `n 2. Sales `n 3. Marketing `n 4. Hotels `n 5. Operations `n "){
        1 {"Finance"}
        2 {"Sales"}
        3 {"Marketing"}
        4 {"Hotels"}
        5 {"Operations"}
        default {"Choose a number between 1 and 5"}
    }
} until (($userGroup -eq "Finance") -or ($userGroup -eq "Sales") -or ($userGroup -eq "Marketing") -or ($userGroup -eq "Hotels") -or ($usergroup -eq "Operations"))

# Create the user in the Active Directory
try {
    New-ADUser -Name "$fullName" `
        -GivenName $firstName `
        -Surname $surName `
        -DisplayName "$fullName" `
        -SamAccountName $username `
        -Country 'IS' `
        -Path $path `
        -UserPrincipalName $upname `
        -HomeDrive "H:" `
        -HomeDirectory "\\Fileshare\home$\$username" `
        -ProfilePath "\\Fileshare\profile$\$username" `
        -AccountPassword(ConvertTo-SecureString -AsPlainText "MySecureDefaultPassword" -Force) `
        -Enabled $true `
        -ChangePasswordAtLogon $true
    }
    catch {
    Write-Host "User not created"
    write-host $_.Exception.Message
    }

Write-Host $fullName - $upname - $path Created as AD User

# Set the user as a member of the base group
try {
    Add-ADGroupMember -Identity everyone $username
    Write-Host $upname added to everyone
    }
    catch {
    Write-Host failed adding $upname to everyone
    }

#Þessar 5 Groups eru fyrir þær deildir sem eru á skrifstofunni, allir notendur þurfa að vera í einni þeirra
do {
    switch ($userGroup) {
        'Finance' {Add-ADGroupMember -Identity Fjárreiðudeild -Members $username; Write-Host "User added to Finance"}
        'Sales' {Add-ADGroupMember -Identity Söludeild -Members $username; Write-Host "User added to Sales"}
        'Marketing' {Add-ADGroupMember -Identity Markaðsdeild -Members $username; Write-Host "User added to Marketing"}
        'Hotels' {Add-ADGroupMember -Identity Markaðsdeild -Members $username; Write-Host "User added to Hotels"}
        'Operations' {Add-ADGroupMember -Identity Operations -Members $username; Write-Host "User added to Operations"}
    } 
} until (($userGroup -eq "Finance") -or ($userGroup -eq "Sales") -or ($userGroup -eq "Marketing") -or ($userGroup -eq "Hotels") -or ($userGroup -eq "Operations"))

## Adds the user to the group that is synchronized with Office 365 if applicable ##
if ($path -eq "OU=Office,OU=Staff,DC=mydomain,DC=local"){
    try {
        Start-ADSyncSyncCycle -PolicyType Delta; Write-Host "AD Sync Successful"
    }
    Catch {
        Write-Host "ADSyncCycle Failed..."
    }

    # Connect to the Office 365 Tenant as the global admin
    $UserCredential = Get-Credential admin@mydomain.onmicrosoft.com
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
    Import-PSSession $Session

    #$msolcred = Get-Credential
    try {
        Connect-MsolService -Credential $UserCredential
        Write-Host "Authentication success"
    }
    catch{
        Write-Host "Authentication failed.."
    }

    #Wait a bit while the user is replicated to Office 365
    Start-Sleep -s 30

    if($path -eq 'OU=Office,OU=Staff,DC=mydomain,DC=local') {
        try {
            Set-MsolUser -UserPrincipalName $upname -UsageLocation "IS"
            Set-MsolUserLicense -UserPrincipalName $upname -AddLicenses mydomain:O365_BUSINESS
            Write-Host "Adding subscription to user $upname "
        }
        Catch {
            Write-Host "No subscription added to user"
        }
    }
    Start-Sleep -s 5
}