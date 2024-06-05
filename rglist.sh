#!/bin/bash
# define a function
#  "deployments": {
#         "type": "Array",
#         "value": [
#           {
#             "model": {
#               "format": "OpenAI",
#               "name": "gpt-35-turbo",
#               "version": "0125"
#             },
#             "name": "chat",
#             "sku": {
#               "capacity": 30,
#               "name": "Standard"
#             }
#           },
#           {
#             "model": {
#               "format": "OpenAI",
#               "name": "text-embedding-ada-002",
#               "version": "2"
#             },
#             "name": "embed",
#             "sku": {
#               "capacity": 30,
#               "name": "Standard"
#             }
#           }
#         ]
#       }
# }
deployments_params='{
    "deployments": {
        "type": "Array",
        "value": [
            {
                "model": {
                    "format": "OpenAI",
                    "name": "gpt-4o",
                    "version": "0125"
                },
                "name": "chat",
                "sku": {
                    "capacity": 30,
                    "name": "Standard"
                }
            },
            {
                "model": {
                    "format": "OpenAI",
                    "name": "text-embedding-ada-002",
                    "version": "2"
                },
                "name": "embed",
                "sku": {
                    "capacity": 30,
                    "name": "Standard"
                }
            }
        ]
    }
}'
function updatedeployment() {
    resource_group=$selected_resource_group
    deployment_name=$2
    # set template to the infra folder, and choose the template file
    template_file="./infra/core/ai/cognitiveservices.bicep"
    deployments=$(az deployment group list --resource-group "$resource_group" --query "[].{Name:name}" --output tsv)
    # Check if there are any deployments
    if [ -z "$deployments" ]; then
        echo "No deployments found in the selected resource group."
        exit 1
    fi
    # Display the deployments with index numbers
    echo "Deployments in Resource Group '$resource_group':"
    index=0
    while IFS= read -r line; do
        echo "[$index] $line"
        index=$((index + 1))
    done <<< "$deployments"
    Prompt the user to choose a specific deployment by index
    read -p "Enter the number corresponding to the deployment you want to update: " index
    # Get the name of the selected deployment
    selected_deployment=$(echo "$deployments" | sed -n "$((index + 1))p" | awk '{print $1}')
    # Check if a deployment was selected
    if [ -z "$selected_deployment" ]; then
        echo "No deployment selected or invalid index."
        exit 1
    fi
    # Update the deployment with the new template
    echo "Updating deployment '$selected_deployment' in resource group '$resource_group'..."
    az deployment group show --resource-group "$resource_group" --name "$selected_deployment"
    # az deployment group create --resource-group "$resource_group" --name "$selected_deployment" --template-file "$template_file"
    # az deployment group create --resource-group "$resource_group" --name "$deployment_name" --template-file "$template_file"
    # echo "Deployment updated successfully."
}
# updatedeployment
# exit 0

