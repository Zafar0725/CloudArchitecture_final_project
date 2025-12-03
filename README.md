# Final Individual Project – AWS Infrastructure as Code

**Name:** Zafar Ahmed  
**Student ID:** 9027671  
**Tools Used:** Terraform & AWS CloudFormation  
**Cloud Provider:** AWS (us-east-1)

---

## 📍 Project Summary

This project automates the deployment of a secure cloud infrastructure using **Infrastructure as Code (IaC).**  
Two automation tools were used:

| IaC Tool | Resources Deployed |
|---------|------------------|
| Terraform | 4 S3 Buckets, VPC + Subnet + EC2, RDS MySQL |
| CloudFormation | 3 S3 Buckets, VPC + EC2, RDS MySQL |

All resources are deployed automatically **without manual configuration**.

---

## ⚙️ Terraform Infrastructure

✔ 4 Private S3 Buckets  
✔ Versioning enabled  
✔ Public access blocked  
✔ Custom VPC with CIDR `10.0.0.0/16`  
✔ Public Subnet + Internet Gateway + Route table  
✔ EC2 Instance (`t3.micro`)  
✔ SSH allowed only from my IP: `99.251.70.231/32`  
✔ RDS MySQL (`db.t3.micro`, MySQL 8.0)  
✔ DB subnet group with 2 private subnets  
✔ RDS MySQL port **3306** restricted to **my IP**

Terraform Structure
terraform/
├── main.tf
├── variables.tf
├── provider.tf
├── backend.tf
├── terraform.tfvars (ignored for security)

📦 CloudFormation Infrastructure

Three separate stacks were deployed:

Stack Name	Template File	Output Provided
zafar-s3-stack	cf-s3.yaml	S3 Bucket names
zafar-ec2-stack	cf-ec2.yaml	EC2 Public IP
zafar-rds-stack	cf-rds.yaml	RDS Endpoint

CloudFormation Folder Structure
cloudformation/
├── cf-s3.yaml
├── cf-ec2.yaml
└── cf-rds.yaml

📁 Overall Repository Structure
final_infra_project/
├── terraform/
├── cloudformation/
└── README.md


### Commands Executed

```bash
terraform init
terraform plan
terraform apply

🧹 Cleanup Steps
terraform destroy

