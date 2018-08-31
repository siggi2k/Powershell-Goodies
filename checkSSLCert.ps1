## This script checks the expiration date of SSL Certificates for websites.
## To-Do:
## - Email notification when a domain will expire in less than 2(?) weeks
## - Monthly? email with an expiration date for everything, or everything expiring the next (60|90) days?

# Put in the Websites you want to monitor the Certificates
$urls  = 'https://google.com',
         'https://contoso.com',
         'https://example.com'

# Create the array
$objects = @()

foreach ($url in $urls){
    # Write to output what Website is being checked
    Write-Host "Checking $url"
    try{
        $cert = [System.Net.ServicePointManager]::FindServicePoint((Invoke-WebRequest $url).BaseResponse.ResponseUri).Certificate
    }
    catch [System.Net.WebException]{
        $cert = [System.Net.ServicePointManager]::FindServicePoint((Invoke-WebRequest $url -UseDefaultCredentials).BaseResponse.ResponseUri).Certificate
    }

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

# List the websites that have less-or-equal to 90 days to expiry
$objects | Where-Object "Days to expiry" -le "90" | SELECT URL, Expiry, "Days to expiry"