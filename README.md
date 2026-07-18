# bluegreen-deployment
Project Architecture
Developer
     │
     ▼
 GitHub Repository
     │
     ▼
 Jenkins Pipeline
     │
     ├── Build Node.js App
     ├── Run Tests
     ├── Build Docker Image
     ├── Push Image to DockerHub/ECR
     └── Helm Upgrade
                │
                ▼
         AWS EKS Cluster
                │
      ┌─────────┴─────────┐
      │                   │
 Blue Deployment     Green Deployment
      │                   │
      └─────────┬─────────┘
                │
          Kubernetes Service
                │
          AWS Load Balancer
________________________________________
Folder Structure
blue-green-eks/
│
├── terraform/
│   ├── provider.tf
│   ├── versions.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── iam.tf
│   ├── eks.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── app/
│   ├── server.js
│   ├── package.json
│   ├── Dockerfile
│   └── Jenkinsfile
│
├── helm/
│   └── blue-green-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│            ├── blue-deployment.yaml
│            ├── green-deployment.yaml
│            ├── service.yaml
│            ├── ingress.yaml
│            └── _helpers.tpl
│
├── README.md
└── screenshots/
________________________________________
Phase 1 — Build Node.js Application
Step 1
Create simple Express application.
mkdir app
cd app
npm init -y
npm install express
server.js
const express = require("express");

const app = express();

const version = process.env.APP_VERSION || "blue";

app.get("/", (req,res)=>{
    res.send(`Application Version : ${version}`);
});

app.listen(3000,()=>{
    console.log("Server Running");
});
________________________________________
Step 2
Create Dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["node","server.js"]
________________________________________
Step 3
Test
docker build -t bluegreen:v1 .

docker run -p 3000:3000 bluegreen:v1
________________________________________
Phase 2 — Terraform Infrastructure
Terraform creates
•	VPC 
•	Internet Gateway 
•	NAT Gateway 
•	Public Subnets 
•	Private Subnets 
•	Route Tables 
•	IAM Roles 
•	EKS Cluster 
•	Managed Node Group 
________________________________________
Commands
cd terraform

terraform init

terraform validate

terraform fmt

terraform plan

terraform apply -auto-approve



<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/dc79ba4e-c48b-461b-afae-2ec5e36e7dca" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/84ec7f80-a95e-432a-a951-d172692219f8" />
Update kubeconfig
aws eks update-kubeconfig \
--region ap-south-1 \
--name bluegreen-cluster
Check
kubectl get nodes

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/157b61c9-f7f6-444b-9aaf-b57a5808bc4e" />

Phase 3 — Install Required Components
Install Helm
helm version
________________________________________
Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
________________________________________
Install AWS Load Balancer Controller
Associate IAM
eksctl utils associate-iam-oidc-provider \
--cluster bluegreen-cluster \
--approve
Create IAM Policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
Create policy
aws iam create-policy \
--policy-name AWSLoadBalancerControllerIAMPolicy \
--policy-document file://iam_policy.json
Create Service Account
eksctl create iamserviceaccount \
--cluster bluegreen-cluster \
--namespace kube-system \
--name aws-load-balancer-controller \
--attach-policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
--approve
Install controller
helm repo add eks https://aws.github.io/eks-charts

helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=bluegreen-cluster
________________________________________
Phase 4 — Helm Blue Green
Helm chart contains
blue deployment
green deployment
service
ingress
helm install bluegreen ./helm/blue-green-app
kubectl get pods
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/4ee4df85-a17f-440f-8ea2-3aa33ddc5238" />

Kubectl get svc

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/67730b87-0ca1-422d-8cd1-ec7c0c8b44a8" />

Kubectl describe svc bluegreen

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/bda9f6f2-e6b9-48a2-b689-e60464fc1dfd" />


Switch Traffic to Green
Update the Helm value:
helm upgrade bluegreen ./helm/blue-green-app \
  --set activeColor=green

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/1cd9fd05-aae2-4bb2-beec-51e05b2d4908" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/59f3be75-c4ca-410f-a574-115e5b98840a" />

Roll Back to Blue

helm upgrade bluegreen ./helm/blue-green-app   --set activeColor=blue
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/d7021455-e927-4938-bba0-79398fcb1eb6" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/9c24ef48-661c-4280-b1e5-c20d04d851f5" />

Phase 5 — Jenkins Installation
Launching an ec2 instance
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/59f38fd6-d5b5-4fbe-afaa-7b52be5bed26" />


Jenkins configuration:
1. Update System
sudo apt update && sudo apt upgrade -y