function list_resources() {
    # List all resources in the selected resource group
    resources=$(az resource list --resource-group "$selected_resource_group" --query "[].{Name:name, Type:type}" --output tsv)
    # Check if there are any resources
    if [ -z "$resources" ]; then
        echo "No resources found in the selected resource group."
        exit 1
    fi
    # Display the resources with index numbers
    echo "Resources in Resource Group '$selected_resource_group':"
    index=0
    while IFS= read -r line; do
        echo "[$index] $line"
        index=$((index + 1))
    done <<< "$resources"
    # Prompt the user to choose a specific resource by index
    read -p "Enter the number corresponding to the resource you want to open: " index
    # Get the name of the selected resource
    selected_resource=$(echo "$resources" | sed -n "$((index + 1))p" | awk '{print $1}')
    # Check if a resource was selected
    if [ -z "$selected_resource" ]; then
        echo "No resource selected or invalid index."
        exit 1
    fi
    # check the type of the resource
    resource_type=$(echo "$resources" | sed -n "$((index + 1))p" | awk '{print $2}')
    # # if the resource is a storage account,list all the files or blobs in the storage account
    if [ "$resource_type" == "Microsoft.Storage/storageAccounts" ]; then
        # Get the subscription ID
        subscription_id=$(az account show --query "id" --output tsv)
        # Open the details page of the selected resource group in the Azure portal
        resource_url="https://portal.azure.com/#resource/subscriptions/$subscription_id/resourceGroups/$selected_resource_group/providers/Microsoft.Storage/storageAccounts/$selected_resource"
        # echo "Opening $resource_url in your browser..."
        # xdg-open "$resource_url" 2>/dev/null || open "$resource_url" 2>/dev/null || echo "Please open the following URL in your browser: $resource_url"
        # list all the files or blobs in the storage account
        # need add the container name
        container_name="files"
        # container_name=$(az storage account show --name "$selected_resource" --resource-group "$selected_resource_group" --query "primaryEndpoints.blob" --output tsv)
        # az storage blob list --account-name "$selected_resource" --query "[].{Name:name}" --output table
        az storage blob list --account-name "$selected_resource" --container-name "$container_name" --query "[].{Name:name}" --output table
    # another option
    elif [ "$resource_type" == "Microsoft.Web/sites" ]; then
     echo "This is a web app"
    elif [ "$resource_type" == "Microsoft.CognitiveServices/accounts" ]; then
    #    echo "This is a cognitive service account"
    # get all the info and endpoint
        echo "This is a cognitive service account"
        az cognitiveservices account show --name "$selected_resource" --resource-group "$selected_resource_group"
        # open the resource in the azure portal
        # Get the subscription ID
        subscription_id=$(az account show --query "id" --output tsv)
        # Open the details page of the selected resource group in the Azure portal
        resource_url="https://portal.azure.com/#resource/subscriptions/$subscription_id/resourceGroups/$selected_resource_group/providers/Microsoft.CognitiveServices/accounts/$selected_resource"
        echo "Opening $resource_url in your browser..."
        xdg-open "$resource_url" 2>/dev/null || open "$resource_url" 2>/dev/null || echo "Please open the following URL in your browser: $resource_url"
    else
         echo "This is a $resource_type"
    fi
}
# Ensure the Azure CLI is installed and the user is logged in
if ! command -v az &> /dev/null
then
    echo "Azure CLI not found. Please install it first."
    exit 1
fi

# List all resource groups and store the output in a variable
resource_groups=$(az group list --query "[].{Name:name, Location:location}" --output tsv)

# Check if there are any resource groups
if [ -z "$resource_groups" ]; then
    echo "No resource groups found."
    exit 1
fi

# Display the resource groups with index numbers
echo "Available Resource Groups:"
index=0
while IFS= read -r line; do
    echo "[$index] $line"
    index=$((index + 1))
done <<< "$resource_groups"

# Prompt the user to choose a specific resource group by index
read -p "Enter the number corresponding to the resource group you want to open: " index

# Get the name of the selected resource group
selected_resource_group=$(echo "$resource_groups" | sed -n "$((index + 1))p" | awk '{print $1}')

# Check if a resource group was selected
if [ -z "$selected_resource_group" ]; then
    echo "No resource group selected or invalid index."
    exit 1
fi

# query if the user wants to open the resource group in the Azure portal or list resouces under the group
read -p "Do you want to list resources under the resource group? [y/n]: " choice
# hanlde the user choice
if [ "$choice" == "y" ]; then
#    function
    # list_resources
    updatedeployment
else
    # Get the subscription ID
    subscription_id=$(az account show --query "id" --output tsv)
    # Open the details page of the selected resource group in the Azure portal
    resource_group_url="https://portal.azure.com/#resource/subscriptions/$subscription_id/resourceGroups/$selected_resource_group"
    echo "Opening $resource_group_url in your browser..."
    xdg-open "$resource_group_url" 2>/dev/null || open "$resource_group_url" 2>/dev/null || echo "Please open the following URL in your browser: $resource_group_url"
fi



# # Get the subscription ID
# subscription_id=$(az account show --query "id" --output tsv)

# # Open the details page of the selected resource group in the Azure portal
# resource_group_url="https://portal.azure.com/#resource/subscriptions/$subscription_id/resourceGroups/$selected_resource_group"
# echo "Opening $resource_group_url in your browser..."
# xdg-open "$resource_group_url" 2>/dev/null || open "$resource_group_url" 2>/dev/null || echo "Please open the following URL in your browser: $resource_group_url"