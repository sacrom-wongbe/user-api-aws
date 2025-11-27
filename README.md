# **user-api-aws**

A fully serverless, AWS-native user routing API designed to capture website interaction data, persist user profiles, and power downstream recommender systems. Built with **Terraform**, **API Gateway**, **Lambda**, and **DynamoDB**, with automated CI/CD and secure HMAC-based request authorization.

---

## **📌 Overview**

This project implements a scalable backend API layer for collecting and serving user events, item events, and profile data from a website. The system is designed to act as the **data backbone for personalization pipelines**, recommendation engines, or behavioral analytics tools.

Infrastructure is defined entirely in **Terraform**, enabling repeatable provisioning of:

* API Gateway endpoints
* Lambda compute functions (Python)
* DynamoDB storage tables
* IAM roles/policies
* Custom HMAC-based request authorizer
* CI/CD automation for infrastructure updates

The API is optimized for:

* **Low-latency user logging**
* **High-throughput event ingestion**
* **ML-ready structured storage**
* **Modular endpoints supporting future model integration**

---

## **✨ Key Features**

### 🗄️ **Serverless Data API for ML/Recommenders**

* Captures **user logs**, **item logs**, and **user profile updates**
* All data routed through API Gateway → Lambda → DynamoDB
* Events stored in ML-friendly JSON structures for downstream pipelines

### 🔒 **Secure HMAC Authorization**

* Custom Lambda authorizer verifies HMAC signatures
* Protects write endpoints from spoofed or unauthorized traffic
* Enables secure client → API integration without OAuth complexity

### 🧱 **Modular Endpoints**

* `/interactions` – user activity + UX events
* `/item` – item/view/click events
* `/user` – store or update user metadata
* Each endpoint backed by its own Lambda function for isolation and scaling

### ☁️ **Terraform Infrastructure-as-Code**

* 100% IaC for reproducibility
* Modules include:

  * DynamoDB tables
  * Lambda packaging + permissions
  * API Gateway with stages + HMAC authorizer
  * CI/CD pipeline triggers
* Designed to stand up a full API stack with a single `terraform apply`

### ⚙️ **CI/CD Pipeline**

* Auto-deploys Terraform changes on push
* Ensures infrastructure updates stay consistent across environments
* Useful for demo environments, experimentation, and team workflows

---

## **🛠️ Tech Stack**

**Infrastructure:** Terraform, AWS API Gateway, AWS Lambda, DynamoDB, IAM
**Compute:** Python (Lambda handlers)
**Security:** HMAC custom authorizer
**CI/CD:** GitHub Actions (or your chosen provider)
**Format:** JSON event payloads

---

## **🧠 Use Cases**

This API can serve as the backbone for:

* **Recommender systems** (collaborative filtering, content-based, hybrid)
* **User behavior analytics**
* **Real-time personalization engines**
* **Marketing attribution pipelines**
* **Product experimentation platforms (A/B testing logs)**

DynamoDB’s structure supports:

* High-volume write patterns
* Low-latency user lookups
* Partition keys optimized for per-user or per-item queries

---

## **🚀 Getting Started**

### **Deploy Infrastructure**

```bash
cd infra/
terraform init
terraform apply
```

### **CI/CD**

* Commit/push → GitHub Actions automatically runs and applies Terraform changes
* Ensures infrastructure state stays in sync across environments

---

## **📈 Future Extensions**

* Add Kinesis or Firehose for large-scale event streaming
* Implement full recommendation inference Lambdas
* Integrate Feature Store (SageMaker Feature Store or DynamoDB global tables)
* Add API versioning + environment promotion (dev → staging → prod)

---
