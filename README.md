# Zscaler Posture Control (ZPC) - Vulnerable Terraform Infrastructure

This is "Vulnerable by Design" Terraform repository.

## Table of Contents

* [Introduction](#introduction)
* [Getting Started](#getting-started)
  * [AWS](#aws-setup)
  * [Azure](#azure-setup)
  * [GCP](#gcp-setup)
* [Contributing](#contributing)
* [Support](#support)

## Introduction

This repository was built to enable DevSecOps design and implement a sustainable misconfiguration prevention strategy. It can be used to test a policy-as-code framework, inline-linters, pre-commit hooks or other code scanning methods.

## Important notes

* **Where to get help:** the [Zscaler Community](https://community.zscaler.com/)

Before you proceed please take a note of these warning:
> :warning: These examples creates intentionally vulnerable AWS resources into your account.

**DO NOT deploy this template examples in a production environment or alongside any sensitive AWS resources.**
**All passwords in this repo are used as an example and should not be used in production**

## Requirements

* Terraform 0.13
* aws cli
* azure cli

To prevent vulnerable infrastructure from arriving to production and static analysis tool for infrastructure as code see: [Zscaler Posture Control](https://www.zscaler.com/products/posture-control)

## Getting started

### AWS Setup

#### Installation (AWS)

You can deploy multiple ZPC stacks in a single AWS account using the parameter `TF_VAR_environment`.

#### Create an S3 Bucket backend to keep Terraform state

```bash
export ZPC_STATE_BUCKET="zpcdevsecops-bucket"
export TF_VAR_company_name=acme
export TF_VAR_environment=mydevsecops
export TF_VAR_region="us-west-2"

aws s3api create-bucket --bucket $ZPC_STATE_BUCKET \
    --region $TF_VAR_region --create-bucket-configuration LocationConstraint=$TF_VAR_region

# Enable versioning
aws s3api put-bucket-versioning --bucket $ZPC_STATE_BUCKET --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption --bucket $ZPC_STATE_BUCKET --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms"
      }
    }
  ]
}'
```

#### Apply ZPC (AWS)

```bash
cd terraform/aws/
terraform init \
-backend-config="bucket=$ZPC_STATE_BUCKET" \
-backend-config="key=$TF_VAR_company_name-$TF_VAR_environment.tfstate" \
-backend-config="region=$TF_VAR_region"

terraform apply
```

#### Remove ZPC (AWS)

```bash
terraform destroy
```

#### Creating multiple ZPC AWS stacks

```bash
cd terraform/aws/
export ZPC_ENV=$TF_VAR_environment
export ZPC_STACKS_NUM=5
for i in $(seq 1 $ZPC_STACKS_NUM)
do
    export TF_VAR_environment=$ZPC_ENV$i
    terraform init \
    -backend-config="bucket=$ZPC_STATE_BUCKET" \
    -backend-config="key=$TF_VAR_company_name-$TF_VAR_environment.tfstate" \
    -backend-config="region=$TF_VAR_region"

    terraform apply -auto-approve
done
```

#### Deleting multiple ZPC stacks (AWS)

```bash
cd terraform/aws/
export TF_VAR_environment = $ZPC_ENV
for i in $(seq 1 $ZPC_STACKS_NUM)
do
    export TF_VAR_environment=$ZPC_ENV$i
    terraform init \
    -backend-config="bucket=$ZPC_STATE_BUCKET" \
    -backend-config="key=$TF_VAR_company_name-$TF_VAR_environment.tfstate" \
    -backend-config="region=$TF_VAR_region"

    terraform destroy -auto-approve
done
```

### Azure Setup

#### Installation (Azure)

You can deploy multiple ZPC stacks in a single Azure subscription using the parameter `TF_VAR_environment`.

#### Create an Azure Storage Account backend to keep Terraform state

```bash
export ZPC_RESOURCE_GROUP="ZPCRG"
export ZPC_STATE_STORAGE_ACCOUNT="mydevsecopssa"
export ZPC_STATE_CONTAINER="mydevsecops"
export TF_VAR_environment="dev"
export TF_VAR_region="westus"

# Create resource group
az group create --location $TF_VAR_region --name $ZPC_RESOURCE_GROUP

# Create storage account
az storage account create --name $ZPC_STATE_STORAGE_ACCOUNT --resource-group $ZPC_RESOURCE_GROUP --location $TF_VAR_region --sku Standard_LRS --kind StorageV2 --https-only true --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $ZPC_RESOURCE_GROUP --account-name $ZPC_STATE_STORAGE_ACCOUNT --query [0].value -o tsv)

# Create blob container
az storage container create --name $ZPC_STATE_CONTAINER --account-name $ZPC_STATE_STORAGE_ACCOUNT --account-key $ACCOUNT_KEY
```

#### Apply ZPC (Azure)

```bash
cd terraform/azure/
terraform init -reconfigure -backend-config="resource_group_name=$ZPC_RESOURCE_GROUP" \
    -backend-config "storage_account_name=$ZPC_STATE_STORAGE_ACCOUNT" \
    -backend-config="container_name=$ZPC_STATE_CONTAINER" \
    -backend-config "key=$TF_VAR_environment.terraform.tfstate"

terraform apply
```

#### Remove ZPC (Azure)

```bash
terraform destroy
```

### GCP Setup

#### Installation (GCP)

You can deploy multiple ZPC stacks in a single GCP project using the parameter `TF_VAR_environment`.

#### Create a GCS backend to keep Terraform state

To use terraform, a Service Account and matching set of credentials are required.
If they do not exist, they must be manually created for the relevant project.
To create the Service Account:

1. Sign into your GCP project, go to `IAM` > `Service Accounts`.
2. Click the `CREATE SERVICE ACCOUNT`.
3. Give a name to your service account (for example - `ZPC`) and click `CREATE`.
4. Grant the Service Account the `Project` > `Editor` role and click `CONTINUE`.
5. Click `DONE`.

To create the credentials:

1. Sign into your GCP project, go to `IAM` > `Service Accounts` and click on the relevant Service Account.
2. Click `ADD KEY` > `Create new key` > `JSON` and click `CREATE`. This will create a `.json` file and download it to your computer.

We recommend saving the key with a nicer name than the auto-generated one (i.e. `ZPC_credentials.json`), and storing the resulting JSON file inside `terraform/gcp` directory of ZPC.
Once the credentials are set up, create the BE configuration as follows:

```bash
export TF_VAR_environment="dev"
export TF_ZPC_STATE_BUCKET=remote-state-bucket-ZPC
export TF_VAR_credentials_path=<PATH_TO_CREDNETIALS_FILE> # example: export TF_VAR_credentials_path=ZPC_credentials.json
export TF_VAR_project=<YOUR_PROJECT_NAME_HERE>

# Create storage bucket
gsutil mb gs://${TF_ZPC_STATE_BUCKET}
```

#### Apply ZPC (GCP)

```bash
cd terraform/gcp/
terraform init -reconfigure -backend-config="bucket=$TF_ZPC_STATE_BUCKET" \
    -backend-config "credentials=$TF_VAR_credentials_path" \
    -backend-config "prefix=ZPC/${TF_VAR_environment}"

terraform apply
```

#### Remove ZPC (GCP)

```bash
terraform destroy
```

## Zscaler IaC Scanning Projects

* [zs-aws-cfn-iac-scanning](https://github.com/zscaler-bd-sa/zs-aws-cfn-iac-scanning) - Vulnerable by design Cloudformation template
* [zs-terraform-iac-scanning](https://github.com/zscaler-bd-sa/zs-terraform-iac-scanning) - Vulnerable by design Terraform stack
* [zs-kustomize-iac-scanning](https://github.com/zscaler-bd-sa/zs-kustomize-iac-scanning) - Vulnerable by design kustomize deployment

## Contributing

Contribution is welcomed!

We would love to hear about more ideas on how to find vulnerable infrastructure-as-code design patterns.
