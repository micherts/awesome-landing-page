#Environment
$App = 'hosposure.com.au' #All lowercase
$WL = "$Home\Documents\Code\awesome-landing-page"
Set-Location $WL

Set-AWSCredential -ProfileName AWSmicherts
$Region = 'ap-southeast-2'
$RegionS3R53ZoneID = "Z1WCIGYICN2BYD" #ap-southeast-2 S3 Bucket R53 Hosted Zone ID https://docs.aws.amazon.com/general/latest/gr/s3.html#s3_website_region_endpoints
Import-Module AWS.Tools.Route53

#Domain Set Up Process
#Route53 - Register domain names.
#S3 - Create bucket with public access
#Remove-S3Bucket -Region $Region -BucketName $App -Force -Verbose
New-S3Bucket -Region $Region -BucketName $App -CannedACLName public-read
Write-S3BucketWebsite -BucketName $App -WebsiteConfiguration_IndexDocumentSuffix index.html -WebsiteConfiguration_ErrorDocument error.html
$Policy = [PSCustomObject]@{Version = "2012-10-17"; Statement = [PSCustomObject]@{Sid = "PublicReadGetObject"; Effect = "Allow"; Principal = "*"; Action = @("s3:GetObject"); Resource = @("arn:aws:s3:::$App/*") } }
Write-S3BucketPolicy -BucketName $App -Policy ($Policy | ConvertTo-Json)

#S3 - Copy local files to S3
#Get-S3Object -BucketName $App | Remove-S3Object -Verbose -Force
$Files = Get-ChildItem | Where-Object { $_.Name -ne 'manage.ps1' }
#$Files = Get-ChildItem | Where-Object {$_.Name -eq 'index.html'}
ForEach ($File in $Files) {
  $FileName = [System.IO.Path]::GetFileName($File)
  If ($File.Mode -match "d") {
    # $Prefix = "$($File.FullName.ToString().replace($WL,''))\"
    $Prefix = "$($File.FullName.ToString().replace($WL,''))"
    Write-S3Object -BucketName $App -Folder $File.Name -KeyPrefix $Prefix -Recurse -Verbose -Force 
  }
  else {
    # Write-S3Object -BucketName $App -Key $FileName -File $File -Verbose -Force 
    Write-S3Object -BucketName $App -Key $FileName -File $File.Name -Verbose -Force 
  }
}

#Certificate Manager - Create new certificate for domain and *.domain.
#Certificate Manager - Validate domains by 'Create records in Route 53' option.
#CloudFront - Create new distribution for S3 bucket with alternate domain names domain and www.domain, default root object index.html, behaviour redirect http to https.
#Route53 - Add hosted zone A record to route to CloudFront distribution.
$R53HostedZoneId = (Get-R53HostedZones | Where { $_.Name -eq "$App." }).Id.split('/')[2]
$Record = New-Object Amazon.Route53.Model.Change
$Record.Action = "CREATE"
$Record.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$Record.ResourceRecordSet.Name = "$App."
$Record.ResourceRecordSet.Type = "A"
<# These lines need updating
 $Record.ResourceRecordSet.AliasTarget = New-Object Amazon.Route53.Model.AliasTarget
 $Record.ResourceRecordSet.AliasTarget.HostedZoneId = $RegionS3R53ZoneID
 $Record.ResourceRecordSet.AliasTarget.DNSName = "s3-website-$Region.amazonaws.com."
 $Record.ResourceRecordSet.AliasTarget.EvaluateTargetHealth = $true #>
