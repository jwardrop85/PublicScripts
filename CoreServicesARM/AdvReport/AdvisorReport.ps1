###############################################  SIGN IN WITH RUN AS ACCOUNT ###############################################
$RunAsConnection = Get-AutomationConnection -Name "AzureRunAsConnection"

Connect-AzAccount `
    -ServicePrincipal `
    -TenantId $RunAsConnection.TenantId `
    -ApplicationId $RunAsConnection.ApplicationId `
    -CertificateThumbprint $RunAsConnection.CertificateThumbprint

###############################################  GET SUBSCRIPTION ID ###############################################
$sub = Get-AzContext | select -ExpandProperty Subscription | select -ExpandProperty Name

###############################################  GET ADVISOR SUMMARY TABLE ###############################################
$impactedResource = "Impacted Resource"
$recommendations = Get-AzAdvisorRecommendation | Group-Object -Property Category | Select -property @{n='Category';e={$_.Name}},@{n='Impacted Resource';e={$_.Count}}

Function Get-RecommendationCount ($Category) {

    (Get-AzAdvisorRecommendation | Where Category -EQ $Category | Group-Object -Property RecommendationTypeId).Count

}

$advisorTable = foreach ($Category in $recommendations) {
    
    $tableline = 1 | select Category,Recommendations,$impactedResource

    $tableline.Category = $Category.Category
    $tableline.Recommendations = (Get-RecommendationCount $Category.Category)
    $tableline.$impactedResource = $Category.$impactedResource
   
    $tableline

}

function ToArray
{ begin { $output = @(); } process { $output += $_; } end {return ,$output; } }
if ((($advisorTable.GetType()).Name) -eq "PSCustomObject") { $recommendationTable = $advisorTable | ToArray } else { $recommendationTable = $advisorTable  } 

if (($recommendationTable | Where Category -EQ "Security") -eq $null) { $recommendationTable += New-Object PSObject -Property @{
    Category           = 'Security'
    Recommendations    = '0'
    $impactedResource  = '0'} }
if (($recommendationTable | Where Category -EQ "HighAvailability") -eq $null) { $recommendationTable += New-Object PSObject -Property @{
    Category           = 'HighAvailability'
    Recommendations    = '0'
    $impactedResource  = '0'} }
if (($recommendationTable | Where Category -EQ "Performance") -eq $null) { $recommendationTable += New-Object PSObject -Property @{
    Category           = 'Performance'
    Recommendations    = '0'
    $impactedResource  = '0'} }
if (($recommendationTable | Where Category -EQ "OperationalExcellence") -eq $null) { $recommendationTable += New-Object PSObject -Property @{
    Category           = 'OperationalExcellence'
    Recommendations    = '0'
    $impactedResource  = '0'} }
if (($recommendationTable | Where Category -EQ "Cost") -eq $null) { $recommendationTable += New-Object PSObject -Property @{
    Category           = 'Cost'
    Recommendations    = '0'
    $impactedResource  = '0'} }

$recommendationssummary = ($recommendationTable | ConvertTo-Html) -replace "</body></html>",""

###############################################  GET ADVISOR DETAILED TABLES ###############################################
# $advisorRecommendations = Get-AzAdvisorRecommendation | Select -ExpandProperty ShortDescription -Property Name,Category,Impact,ImpactedField,ImpactedValue | Select -property @{n='Resource Type';e={$_.ImpactedField}},@{n='Resource Name';e={$_.ImpactedValue}},Category,Impact,Problem,Solution | ConvertTo-Html

$recommendationDetails = foreach ($Category in $recommendations) {

    $categoryTable = Get-AzAdvisorRecommendation | Select -ExpandProperty ShortDescription -Property Name,Category,Impact,ImpactedField,ImpactedValue | Select -property @{n='Resource Type';e={$_.ImpactedField}},@{n='Resource Name';e={$_.ImpactedValue}},Category,Impact,Problem,Solution | Where Category -EQ $Category.Category
    $categoryTableHTML = ($categoryTable | ConvertTo-Html) -replace "</body></html>",""
    $categoryTitle = "<h3>" + $Category.Category + "</h3>"
    $CategoryResult = $categoryTitle + $categoryTableHTML
    $CategoryResult

}

###############################################  GET SECURITY CENTER RECOMMENDATIONS ###############################################
$securityTasks = Get-AzSecurityTask
$securitytable = foreach ($resource in $securityTasks) {
    
    $tableline = 1 | select Recommendatoin,ResourceID
    if ($resource.ResourceId.length -lt 52) {
    
        $tableline.Recommendatoin = $resource.RecommendationType
        $tableline.ResourceID = "Subscription"
    
    } 
    else
    {
        
        $stinglength = $resource.ResourceId.Length
        $indexlength = (($resource.ResourceId.IndexOf("/providers/")) + 11)
        $resourceName = $resource.ResourceId.Substring($indexlength,($stinglength - $indexlength))

        $tableline.Recommendatoin = $resource.RecommendationType
        $tableline.ResourceID = $resourceName

    }
    $tableline

}
$securityRecommendations =  $securitytable | ConvertTo-Html

###############################################  GET A LIST OF RESOURCES IN SUBSCRIPTION ###############################################
# $resources = Get-AzResource | Group-Object ResourceType

# $resourceTable = foreach ($resource in $resources) {
    
