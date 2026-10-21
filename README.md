# AWS Infrastructure with Terraform

## Overview

This project uses **Terraform** to provision AWS infrastructure, including a Virtual Private Cloud (VPC), public and private subnets, EC2 instances, security groups, load balancers, and an Auto Scaling Group.

The infrastructure demonstrates Infrastructure as Code (IaC), network segmentation, load balancing, and high availability across multiple Availability Zones.

## Architecture

The infrastructure includes:

- **VPC:** Isolated AWS virtual network.
- **Public subnets:** Host the internet-facing load balancers and a public EC2 instance.
- **Private subnets:** Host a private EC2 instance and the Auto Scaling Group instances.
- **EC2:** Virtual machines running Amazon Linux 2023.
- **Security Groups:** Control inbound and outbound network traffic.
- **Application Load Balancer (ALB):** Distributes HTTP requests at Layer 7.
- **Network Load Balancer (NLB):** Distributes TCP connections at Layer 4.
- **Auto Scaling Group (ASG):** Maintains a desired capacity of two instances and can scale between two and four instances.
- **Launch Template:** Defines the AMI, instance type, security group, and startup script for ASG instances.
- **NAT Gateway:** Provides outbound internet connectivity to private instances for tasks such as installing packages.

## Technologies Used

- AWS
- Terraform
- Amazon Linux 2023
- Amazon EC2
- Amazon VPC
- Application Load Balancer
- Network Load Balancer
- Auto Scaling
- Security Groups
- Apache HTTP Server

## Project Structure

```text
.
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── README.md
```

*The file structure may vary depending on how the Terraform configuration is organized.*

## Prerequisites

Before deploying the infrastructure, make sure you have:

1. An AWS account.
2. AWS CLI installed and configured.
3. Terraform installed.
4. Appropriate AWS IAM permissions.
5. An AWS region selected in your provider configuration.

Configure AWS credentials using an AWS profile or environment variables. Avoid hardcoding credentials in Terraform files.

## Deployment

### 1. Clone the repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd <YOUR_PROJECT_DIRECTORY>
```

### 2. Initialize Terraform

```bash
terraform init
```

Downloads the required providers and initializes the working directory.

### 3. Format the configuration

```bash
terraform fmt -recursive
```

Formats Terraform files consistently.

### 4. Validate the configuration

```bash
terraform validate
```

Checks the configuration for syntax and internal consistency errors.

### 5. Review the execution plan

```bash
terraform plan
```

Shows the infrastructure changes Terraform intends to make.

### 6. Deploy the infrastructure

```bash
terraform apply
```

Review the proposed changes and confirm when prompted.

## Accessing the Infrastructure

After deployment, Terraform displays the configured outputs.

| Output | Description |
|---|---|
| `alb_dns_name` | DNS name of the Application Load Balancer |
| `nlb_dns_name` | DNS name of the Network Load Balancer |
| `public_instance_ip` | Public IP address of the public EC2 instance |
| `private_instance_ip` | Private IP address of the private EC2 instance |

Retrieve all outputs:

```bash
terraform output
```

Retrieve a specific output:

```bash
terraform output alb_dns_name
```

Open the ALB DNS name in a browser using HTTP:

```text
http://<ALB_DNS_NAME>
```

The ASG instances install Apache HTTP Server through EC2 user data and serve a simple page containing the instance hostname.

The NLB is configured to accept TCP traffic on port 80 and forward it to its target group.

## Networking and Security

- The ALB and NLB are internet-facing and deployed across public subnets.
- The ASG instances are deployed in private subnets across two Availability Zones.
- The ALB security group allows inbound HTTP traffic on port 80.
- The ASG security group permits HTTP traffic according to its configured ingress rules.
- The private EC2 security group allows SSH from the public EC2 security group.
- The NAT Gateway provides a route for outbound internet access from private subnets.

**Security considerations:**

- Restrict SSH access to trusted IP addresses.
- Avoid unnecessarily broad ingress rules.
- Consider attaching a security group to the NLB and restricting backend access appropriately.
- Use HTTPS and TLS certificates for production deployments.
- Store AWS credentials securely and never commit secrets to Git.

## Cleanup

To remove the resources managed by this Terraform configuration, run:

```bash
terraform destroy
```

Review the proposed changes and confirm when prompted.

Ensure that any resources created outside Terraform are also removed if they are no longer needed. NAT Gateways and other networking resources can incur AWS charges while they exist.

## Learning Objectives

This project demonstrates practical experience with:

- Infrastructure as Code using Terraform.
- AWS networking and subnet design.
- Public and private EC2 deployments.
- Security group configuration.
- Application and Network Load Balancers.
- Auto Scaling Groups and Launch Templates.
- EC2 user-data automation.
- Terraform variables, outputs, dependencies, and resource references.

## Disclaimer

This project is intended for educational purposes. Review networking, access controls, availability requirements, and costs before using the configuration in a production environment.
