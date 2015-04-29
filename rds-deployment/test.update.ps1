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



$template   = '.'
$defaultparamsfile = "$template\azuredeploy-parameters.json"
$paramsfile        = "$template\my-azuredeploy-parameters.json"

$parameters = @{}

$guid = [guid]::NewGuid().ToString()


$group = "rds-9e9ce5f7-aa6f-4cc9-8d34-023e39c0d4fa"



if (test-path $defaultparamsfile)
{
    $json = get-content $defaultparamsfile -raw | convertfrom-json
    $json.parameters.psobject.properties | % { $parameters += @{ $_.name = $_.value.value } }
}

$name = "update-vnet-join-domain"

$override = @{     
            location           = "West US";
            storageAccountName = "sa6f4cc98d34023e39c0d4fa"
            } 


write-parameters ( $override, $parameters | get-unique ) | out-file $paramsfile



New-AzureResourceGroupDeployment -Name $name -ResourceGroupName $group -TemplateFile "$template\azuredeploy.update.json" -TemplateParameterFile $paramsfile -Verbose


# deployment running...


$errors = Get-AzureResourceGroupLog -ResourceGroup $group -Status Failed -DetailedOutput

"Errors: $($errors.Count)"
$errors | % { $_.Properties.Content }   # .Content["statusCode" | "statusMessage" | "responseBody"]