2. Install Git
sudo apt install git -y
Verify:
git --version

3. Install Python3
sudo apt install python3 python3-pip python3-venv -y
Verify:
python3 --version
pip3 --version

4. Install Docker
sudo apt install docker.io -y

sudo systemctl enable docker

sudo systemctl start docker

sudo usermod -aG docker $USER
Apply the group change:
newgrp docker
Verify:
docker --version
________________________________________
5. Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
Verify:
aws --version
________________________________________
6. Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

Verify:
kubectl version --client

7. Install Trivy
sudo apt install wget gnupg lsb-release apt-transport-https -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt update

sudo apt install trivy -y
Verify:
trivy --version

8. Install Terraform (Optional)
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update

sudo apt install terraform -y
Verify:
terraform version

9. Configure AWS CLI
aws configure
Enter:
AWS Access Key ID
AWS Secret Access Key
Region: ap-south-1
Output: json
Verify:
aws sts get-caller-identity

10. Connect to EKS
aws eks update-kubeconfig --region ap-south-1 --name bluegreen-eks-cluster
Verify:
kubectl get nodes
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/180a8d94-4c21-4951-85f9-338a8322ccf2" />

11 Jenkins installation
sudo apt update
sudo apt install fontconfig openjdk-21-jre
java -version

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins
sudo usermod -aG docker jenkins

sudo systemctl restart jenkins

sudo systemctl restart docker

12. Helm installation
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

Phase 6 — Jenkins Pipeline
Pipeline
Checkout

↓

Install dependencies

↓

Run Tests

↓

Docker Build

↓

Docker Push

↓

Update values.yaml

↓

helm upgrade

↓

Verify rollout

↓

Switch Service

↓

Cleanup





pipeline {

    agent any

    environment {

        AWS_REGION = "ap-south-1"

        CLUSTER_NAME = "bluegreen-eks-cluster"

        ECR_REPO = "254292659362.dkr.ecr.ap-south-1.amazonaws.com/node-app"

        HELM_RELEASE = "bluegreen"

        HELM_CHART = "./helm/blue-green-app"

        IMAGE_TAG = "blue"
    }

    stages {

        stage('Checkout') {

            steps {

                git branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/saiyedin786/bluegreen-deployment.git'
            }
        }

        stage('Build Docker Image') {

            steps {

                sh '''
                docker build -t $ECR_REPO:$IMAGE_TAG ./app
                '''
            }
        }

        stage('Login to Amazon ECR') {

            steps {

                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds']
                ]) {

                    sh '''
                    aws ecr get-login-password \
                    --region $AWS_REGION | \
                    docker login \
                    --username AWS \
                    --password-stdin $ECR_REPO
                    '''
                }
            }
        }

        stage('Push Docker Image') {

            steps {

                sh '''
                docker push $ECR_REPO:$IMAGE_TAG
                '''
            }
        }

        stage('Configure kubectl') {

            steps {

                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds']
                ]) {

                    sh '''
                    aws eks update-kubeconfig \
                    --region $AWS_REGION \
                    --name $CLUSTER_NAME
                    '''
                }
            }
        }

     stage('Deploy Green') {
    steps {
        withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-creds'
        ]]) {
            sh '''
            aws eks update-kubeconfig \
              --region ap-south-1 \
              --name bluegreen-eks-cluster

            helm upgrade --install bluegreen \
              ./helm/blue-green-app \
              --set image.greenTag=blue \
              --set activeColor=green
            '''
        }
    }
}

      stage('Wait for Rollout') {
    steps {
        withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-creds'
        ]]) {
            sh '''
            aws eks update-kubeconfig --region ap-south-1 --name bluegreen-eks-cluster
            kubectl rollout status deployment/bluegreen-green
            '''
        }
    }
}

        stage('Health Check') {
    steps {
        withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-creds'
        ]]) {
            sh '''
            aws eks update-kubeconfig --region ap-south-1 --name bluegreen-eks-cluster
            kubectl get pods
            '''
        }
    }
}

       stage('Switch Traffic') {
    steps {
        withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-creds'
        ]]) {
            sh '''
            aws eks update-kubeconfig --region ap-south-1 --name bluegreen-eks-cluster
            helm upgrade bluegreen ./helm/blue-green-app --set activeColor=green
            '''
        }
    }
}

    }

    post {
    failure {
        withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-creds'
        ]]) {
            sh '''
            aws eks update-kubeconfig --region ap-south-1 --name bluegreen-eks-cluster
            helm rollback bluegreen || true
            '''
        }
    }
}

}

















