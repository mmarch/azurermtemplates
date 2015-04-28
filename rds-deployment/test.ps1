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
$defaultparamsfile = "$template\azuredeploy.parameters.json"
$paramsfile        = "$template\my-azuredeploy-parameters.json"

$parameters = @{}

$guid = [guid]::NewGuid().ToString()
$group = "rds-" + $guid
$sa = "sa" + ($guid -replace '-','').Substring(10)

if (test-path $defaultparamsfile)
{
    $json = get-content $defaultparamsfile -raw | convertfrom-json
    $json.parameters.psobject.properties | % { $parameters += @{ $_.name = $_.value.value } }
}

$name = $myinvocation.mycommand.path | split-path -parent | split-path -leaf

$override = @{     
            location           = "West US"; 
            storageAccountName = $sa;
            publicDnsName      = "rds-" + $guid     
            } 


write-parameters ( $override, $parameters | get-unique ) | out-file $paramsfile



New-AzureResourceGroup -Name $group -Location 'West US'  

New-AzureResourceGroupDeployment -Name $name -ResourceGroupName $group -TemplateFile "$template\azuredeploy.json" -TemplateParameterFile $paramsfile -Verbose


# deployment running...


$errors = Get-AzureResourceGroupLog -ResourceGroup $group -Status Failed -DetailedOutput

"Errors: $($errors.Count)"
$errors | % { $_.Properties.Content }   # .Content["statusCode" | "statusMessage" | "responseBody"]

