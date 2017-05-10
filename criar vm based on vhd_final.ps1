# criar vm from a vhd disk specialized
 
# disco specialized é um disco (vhd) para ser usado unicamente para criar uma nova VM
# há a opcao de usar um disco vhd chamado generalized ... esse tipo de vhd permite ser usado como base para criacao de várias VMs (nao é o caso desse script)

# step 0
# nem sempre precisa ser rodado, pode ja estar disponivel no seu powershell
Install-Module AzureRM.Compute -RequiredVersion 2.6.0 -Scope CurrentUser

# logar no azure
Login-AzureRmAccount
Get-AzureRmSubscription
Select-AzureRmSubscription -SubscriptionId "a4002580-6b68-4d27-9418-af7f8d210766"

# step 1 - location, vnet - nesse caso na subscricao do itau o RG, vnet e subnet ja existiam, por isso estou usando "Get-..."
$location = "East US"
$vnetName = "blockchain-itau-vnet"
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName

# step 2 - RG, subnet - nesse caso na subscricao do itau o RG, vnet e subnet ja existiam, por isso estou usando "Get-..."
$rgName = "blockchain-itau"
$subnetName = "blockchain-subnet-dev2"
$singleSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

# step 3 - ip
$ipName = "ip-dev3"
$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic

# step 4 - nic
$nicName = "nic-dev3"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[2].Id -PublicIpAddressId $pip.Id

# step 5 - nsg
$nsgName = "nsg-dev3"
$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name myRdpRule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $location -Name $nsgName -SecurityRules $rdpRule

# bind nsg e nic feito com Rafa
$nic.NetworkSecurityGroup = $nsg
Set-AzureRmNetworkInterface -NetworkInterface $nic

# step 6 - vm
$vmName = "dlt-win12-dev3"
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_D2_v2" #Aqui o VMSize pode mudar de acordo com o tamanho da máquina

# step 7 - add nic to vm
$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id

# step 8 - apontar o vhd - o procedimento nesse step é para disco specialized. Para disco generalized o procedimento é outro. Ver na seguinte página microsoft: 
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/create-vm-generalized
$osDiskUri = "<URI do seu VHD>"
$osDiskName = $vmName + "osDisk"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption attach -Windows

# step 10 Criando a nova VM
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm

# step 11 - validar a criacao da vm
$vmList = Get-AzureRmVM -ResourceGroupName $rgName
$vmList.Name