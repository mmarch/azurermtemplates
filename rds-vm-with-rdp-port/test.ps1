function add-parameter
{
    param([string]$name, [string]$value)

    "`t`"$name`" : {`n`t`t `"value`" : `"$value`"`n`t}"
}


function write-parameters
{
    param([hashtable]$parameters)

    "{`n" + (($parameters.getenumerator() | % { add-parameter $_.key $_.value }) -join ",`n") + "`n}"
}





$guid = [guid]::NewGuid().ToString()
$group = "rds-" + $guid
$sa = "sa" + ($guid -replace '-','').Substring(10)


New-AzureResourceGroup -Name $group -Location 'West US'  

<#
$template   = '101-create-storage-account'
$paramsfile = "$template\my-azuredeploy-parameters.json"

write-parameters @{ location = "West US"; newStorageAccountName = $sa } | out-file $paramsfile

New-AzureResourceGroupDeployment -Name "create-storage-account" -ResourceGroupName $group -TemplateFile "$template\azuredeploy.json" -TemplateParameterFile $paramsfile
#>


$template   = '.'
$paramsfile = "$template\my-azuredeploy-parameters.json"

write-parameters @{     location           = "West US"; 
                        storageAccountName = $sa;
                        publicDnsName      = "rds-" + $guid     } | out-file $paramsfile

New-AzureResourceGroupDeployment -Name "vm-with-rdp-port" -ResourceGroupName $group -TemplateFile "$template\azuredeploy.json" -TemplateParameterFile $paramsfile -Verbose



$errors = Get-AzureResourceGroupLog -ResourceGroup $group -Status Failed -DetailedOutput

"Errors: $($errors.Count)"
$errors | % { $_.Properties.Content }   # .Content["statusCode" | "statusMessage" | "responseBody"]

