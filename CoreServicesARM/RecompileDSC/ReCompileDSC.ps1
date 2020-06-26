Import-Module AzureRM

$aan="aa-coreServices"
$rgn="rg-coreServices"

$connection = Get-AzureRMAutomationConnection -Name AzureRunAsConnection -ResourceGroupName $rgn -AutomationAccountName $aan

Connect-AzureRmAccount `
-ServicePrincipal `
-Tenant $connection.TenantID `
-ApplicationId $connection.ApplicationID `
-CertificateThumbprint $connection.CertificateThumbprint

$dsc=Get-AzureRmAutomationDscConfiguration `
		-AutomationAccountName $aan `
		-ResourceGroupName $rgn

$dsc | Start-AzureRmAutomationDscCompilationJob
