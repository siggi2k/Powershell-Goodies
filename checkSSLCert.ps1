## This script checks the expiration date of SSL Certificates for websites.

# Put in the Websites you want to monitor the Certificates
$urls = 'contoso.com',
        'google.com',
        'example.com'

$date = [datetime]::Now

# Set the notification period for number of days until expiry
$daysToExpiration = 30

### Pushbullet Sanitized API settings
$PushURL = "https://api.pushbullet.com/v2/pushes"
$APIKey = "----"
$channel_tag = "----"
$Cred = New-Object System.Management.Automation.PSCredential ($APIKey, (ConvertTo-SecureString $APIKey -AsPlainText -Force))

# Create the array
$objects = @()

foreach ($url in $urls){
    # Write to output what Website is being checked
    Write-Host "Checking $url"
    try{
        $cert = [System.Net.ServicePointManager]::FindServicePoint((Invoke-WebRequest $url).BaseResponse.ResponseUri).Certificate
    }
    catch [System.Net.WebException]{
        # Set the response to $null if no valid SSL Certificate is found
        $cert = ''
    }
    if ($cert -eq $null) {
        Write-Host "$url does not have a valid SSL Certificate"
    } else {
        # Get the expiration date
        $expiry = [datetime]::Parse($cert.GetExpirationDateString())

        # Get the Time Span between today and expiration date
        $timespan = New-TimeSpan $date $expiry

        # Get the number of days from the Time Span
        $days = $timespan.Days
        
        # Get the properties into a variable
        $properties = @{URL=$url;Expiry=$expiry;"Days to Expiry"=$days}

        # Create an object with the properties
        $object = New-Object PSObject -Property $properties

        # Add the objects to the array
        $objects += $object
    }

}

# List the websites that have less-or-equal to set days to expiry
$almostExpired = $objects | Where-Object "Days to expiry" -le $daysToExpiration | SELECT URL, Expiry, "Days to expiry"

foreach ($domain in $almostExpired) {
    #Write-Host $domain
    $domainName = $domain | Select -ExpandProperty URL
    $domainExpiry = $domain | Select -ExpandProperty "Days to Expiry"
    $domainExpiryDate = $domain | Select -ExpandProperty Expiry
    $ReadbleExpiryDate = $domainExpiryDate.ToString('dd/MMM/yyyy')
    #Write-Host "$domainName will expire in $domainExpiry days ($ReadbleExpiryDate)"

    $body = @{
        type = "note"
        title = "$domainName SSL Warning"
        body = "SSL Certificate for $domainName will expire in $domainExpiry days ($ReadbleExpiryDate)"
        channel_tag = $channel_tag
    }

    #Send a Push Notification to the channel
    Invoke-WebRequest -Uri $PushURL -Credential $cred -Method Post -Body $body 
}