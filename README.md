# Final Individual Project – Infrastructure as Code (AWS)

**Student:** Shaik Zafar Ahmed  
**Student ID:** 9027671  
**Project:** Comprehensive AWS Infrastructure using Terraform & CloudFormation  
**Region:** us-east-1 (N. Virginia)  
**Tools Used:** Terraform, AWS CloudFormation, AWS Console

---

## 🎯 Project Objective

The objective of this project is to provision a full cloud architecture on AWS using two different IaC tools:

- **Terraform** (main deployment automation)
- **AWS CloudFormation** (secondary deployment validation)

The design follows industry best practices:
- Infrastructure must be fully **automated**
- Networking and security must be **properly configured**
- No sensitive info committed to version control
- Resources must be **easily reproducible and deletable**

---

## 🏗️ Infrastructure Architecture (High-Level)

                +-------------------+
                |  S3 Buckets       |
                | (Terraform)       |
                +-------------------+

                +-------------------------+
Internet  --->  |  EC2 Instance in VPC    |
                |  Public Subnet + IGW    |
                |  SSH only from my IP    |
                +-------------------------+

                +-------------------------+
                |  MySQL RDS Database     |
                |  Private Subnets        |
                |  SG: My IP only (3306)  |
                +-------------------------+

Each of the above layers is recreated once again using CloudFormation to demonstrate tool-agility.

---

## ⚙️ Terraform Implementation

✔ 4 Private S3 Buckets  
✔ Versioning Enabled  
✔ Public Access Block Enabled  
✔ Custom VPC (10.0.0.0/16) with public subnet  
✔ Internet Gateway + Route Table  
✔ EC2 Instance (t3.micro) in Public Subnet  
✔ Security Group – SSH only from my IP (`99.251.70.231/32`)  
✔ Two DB subnets + Subnet Group  
✔ MySQL RDS (`db.t3.micro`, MySQL 8.0) with SG access only from my IP  
✔ Used **variables.tf** and **terraform.tfvars** (dynamic configuration)  
✔ **Local backend** state management (per rubric)

### Terraform Execution Commands

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

🧹 Cleanup Steps
terraform destroy