#     $tableline = 1 | select Count,ResourceType

        
#     $stinglength = $resource.Name.Length
#     $indexlength = (($resource.Name.IndexOf("/")) + 1)
#     $resourceName = $resource.Name.Substring($indexlength,($stinglength - $indexlength))

#     $tableline.Count = $resource.Count
#     $tableline.ResourceType = $resourceName

   
#     $tableline

# }
# $resourceList = $resourceTable | ConvertTo-Html


# $advisorRecommendationsHTML = $advisorRecommendations -replace "</body></html>",""
$securityRecommendationsHTML = $securityRecommendations -replace "</body></html>",""
# $resourceListHTML = $resourceList -replace "</body></html>",""

###############################################  CONSTRUCT EMAIL ###############################################
$Head = @"
  
<style>
  body {
    font-family: "Arial";
    font-size: 10pt;
    color: #4C607B;
    }
  table {
    border: 1px solid black;
    border-collapse: collapse;
    }
  th, td { 
    border: 1px solid #e57300;
    border-collapse: collapse;
    padding: 5px;
    }
  th {
    font-size: 1.2em;
    text-align: left;
    background-color: #003366;
    color: #ffffff;
    }
  td {
    color: #000000;
    }
  .even { background-color: #ffffff; }
  .odd { background-color: #bfbfbf; }
</style>
  
"@

$body = @"
    
    <center><h1>Azure Recommendations for Subscription: $sub</h1></center>
    <h2>Azure Advisor Recommendations Summary</h2>
    <p>A summary of the recommendations from Azure's Advisor service</p>

"@

$body += $recommendationssummary

$body += @"
    
    <h2>Azure Advisor Recommendations Details</h2>
    <p>Detailed information about each of the Azure Advisor Categories</p>

"@

$body += $recommendationDetails

# $body += @"
    
#     <h2>Azure Security Center Recommendations</h2>
#     <p>Below are recommendations from Azure's Security Center.</p>

# "@

# $body += $securityRecommendationsHTML

# $body += @"
    
#     <h2>Azure Resources Utilised</h2>
#     <p>Below is a list of resources that are being used inside the subscription.</p>

# "@

# $body += $resourceListHTML

$body += @"

<p class="MsoNormal"><b><span style="font-size:12.0pt;font-family:&quot;Arial&quot;,sans-serif;color:#454545;mso-fareast-language:EN-GB">Azure Team</span></b><span style="font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#454545;mso-fareast-language:EN-GB"><br>
</span><b><span style="font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#DC4405;mso-fareast-language:EN-GB">________________________<o:p></o:p></span></b></p>
<p class="MsoNormal" style="mso-margin-top-alt:auto;margin-bottom:15.75pt"><b><span style="font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#454545;mso-fareast-language:EN-GB">Advanced Computer Software Group</span></b>
<p class="MsoNormal" style="mso-margin-top-alt:auto;margin-bottom:15.75pt"><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif;color:#1F497D;mso-fareast-language:EN-GB"><a href="http://www.oneadvanced.com/"><span style="font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#DC4405">www.oneadvanced.com</span></a></span><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif;color:black;mso-fareast-language:EN-GB"><o:p></o:p></span></p>
<p class="MsoNormal" style="mso-margin-top-alt:12.0pt;margin-right:0cm;margin-bottom:12.0pt;margin-left:0cm">

<p class="MsoNormal" style="mso-margin-top-alt:auto;margin-bottom:15.75pt"><b><span style="font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#DC4405;mso-fareast-language:EN-GB">&gt;</span></b><b><span style="font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#454545;mso-fareast-language:EN-GB">&nbsp;A
 Sunday Times Top Track 250 Company 2015<br>
</span></b><b><span style="font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#DC4405;mso-fareast-language:EN-GB">&gt;</span></b><b><span style="font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#454545;mso-fareast-language:EN-GB">&nbsp;Ranked in UK's 50 fastest
 growing technology companies 2014</span></b><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif;color:black;mso-fareast-language:EN-GB"><o:p></o:p></span></p>
<p class="MsoNormal" style="mso-margin-top-alt:auto;margin-bottom:15.75pt"><span style="font-size:8.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#AAAAAA;mso-fareast-language:EN-GB">This message is confidential. You may use and apply the information only for the
 intended purpose. Internet communications are not secure and therefore Advanced does not accept legal responsibility&nbsp;for the contents of this message. Any views or opinions presented are only those of the author and not those of Advanced. If this email has
 come to you in error please delete it and any attachments</span><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif;color:black;mso-fareast-language:EN-GB"><o:p></o:p></span></p>
<p class="MsoNormal"><o:p>&nbsp;</o:p></p>
</html>

"@


$HTML = $Head + $body


$secret = Get-AzKeyVaultSecret -VaultName 'kv-coreServices-KJR' -Name 'SGAPICred'
$pw = $secret.SecretValueText
$date = Get-Date -Format "dddd dd/MM/yyyy"
$username="apikey"

$securePw=ConvertTo-SecureString $pw -AsPlainText -Force

$Cred = New-Object System.Management.Automation.PSCredential ($username, $securePw)

Send-MailMessage -From AzureReports@oneadvanced.com -To ${local.advisor-emails} -Subject "Advanced Azure Report Sub: $sub $date" -Port 587 -UseSSL -SmtpServer smtp.sendgrid.net -Credential $Cred -BodyAsHtml $HTML