Edit-R53ResourceRecordSet -HostedZoneId $R53HostedZoneId -ChangeBatch_Comment "Add routing to CloudFront" -ChangeBatch_Change $Record
#Route53 - Add hosted zone CNAME record to route www subdomain to apex.
$Record = New-Object Amazon.Route53.Model.Change
$Record.Action = "CREATE"
$Record.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$Record.ResourceRecordSet.Name = "www.$App."
$Record.ResourceRecordSet.Type = "CNAME"
$Record.ResourceRecordSet.ResourceRecords = (New-Object Amazon.Route53.Model.ResourceRecord)
$Record.ResourceRecordSet.ResourceRecords[0].Value = "$App."
$Record.ResourceRecordSet.TTL = 500
Edit-R53ResourceRecordSet -HostedZoneId $R53HostedZoneId -ChangeBatch_Comment "Add routing from www subdomain to apex" -ChangeBatch_Change $Record
#Route secondary domain to main domain. Only works for http, not https. Secondary domain https routing is not possible on AWS.
$App2 = 'hosposure.com'
$R53HostedZoneId2 = (Get-R53HostedZones | Where { $_.Name -eq "$App2." }).Id.split('/')[2]
#S3 - Create bucket for redirect
New-S3Bucket -Region $Region -BucketName $App2
Write-S3BucketWebsite -BucketName $App2 -RedirectAllRequestsTo_HostName $App
#Route53 - Add hosted zone A record to route to S3.
$Record = New-Object Amazon.Route53.Model.Change
$Record.Action = "CREATE"
$Record.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$Record.ResourceRecordSet.Name = "$App2."
$Record.ResourceRecordSet.Type = "A"
$Record.ResourceRecordSet.AliasTarget = New-Object Amazon.Route53.Model.AliasTarget
$Record.ResourceRecordSet.AliasTarget.HostedZoneId = $RegionS3R53ZoneID
$Record.ResourceRecordSet.AliasTarget.DNSName = "s3-website-$Region.amazonaws.com."
$Record.ResourceRecordSet.AliasTarget.EvaluateTargetHealth = $false
Edit-R53ResourceRecordSet -HostedZoneId $R53HostedZoneId2 -ChangeBatch_Comment "Route secondary domain to main domain" -ChangeBatch_Change $Record
#Create redirects for subdomains
ForEach ($Sub in ("app", "www")) {
  #S3 - Create bucket for redirect
  New-S3Bucket -Region $Region -BucketName "$Sub.$App2"
  Write-S3BucketWebsite -BucketName "$Sub.$App2" -RedirectAllRequestsTo_HostName "$Sub.$App"
  #Route53 - Add hosted zone CNAME record to route subdomain to apex.
  $Record = New-Object Amazon.Route53.Model.Change
  $Record.Action = "CREATE"
  $Record.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
  $Record.ResourceRecordSet.Name = "$Sub.$App2."
  $Record.ResourceRecordSet.Type = "CNAME"
  $Record.ResourceRecordSet.ResourceRecords = (New-Object Amazon.Route53.Model.ResourceRecord)
  $Record.ResourceRecordSet.ResourceRecords[0].Value = "$App2."
  $Record.ResourceRecordSet.TTL = 500
  Edit-R53ResourceRecordSet -HostedZoneId $R53HostedZoneId2 -ChangeBatch_Comment "Add routing from $Sub subdomain to apex" -ChangeBatch_Change $Record
}



#Read S3
Get-S3Object -Region $Region -BucketName $App | ft

#Copy S3 files to local
$Files = Get-S3Object -Region $Region -BucketName $App
ForEach ($File in $Files) {
  Read-S3Object -BucketName $App -Key $File.Key -File $File.Key -Verbose
}

#Read R53 Record Sets
$R53HostedZoneId = (Get-R53HostedZones | Where { $_.Name -eq "$App." }).Id.split('/')[2]
$Records = (Get-R53ResourceRecordSet -HostedZoneId $R53HostedZoneId).ResourceRecordSets
$Records | ft

#Create R53 Record to route apex domain to S3 bucket

# Initialise git
git init
git add .
git commit -m "first commit"
git branch -M main
# Manually create new repo on Github
git remote add origin git@github.com:micherts/hosposure.com.au.git
git push -u origin main

# Run local webserver
Install-Module webserver
Import-Module webserver
Start-Webserver
Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe" "http://localhost:8080"

# Update git **Note git workflow syncs to S3
git add .
git commit -m "added assets\email\account-verified.png"
git push origin master

#Clone Git repo
git clone git@github.com:micherts/awesome-landing-page.git
