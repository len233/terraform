#!/bin/bash

echo "🔧 IMPORT DES RESSOURCES AZURE EXISTANTES DANS TERRAFORM STATE"
echo "=============================================================="
echo ""

cd /Users/mihu/projet_cloud_computing/terraform/terraform

# Variables
SUBSCRIPTION_ID="c8148adc-f0a7-49f7-9f36-f085f62e9376"
RG="rg-terraform-cloud"

echo "📦 Resource Group: $RG"
echo "🔑 Subscription: $SUBSCRIPTION_ID"
echo ""

# 1. Resource Group
echo "1️⃣  Importing Resource Group..."
terraform import azurerm_resource_group.main \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ Resource Group imported"
else
  echo "   ⚠️  Already imported or error"
fi

# 2. Virtual Network
echo "2️⃣  Importing Virtual Network..."
terraform import azurerm_virtual_network.main \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/tfcloud-vnet" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ VNet imported"
else
  echo "   ⚠️  Already imported or error"
fi

# 3. Subnet
echo "3️⃣  Importing Subnet..."
terraform import azurerm_subnet.main \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/tfcloud-vnet/subnets/tfcloud-subnet" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ Subnet imported"
else
  echo "   ⚠️  Already imported or error"
fi

# 4. Public IP
echo "4️⃣  Importing Public IP..."
terraform import azurerm_public_ip.main \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Network/publicIPAddresses/tfcloud-public-ip" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ Public IP imported"
else
  echo "   ⚠️  Already imported or error"
fi

# 5. Network Security Group
echo "5️⃣  Importing Network Security Group..."
terraform import azurerm_network_security_group.main \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Network/networkSecurityGroups/tfcloud-nsg" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ NSG imported"
else
  echo "   ⚠️  Already imported or error"
fi

# 6. Network Interface
echo "6️⃣  Importing Network Interface..."
terraform import azurerm_network_interface.main \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Network/networkInterfaces/tfcloud-nic" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ NIC imported"
else
  echo "   ⚠️  Already imported or error"
fi

# 7. Virtual Machine
echo "7️⃣  Importing Virtual Machine..."
terraform import azurerm_linux_virtual_machine.main \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Compute/virtualMachines/tfcloud-vm" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ VM imported"
else
  echo "   ⚠️  Already imported or error"
fi

# 8. Storage Account
echo "8️⃣  Importing Storage Account..."
terraform import azurerm_storage_account.main \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/tfcloudstorage2026" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ Storage Account imported"
else
  echo "   ⚠️  Already imported or error"
fi

# 9. Storage Container: images
echo "9️⃣  Importing Storage Container 'images'..."
terraform import azurerm_storage_container.images \
  "https://tfcloudstorage2026.blob.core.windows.net/images" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ Container 'images' imported"
else
  echo "   ⚠️  Already imported or error"
fi

# 10. Storage Container: logs
echo "🔟 Importing Storage Container 'logs'..."
terraform import azurerm_storage_container.logs \
  "https://tfcloudstorage2026.blob.core.windows.net/logs" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ Container 'logs' imported"
else
  echo "   ⚠️  Already imported or error"
fi

# 11. Storage Container: static
echo "1️⃣1️⃣  Importing Storage Container 'static'..."
terraform import azurerm_storage_container.static \
  "https://tfcloudstorage2026.blob.core.windows.net/static" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ Container 'static' imported"
else
  echo "   ⚠️  Already imported or error"
fi

echo ""
echo "=============================================================="
echo "✅ IMPORT TERMINÉ !"
echo ""
echo "🔍 Vérification du state..."
terraform state list

echo ""
echo "📊 Résumé des ressources importées :"
terraform state list | wc -l | xargs echo "   Total:"

echo ""
echo "✅ Maintenant vous pouvez déployer PostgreSQL avec :"
echo "   terraform apply -auto-approve"
