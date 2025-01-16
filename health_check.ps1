 # Connect to Azure (ensure the runbook has appropriate permissions)
Connect-AzAccount -Identity

# Parameters
$subscriptionId = "<ed19ccdf-7b4a-4666-8948-3923639ec896>"
$resourceGroupName = "<resource_group>"
$vmName = "<vm1>"

# Set the context to the correct subscription
Set-AzContext -SubscriptionId $subscriptionId

# Get VM status
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Status

# Check if the VM is running
if ($vm.Statuses[1].Code -eq "PowerState/running") {
    Write-Output "VM $vmName is running."
} else {
    Write-Output "VM $vmName is not running. Current status: $($vm.Statuses[1].DisplayStatus)"
}

# Optional: Check additional metrics (e.g., CPU, Memory, Disk)
# Add specific metric queries or integrations here if needed

# Example: Send output to a Log Analytics workspace
# Set this up if using Log Analytics for monitoring
send-AzOperationalInsightsData -WorkspaceId "<3df3c62a-e49e-4d35-9fa5-083e951e73fe>" -Data @{"VMStatus"=$vm.Statuses[1].DisplayStatus}

Write-Output "Health check completed for VM $vmName."





# Connect to Azure (ensure the runbook has appropriate permissions)
Connect-AzAccount -Identity

# Parameters
$subscriptionId = "ed19ccdf-7b4a-4666-8948-3923639ec896"
$resourceGroupName = "resource_group0"
$vmName = "vm2"

# Set the context to the correct subscription
Set-AzContext -SubscriptionId $subscriptionId

# Get VM status
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Status

# Check if the VM is running
if ($vm.Statuses[1].Code -eq "PowerState/running") {
    Write-Output "VM $vmName is running."
} else {
    Write-Output "VM $vmName is not running. Current status: $($vm.Statuses[1].DisplayStatus)"
}

# Optional: Check additional metrics (e.g., CPU, Memory, Disk)
# Add specific metric queries or integrations here if needed

# Example: Send output to a Log Analytics workspace
# Set this up if using Log Analytics for monitoring
send-AzOperationalInsightsData -WorkspaceId "2feb38df-cd8f-4496-b984-58a03f6fd6dc" -Data @{"VMStatus"=$vm.Statuses[1].DisplayStatus}

Write-Output "Health check completed for VM $vmName."
