$connection = Get-AutomationConnection -Name AzureRunAsConnection

Connect-AzureRmAccount `
-ServicePrincipal `
-Tenant $connection.TenantID `
-ApplicationId $connection.ApplicationID `
-CertificateThumbprint $connection.CertificateThumbprint

$aan="${azurerm_automation_account.account.name}"
$rgn="${var.aa-resourcegroup}"

$dsc=Get-AzureRmAutomationDscConfiguration `
		-AutomationAccountName $aan `
		-ResourceGroupName $rgn

$dsc | Start-AzureRmAutomationDscCompilationJob