 # Connect to Azure (ensure the runbook has appropriate permissions)
Connect-AzAccount -Identity

# Parameters
$subscriptionId = "<>"
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
send-AzOperationalInsightsData -WorkspaceId "<>" -Data @{"VMStatus"=$vm.Statuses[1].DisplayStatus}

Write-Output "Health check completed for VM $vmName."





# Connect to Azure (ensure the runbook has appropriate permissions)
Connect-AzAccount -Identity

# Parameters
$subscriptionId = ""
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
send-AzOperationalInsightsData -WorkspaceId "" -Data @{"VMStatus"=$vm.Statuses[1].DisplayStatus}

Write-Output "Health check completed for VM $vmName."
