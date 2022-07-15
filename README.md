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

> :warning:  **DO NOT deploy this template examples in a production environment or alongside any sensitive AWS resources.**

> :warning:  **All passwords in this repo are used as an example and should not be used in production**

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

* [zpc-aws-cfn-iac-scanning](https://github.com/zscaler-bd-sa/zpc-aws-cfn-iac-scanning) - Vulnerable by design Cloudformation template
* [zpc-terraform-iac-scanning](https://github.com/zscaler-bd-sa/zpc-terraform-iac-scanning) - Vulnerable by design Terraform stack
* [zpc-kustomize-iac-scanning](https://github.com/zscaler-bd-sa/zpc-kustomize-iac-scanning) - Vulnerable by design kustomize deployment

## Contributing

Contribution is welcomed!

We would love to hear about more ideas on how to find vulnerable infrastructure-as-code design patterns.

## Support

[Zscaler-BD-SA Team](https://github.com/zscaler-bd-sa) builds and maintains TerraGoat to encourage the adoption of policy-as-code.

If you need direct support you can contact us at [zscaler-partner-labs@z-bd.com](mailto:zscaler-partner-labs@z-bd.com).

## Existing vulnerabilities (Auto-Generated)

|     | check_id      | file                          | resource                                                | check_name                                                                                                                                                   | guideline                                                                                                                                    |
|-----|---------------|-------------------------------|---------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
|  0 | ZS-GCP-00001   | /aws/instances.tf                | google_compute_instance.server                                 | Ensure that instances are not configured to use the default service account                                                                                           |                                           |
|  1 | ZS-GCP-00002   | /aws/instances.tf                | google_compute_instance.server                                 | Ensure that Compute instances have Confidential Computing enabled                                                                                           |                                           |
|  2 | ZS-GCP-00006   | /aws/instances.tf                | google_compute_instance.server                                 | Ensure that IP forwarding is not enabled on Instances                                                                                           |                                           |
|  3 | ZS-GCP-00008   | /aws/instances.tf                | google_compute_instance.server                                 | Ensure Compute instances are launched with Shielded VM enabled                                                                                           |                                           |
|  4 | ZS-GCP-00009   | /aws/instances.tf                | google_compute_instance.server                                 | Ensure that Compute instances do not have public IP addresses                                                                                           |                                           |
|  5 | ZS-GCP-00011   | /aws/big_data.tf                | google_bigquery_dataset.dataset                                 | Ensure that a Default Customer-managed encryption key (CMEK) is specified for all BigQuery Data Sets                                                                                           |                                           |
|  6 | ZS-GCP-00014   | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure that the 'log_checkpoints' database flag for Cloud SQL PostgreSQL instance is set to 'on'                                                                                           |                                           |
|  7 | ZS-GCP-00016   | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure 'log_min_error_statement' database flag for Cloud SQL PostgreSQL instance is set to 'Error' or stricter                                                                                           |                                           |
|  8 | ZS-GCP-00017   | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure 'log_error_verbosity' database flag for Cloud SQL PostgreSQL instance is set to 'DEFAULT' or stricter                                                                                           |                                           |
|  9 | ZS-GCP-00019   | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure 'log_statement' database flag for Cloud SQL PostgreSQL instance is set appropriately                                                                                           |                                           |
|  10 | ZS-GCP-00020   | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure 'log_duration' database flag for Cloud SQL PostgreSQL instance is set to 'on'                                                                                           |                                           |
|  11 | ZS-GCP-00022   | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure that the 'log_connections' database flag for Cloud SQL PostgreSQL instance is set to 'on'                                                                                           |                                           |
|  12 | ZS-GCP-00023  | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure that the 'log_disconnections' database flag for Cloud SQL PostgreSQL instance is set to 'on'                                                                                           |                                           |
|  13 | ZS-GCP-00024   | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure that the 'log_lock_waits' database flag for Cloud SQL PostgreSQL instance is set to 'on'                                                                                           |                                           |
|  14 | ZS-GCP-00025   | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure that the 'log_min_messages' database flag for Cloud SQL PostgreSQL instance is set appropriately                                                                                           |                                           |
|  15 | ZS-GCP-00026   | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure that the 'log_temp_files' database flag for Cloud SQL PostgreSQL instance is set to '0' (on)                                                                                           |                                           |
|  16 | ZS-GCP-00037   | /aws/big_data.tf                | google_sql_database_instance.master_instance                                 | Ensure that the Cloud SQL database instance requires all incoming                                                                                           |                                           |
|  17 | ZS-GCP-00056   | /aws/big_data.tf                | google_storage_bucket.zs-terraform-iac-scanning_website                                  | Ensure that Cloud Storage buckets have uniform bucket-level access enabled                                                                                           |                                           |
|  18 | ZS-GCP-00128   | /aws/gke.tf                | google_container_cluster.workload_cluster                                   | Ensure clusters are created with Private Endpoint Enabled and Public Access Disabled                                                                                           |                                           |
|  19 | ZS-GCP-00129   | /aws/gke.tf                | google_container_cluster.workload_cluster                                   | Ensure Integrity Monitoring for Shielded GKE Nodes is Enabled                                                                                           |                                           |
|  20 | ZS-GCP-00130   | /aws/gke.tf                | google_container_cluster.workload_cluster                                   | Ensure the GKE Metadata Server is Enabled                                                                                           |                                           |
|  21 | ZS-GCP-00131   | /aws/gke.tf                | google_container_cluster.workload_cluster                                   | Ensure Shielded GKE Nodes are Enabled                                                                                           |                                           |
|  22 | ZS-GCP-00132   | /aws/gke.tf                | google_container_cluster.workload_cluster                                   | Ensure Secure Boot for Shielded GKE Nodes is Enabled                                                                                           |                                           |
|  23 | ZS-GCP-00133   | /aws/gke.tf                | google_container_cluster.workload_cluster                                   | Ensure clusters are created with Private Nodes                                                                                           |                                           |
|  24 | ZS-GCP-00134   | /aws/gke.tf                | google_container_cluster.workload_cluster                                   | Ensure use of Binary Authorization                                                                                           |                                           |
|  25 | ZS-GCP-00135   | /aws/gke.tf                | google_container_cluster.workload_cluster                                   | Kubernetes RBAC users are not managed with Google Groups for GKE                                                                                           |                                           |
|  26 | ZS-GCP-00136   | /aws/gke.tf                | google_container_cluster.workload_cluster                                   | Enable VPC Flow Logs and Intranode Visibility                                                                                           |                                           |
|  27 | ZS-AWS-00030   | /aws/db-app.tf                | aws_db_instance.default                                 | Ensure that EC2 has detailed monitoring enabled                                                                                           |                                           |
|  28 | ZS-AWS-00031    | /aws/db-app.tf                | aws_db_instance.default                                 | Ensure that EC2 instance should have IMDS disabled or require IMDSv2                                                                                                            |                                                            |
|  29 | ZS-AWS-00032    | /aws/db-app.tf                | aws_db_instance.default                                 | Ensure that backup retention is enabled for RDS Instances                                                                                                                  |                                                                  |
|  30 | ZS-AWS-00007    | /aws/db-app.tf                | aws_db_instance.default                                 | Ensure that encryption is enabled for RDS MySQL Instances                                                                                                     |                                                                                                                                              |
|  31 | ZS-AWS-00028    | /aws/ec2.tf                | aws_ebs_volume.web_host_storage                                 | Ensure that encryption is enabled for EBS volumes                                                                                              |                                                                                                     |
|  32 | ZS-AWS-0002   | /aws/kms.tf                | aws_kms_key.key                                 | Ensure rotation for customer created CMKs is enabled                                                                                                               |                                                                                                    |
|  33 | ZS-AWS-00054   | /aws/ec2.tf                | aws_security_group.web-node                                 | Ensure that Security Groups does not have unrestricted public access                                                                    |                      |
|  34 | ZS-AWS-00044    | /aws/ec2.tf                | aws_security_group.web-node                                 | Ensure that Security Groups does not have unrestricted HTTP access                                                                                                     |                                                                                                      |
|  35 | ZS-AWS-00020    | /aws/ec2.tf                | aws_security_group.web-node                              | Ensure that Security Groups does not have unrestricted SSH access                                                                                                          |                                                                                                 |
|  36 | ZS-AWS-00035    | /aws/s3.tf                | aws_s3_bucket.financials                         | Ensure that object versioning is enabled for S3 buckets                                                                                                          |                                                                                                 |
|  37 | ZS-AWS-00035    | /aws/s3.tf                | aws_s3_bucket.flowbucket                          | Ensure that object versioning is enabled for S3 buckets                                                                                                          |                                                                                                 |
|  38 | ZS-AWS-00035    | /aws/s3.tf                | aws_s3_bucket.data                                     | Ensure that object versioning is enabled for S3 buckets                                                                                                    |                                                                                             |
|  39 | ZS-AWS-00026     | /aws/s3.tf                | aws_s3_bucket.logs                                     | Ensure MFA Delete is enable on S3 buckets                                                                                                    |                                                                                             |
|  40 | ZS-AWS-00026     | /aws/s3.tf                | aws_s3_bucket.data_science                                     | Ensure MFA Delete is enable on S3 buckets                                                                                                    |                                                                                             |
|  41 | ZS-AWS-00026     | /aws/s3.tf                | aws_s3_bucket.financials                                     | Ensure MFA Delete is enable on S3 buckets                                                                                                    |                                                                                             |
|  42 | ZS-AWS-00026     | /aws/s3.tf                | aws_s3_bucket.flowbucket                                     | Ensure MFA Delete is enable on S3 buckets                                                                                                    |                                                                                             |
|  43 | ZS-AWS-00026     | /aws/s3.tf                | aws_s3_bucket.data                                     | Ensure MFA Delete is enable on S3 buckets                                                                                                    |                                                                                             |
|  44 | ZS-AWS-00026     | /aws/s3.tf                | aws_s3_bucket.operations                                     | Ensure MFA Delete is enable on S3 buckets                                                                                                    |                                                                                             |
|  45 | ZS-AWS-00034     | /aws/s3.tf                | aws_s3_bucket.logs                                     | Ensure that lifecycle configuration is applied to S3 buckets                                                                                                    |                                                                                             |
|  46 | ZS-AWS-00034     | /aws/s3.tf                | aws_s3_bucket.data_science                                     | Ensure that lifecycle configuration is applied to S3 buckets                                                                                                    |                                                                                             |
|  47 | ZS-AWS-00034     | /aws/s3.tf                | aws_s3_bucket.financials                                     | Ensure that lifecycle configuration is applied to S3 buckets                                                                                                    |                                                                                             |
|  48 | ZS-AWS-00034     | /aws/s3.tf                | aws_s3_bucket.flowbucket                                     | Ensure that lifecycle configuration is applied to S3 buckets                                                                                                    |                                                                                             |
|  49 | ZS-AWS-00034     | /aws/s3.tf                | aws_s3_bucket.data                                     | Ensure that lifecycle configuration is applied to S3 buckets                                                                                                    |                                                                                             |
|  50 | ZS-AWS-00034     | /aws/s3.tf                | aws_s3_bucket.operations                                     | Ensure that lifecycle configuration is applied to S3 buckets                                                                                                    |                                                                                             |
|  51 | ZS-AWS-00018     | /aws/s3.tf                | aws_s3_bucket.logs                                     | Ensure that S3 buckets have access logging enabled                                                                                                    |                                                                                             |
|  52 | ZS-AWS-00018     | /aws/s3.tf                | aws_s3_bucket.financials                                     | Ensure that S3 buckets have access logging enabled                                                                                                    |                                                                                             |                                         |
|  53 | ZS-AWS-00018     | /aws/s3.tf                | aws_s3_bucket.flowbucket                                     | Ensure that S3 buckets have access logging enabled                                                                                                    |                                                                                             |                                         |
|  54 | ZS-AWS-00018     | /aws/s3.tf                | aws_s3_bucket.data                                     | Ensure that S3 buckets have access logging enabled                                                                                                    |                                                                                             |                                         |
|  55 | ZS-AWS-00018     | /aws/s3.tf                | aws_s3_bucket.operations                                     | Ensure that S3 buckets have access logging enabled                                                                                                    |                                                                                             |                                         |
|  56 | ZS-AWS-00025     | /aws/s3.tf                | aws_s3_bucket.data_science                                     | Ensure default server side encryption is enabled for S3 buckets                                                                                                    |                                                                                             |                                         |
|  57 | ZS-AWS-00025     | /aws/s3.tf                | aws_s3_bucket.financials                                     | Ensure default server side encryption is enabled for S3 buckets                                                                                                    |                                                                                             |                                         |
|  58 | ZS-AWS-00025     | /aws/s3.tf                | aws_s3_bucket.flowbucket                                     | Ensure default server side encryption is enabled for S3 buckets                                                                                                    |                                                                                             |                                         |
|  59 | ZS-AWS-00025     | /aws/s3.tf                | aws_s3_bucket.data                                     | Ensure default server side encryption is enabled for S3 buckets                                                                                                    |                                                                                             |                                         |
|  60 | ZS-AWS-00025     | /aws/s3.tf                | aws_s3_bucket.operations                                     | Ensure default server side encryption is enabled for S3 buckets                                                                                                    |                                                                                             |                                         |
|  61 | ZS-AWS-00139     | /aws/eks.tf                | aws_eks_cluster.eks_cluster                                     | Ensure Kubernetes Secrets are encrypted using Customer Master Keys (CMKs) managed in AWS KMS                                                                                                     |                                                                                             |                                         |
|  62 | ZS-AWS-00030     | /aws/db-app.tf                | aws_instance.db_app                                     | Ensure that EC2 has detailed monitoring enabled                                                                                                      |                                                                                             |                                         |
|  63 | ZS-AWS-00030     | /aws/ec2.tf                | aws_instance.web_host                                     | Ensure that EC2 has detailed monitoring enabled                                                                                                      |                                                                                             |                                         |
|  64 | ZS-AWS-00001     | /aws/ec2.tf                | aws_instance.web_host                                     | Ensure that IAM instance roles used to provision access to AWS resources                                                                                                      |                                                                                             |                                         |
|  65 | ZS-AWS-00031    | /aws/db-app.tf                | aws_instance.db_app                                     | Ensure that EC2 instance should have IMDS disabled or require IMDSv2                                                                                                      |                                                                                             |                                         |
|  66 | ZS-AWS-00031    | /aws/ec2.tf                | aws_instance.web_host                                     | Ensure that EC2 instance should have IMDS disabled or require IMDSv2                                                                                                      |                                                                                             |                                         |
|  67 | ZS-AWS-00031    | /aws/ec2.tf                | aws_instance.default                                     | Ensure that backup retention is enabled for RDS Instances                                                                                                      |                                                                                             |                                         |
|  68 | ZS-AWS-00007    | /aws/ec2.tf                | aws_instance.default                                     | Ensure that encryption is enabled for RDS MySQL Instances                                                                                                      |                                                                                             |                                         |
|  69 | ZS-AZURE-00018    | /aws/sql.tf                | azurerm_sql_server.example                                     | Ensure that 'Advanced Data Security' on a SQL server is set to 'On'                                                                                                      |                                                                                             |                                         |
|  70 | ZS-AZURE-00006    | /aws/app_service.tf                | azurerm_sql_server.app-service1                                     | Ensure FTP deployments are disabled for API app                                                                                                      |                                                                                             |                                         |
|  71 | ZS-AZURE-00006    | /aws/app_service.tf                | app_service.app-service2                                     | Ensure FTP deployments are disabled for API app                                                                                                      |                                                                                             |                                         |
|  72 | ZS-AZURE-00029    | /aws/app_service.tf                | app_service.app-service1                                     | Ensure that 'HTTP Version' is the latest, if used to run the web app                                                                                                      |                                                                                             |                                         |
|  73 | ZS-AZURE-00029    | /aws/app_service.tf                | app_service.app-service2                                     | Ensure that 'HTTP Version' is the latest, if used to run the web app app                                                                                                      |                                                                                             |                                         |
|  74 | ZS-AZURE-00044    | /aws/app_service.tf                | app_service.app-service2                                     | Ensure that 'HTTP Version' is the latest, if used to run the web app app                                                                                                      |                                                                                             |                                         |
|  75 | ZS-AZURE-00044    | /aws/app_service.tf                | app_service.app-service2                                     | Ensure web app has 'Client Certificates (Incoming client certificates)' set to 'On'                                                                                                      |                                                                                             |                                         |
|  76 | ZS-AZURE-00034    | /aws/app_service.tf                | app_service.app-service1                                     | Ensure that Register with Azure Active Directory is enabled on App Service                                                                                                      |                                                                                             |                                         |
|  77 | ZS-AZURE-00034   | /aws/app_service.tf                | app_service.app-service2                                     | Ensure that Register with Azure Active Directory is enabled on App Service                                                                                                      |                                                                                             |                                         |
|  78 | ZS-AZURE-00020   | /aws/app_service.tf                | app_service.app-service1                                     | Ensure that 'App Service Authentication' is enabled for API Apps                                                                                                      |                                                                                             |                                         |
|  79 | ZS-AZURE-00020   | /aws/app_service.tf                | app_service.app-service2                                     | Ensure that 'App Service Authentication' is enabled for API Apps                                                                                                      |                                                                                             |                                         |
|  80 | ZS-AZURE-00045   | /aws/app_service.tf                | app_service.app-service1                                     | Ensure web app is using the latest version of TLS encryption                                                                                                      |                                                                                             |                                         |
|  81 | ZS-AZURE-00045   | /aws/app_service.tf                | app_service.app-service2                                     | Ensure web app is using the latest version of TLS encryption                                                                                                      |                                                                                             |                                         |
|  82 | ZS-AZURE-00046   | /aws/app_service.tf                | app_service.app-service2                                     | Ensure web app redirects all HTTP traffic to HTTPS in Azure App Service                                                                                                      |                                                                                             |                                         |
|  83 | ZS-AZURE-00004   | /aws/sql.tf                | azurerm_mysql_server.example                                     | Ensure 'Enforce SSL connection' is set to 'ENABLED' for MySQL Database Server                                                                                                      |                                                                                             |                                         |
|  84 | ZS-AZURE-00004   | /aws/sql.tf                | azurerm_storage_account.example                                     | Ensure that 'Secure transfer required' is 'Enabled' for Storage Account                                                                                                      |                                                                                             |                                         |
|  85 | ZS-AZURE-00003   | /aws/storage.tf                | azurerm_storage_account.example                                     | Ensure default network access rule for Storage Accounts is set to deny                                                                                                      |                                                                                             |                                         |
|  86 | ZS-AZURE-00003   | /aws/mssql.tf                | azurerm_storage_account.security_storage_account                                      | Ensure default network access rule for Storage Accounts is set to deny                                                                                                      |                                                                                             |                                         |
|  87 | ZS-AZURE-00039   | /aws/storage.tf                | azurerm_managed_disk.example                                      | Ensure that 'Unattached disks' are encrypted                                                                                                      |                                                                                             |                                         |
|  88 | ZS-AZURE-00002   | /aws/aks.tf                | azurerm_kubernetes_cluster.k8s_cluster                                      | Ensure that 'Unattached disks' are encrypted                                                                                                      |                                                                                             |                                         |
|  89 | ZS-AZURE-00005   | /aws/aks.tf                | azurerm_postgresql_server.example                                      | Ensure 'Enforce SSL connection' is set to 'true' for PostgreSQL Database Server                                                                                                      |                                                                                             |                                         |
