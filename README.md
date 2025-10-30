# End-to-End Deployment of a FullStack Blogging Application with AWS EKS, Terraform, Jenkins, SonarQube, Nexus, Trivy & Prometheus/Grafana

<img width="1346" height="716" alt="image" src="https://github.com/user-attachments/assets/06fb44f9-dfa1-436e-bd51-99bb933e1c7d" />


## Project Overview
This project demonstrates the end-to-end DevOps pipeline for deploying a FullStack Blogging Application using modern DevOps tools and practices.
It covers every stage — from source code management to deployment on Kubernetes (EKS) using CI/CD pipelines.

## Tech Stack

Frontend: React.js

Backend: Spring Boot (Java)

Database: MySQL

Containerization: Docker

Orchestration: Kubernetes (EKS)

CI/CD: Jenkins

Code Quality: SonarQube

Artifact Repository: Nexus

Security Scanning: Trivy

Infrastructure: Terraform + AWS

<img width="700" height="362" alt="image" src="https://github.com/user-attachments/assets/86630a1f-049d-47d1-ae99-b18fe0cb0654" />
<img width="700" height="362" alt="image" src="https://github.com/user-attachments/assets/33aad6f2-e4ad-4767-b9a9-5ff1c9d1e995" />


## Setup AWS EKS Cluster by Terraform

### **1. AWS CLI Installation**

Download and install AWS CLI to connect with AWS Cloud:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

**Expected Output:**

```
aws-cli/2.x.x Python/3.x.x Linux/...
```

---

### **2. Configure AWS CLI**

You need AWS credentials to use the CLI. Run:

```bash
aws configure
```

**Provide the following details when prompted:**

```
AWS Access Key ID: <Your Access Key>
AWS Secret Access Key: <Your Secret Key>
Default region name: ap-southeast-1
Default output format: json
```

---

### **3. Terraform Installation on Ubuntu**

#### **Method 1: Official APT Repository (Recommended for Production)**

```bash
# Install prerequisites
sudo apt install -y gnupg software-properties-common curl

# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add the official HashiCorp Linux repo
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Terraform
sudo apt update
sudo apt install terraform -y

# Verify installation
terraform -version
```

#### **Method 2: Using Snap (Quick Setup, Not Always the Latest Version)**

```bash
sudo snap install terraform --classic
```

---

### **4. Create EKS Cluster Using Terraform**

#### **Step 1: Create Terraform Project Folder**

```bash
mkdir -p ~/terraform-eks-vaishnavi
cd ~/terraform-eks-vaishnavi
```

#### **Step 2: Create the following files**

You can add your **EKS, VPC, Node Group** configurations in these files.

#### **Step 3: Initialize Terraform**

```bash
terraform init
```

#### **Step 4: Validate Configuration**

```bash
terraform validate
```

#### **Step 5: Preview and Apply**

```bash
terraform plan
terraform apply -auto-approve
```

#### **Step 6: View Outputs**

```bash
terraform output
```

---
<img width="936" height="621" alt="Screenshot 2025-10-30 150351" src="https://github.com/user-attachments/assets/dd5e59b1-03c1-4c1a-ba41-14c0aff39bd1" />

### **EKS Cluster Creation & Connection Guide**

---

### **1. Connect with EKS Cluster**

Once your EKS cluster is created using Terraform, connect it to your local system:

```bash
aws eks --region ap-southeast-1 update-kubeconfig --name vaishnavi-cluster
```

✅ This command updates your kubeconfig file to include the **EKS cluster context**, allowing `kubectl` to interact with it.

---

### **2. Install kubectl (Kubernetes CLI)**

If `kubectl` is not already installed, install it using Snap:

```bash
sudo snap install kubectl --classic
```

Verify the installation:

```bash
kubectl version --client
```

---

### **3. Check Cluster Nodes**

Once the connection is established, verify your EKS worker nodes:

```bash
kubectl get nodes
```

✅ You should see a list of your EKS nodes in **Ready** state.

---
<img width="700" height="358" alt="image" src="https://github.com/user-attachments/assets/b95fbaac-61fb-4adc-b4a3-a9de6fafc929" />


##  **Step 5: RBAC Setup (Master Node)**

We’ll create Kubernetes roles and service accounts with different access levels.

---

### ** Users and Roles**

| User   | Role   | Access Level            |
| ------ | ------ | ----------------------- |
| user-1 | role-1 | Cluster Admin           |
| user-2 | role-2 | Developer (Good Access) |
| user-3 | role-3 | Read-only Access        |

---

### **1️ Create RBAC Folder**

```bash
cd ..
mkdir rbac
cd rbac
```

---

### **2️ Create Namespace**

```bash
kubectl create ns webapps
```

---

### **3️ Create Service Account**

File: `svc.yaml`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: webapps
```

Apply:

```bash
kubectl apply -f svc.yaml
```

---

### **4️Create Role**

File: `role.yaml`

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: webapps
rules:
  - apiGroups:
        - ""
        - apps
        - autoscaling
        - batch
        - extensions
        - policy
        - rbac.authorization.k8s.io
    resources:
      - pods
      - secrets
      - componentstatuses
      - configmaps
      - daemonsets
      - deployments
      - events
      - endpoints
      - horizontalpodautoscalers
      - ingress
      - jobs
      - limitranges
      - namespaces
      - nodes
      - persistentvolumes
      - persistentvolumeclaims
      - resourcequotas
      - replicasets
      - replicationcontrollers
      - serviceaccounts
      - services
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

Apply:

```bash
kubectl apply -f role.yaml
```

---

### **5️ Bind Role to Service Account**

File: `bind.yaml`

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-rolebinding
  namespace: webapps 
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-role 
subjects:
- namespace: webapps 
  kind: ServiceAccount
  name: jenkins
```

Apply:

```bash
kubectl apply -f bind.yaml
```

---

### **6️ Create Secret for Service Account Token**

File: `sec.yaml`

```yaml
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: mysecretname
  annotations:
    kubernetes.io/service-account.name: jenkins
```

Apply:

```bash
kubectl apply -f sec.yaml -n webapps
```

Get token (for Jenkins integration):

```bash
kubectl describe secret mysecretname -n webapps
```

---

### **7️ Create Docker Registry Secret**

Use your DockerHub credentials — replace everything with **Vaishnavi’s details**:

```bash
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=vaishnavi \
  --docker-password=<your_dockerhub_password> \
  --docker-email=vaishnavi@gmail.com \
  --namespace=webapps
```

Verify:

```bash
kubectl get secret regcred --namespace=webapps --output=yaml
```

---

### **8️ Check kubeconfig**

```bash
cd ~/.kube
ls
cat config
```

Use the **server: IP** from the kubeconfig file if needed for Jenkins or deployment configuration.

---

##  **: SonarQube Server Setup**

For code quality analysis.

---

### **1️ Install Docker (Rootless Mode)**

```bash
sudo apt update
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install -y uidmap
dockerd-rootless-setuptool.sh install
```

---

### **2️⃣ Run SonarQube Container**

```bash
docker run -d --name Sonar -p 9000:9000 sonarqube:lts-community
```

Access at:

```
http://<server_ip>:9000/
```

**Default Login:**

```
Username: admin
Password: admin
```

---
<img width="941" height="545" alt="Screenshot 2025-10-30 145214" src="https://github.com/user-attachments/assets/77b4b277-b9ee-4f7e-9388-4cef87537a82" />

Step 3: Generate Authentication Token
Go to: **Administration > Security > Users > Tokens**

Create a new token:

Name: sonar-token
3. Click Generate and copy the token

Press enter or click to view image in full size

##  **2️ Nexus Repository Setup**

### **Step 1: Install Docker & Enable Rootless Mode**

```bash
sudo apt update
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install -y uidmap
dockerd-rootless-setuptool.sh install
```

This enables **Docker in rootless mode**, improving security by not running Docker as root.

---

### **Step 2: Run Nexus Repository Manager**

Run the official **Sonatype Nexus 3** container:

```bash
docker run -d --name Nexus -p 8081:8081 sonatype/nexus3
```

This will:

* Pull the latest Nexus 3 image
* Run it on **port 8081**
* Create the default data directory inside the container

---

### **Step 3: Retrieve the Nexus Admin Password**

List the running container:

```bash
docker ps
```

Get inside the container shell:

```bash
docker exec -it <container_id> sh
```

Retrieve the admin password:

```bash
cat sonatype-work/nexus3/admin.password
```

---

### **Step 4: Access Nexus Dashboard**

Open your browser and go to:

```
http://<your_server_ip>:8081/
```

**Default Credentials:**

```
Username: admin
Password: (copy from the admin.password file)
```

---

### **Step 5: Post-Login Setup**

 Go through the initial setup wizard
 (Optional) Enable **Anonymous Access** — useful for testing or open-read setups
 Confirm that these repositories exist:

* **maven-releases**
* **maven-snapshots**

You can copy their URLs — they’ll be used later in your Maven `pom.xml` and Jenkins pipeline for publishing artifacts.

---

 **Tip:**
If Nexus restarts frequently or doesn’t retain data, mount a persistent volume:

```bash
docker run -d --name Nexus -p 8081:8081 -v /opt/nexus-data:/nexus-data sonatype/nexus3
```

---

<img width="700" height="176" alt="image" src="https://github.com/user-attachments/assets/09e75bd0-4fde-4f6a-bf00-4cef1aa97d52" />


##  **Step 4: Update Maven `pom.xml`**

Add your **Nexus repository URLs** under `<distributionManagement>`:

```xml
<distributionManagement>
    <repository>
        <id>maven-releases</id>
        <url>http://13.212.202.251:8081/repository/maven-releases/</url>
    </repository>
    <snapshotRepository>
        <id>maven-snapshots</id>
        <url>http://13.212.202.251:8081/repository/maven-snapshots/</url>
    </snapshotRepository>
</distributionManagement>
```

---

##  **3️ Jenkins Server Setup (CI/CD Pipeline with SonarQube, Nexus, Docker & K8s)**

### **Step 1: Install Docker (Rootless Mode)**

```bash
sudo apt update
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install -y uidmap
dockerd-rootless-setuptool.sh install
docker --version
```

---

### **Step 2: Install Trivy (Security Scanner)**

```bash
vim trivy.sh
```

Paste:

```bash
#!/bin/bash
sudo apt-get install wget gnupg -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install trivy -y
```

Run:

```bash
chmod +x trivy.sh && ./trivy.sh
trivy --version
```

---

### **Step 3: Install Jenkins**

```bash
vim jenkin.sh
```

Paste:

```bash
#!/bin/bash
sudo apt install openjdk-17-jre-headless -y
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y
```

Run:

```bash
chmod +x jenkin.sh && ./jenkin.sh
```

Access Jenkins:

```
http://<server_ip>:8080
```

Get initial password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

<img width="700" height="646" alt="image" src="https://github.com/user-attachments/assets/12337261-c365-4dfa-97e1-c5b8e1fd9c20" />

<img width="700" height="646" alt="image" src="https://github.com/user-attachments/assets/0874bddd-6e48-486b-b1b6-dfd1c1214701" />

<img width="700" height="646" alt="image" src="https://github.com/user-attachments/assets/3577b648-fe39-428f-ab7b-c07683458cf0" />

<img width="700" height="646" alt="image" src="https://github.com/user-attachments/assets/8ca680ee-763a-4024-95fc-b8555f7b2c85" />

##  **Step 4: Install kubectl on Jenkins Server**

Create script:

```bash
vi kubelet.sh
```

Paste:

```bash
#!/bin/bash
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
kubectl version --short --client
```

Run it:

```bash
chmod +x kubelet.sh
./kubelet.sh
```

---

##  **Step 5: Add Jenkins to Docker Group**

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

---

##  **Step 6: Jenkins Configuration**

Go to:
**Dashboard → Manage Jenkins → Plugins → Available Plugins**

###  Install the following plugins:

* Docker
* Docker Pipeline
* Kubernetes
* Kubernetes CLI
* Kubernetes Client API
* Kubernetes Credentials
* Prometheus Metrics
* Pipeline: Stage View
* Pipeline Maven Integration
* Maven Integration
* SonarQube Scanner
* Config File Provider
* Eclipse Temurin Installer

 **Restart Jenkins** after plugin installation.

### **Step 7: Global Tool Configuration**

**Path:**
`Dashboard → Manage Jenkins → Tools`

#### **JDK**

* **Name:** `jdk17`
* **Install automatically:** 
* **Source:** `Adoptium.net`
* **Version:** `jdk-17.0.9+9`

#### **SonarQube Scanner**

* **Name:** `sonar-scanner`
* **Version:** `latest`

#### **Maven**

* **Name:** `maven3`
* **Version:** `3.6.1`

#### **Docker**

* **Name:** `docker`
* **Install automatically:** 

---

### **Step 8: Add Required Credentials**

**Path:**
`Manage Jenkins → Credentials → System → Global → Add Credentials`

| **Type**            | **ID**        | **Username / Secret**                                                 | **Description**                  |
| ------------------- | ------------- | --------------------------------------------------------------------- | -------------------------------- |
| Username & Password | `git-cred`    | GitHub username + token                                               | Git credentials                  |
| Secret Text         | `sonar-token` | SonarQube token                                                       | SonarQube access                 |
| Username & Password | `docker-cred` | DockerHub username + password                                         | DockerHub credentials            |
| Secret Text         | `k8-cred`     | K8s cluster token (`kubectl describe secret mysecretname -n webapps`) | Kubernetes cluster access        |
| Username & Password | `mail-cred`   | Gmail + App Password                                                  | Jenkins email notification setup |

---

### **Step 9: Add Global Maven Settings for Nexus**

**Path:**
`Manage Jenkins → Managed Files → Add a New Config`

* **Type:** `Global Maven settings.xml`
* **ID:** `global-settings`

**Paste the following content:**

```xml
<settings>
  <servers>
    <server>
      <id>maven-releases</id>
      <username>nexus_username</username>
      <password>nexus_password</password>
    </server>
    <server>
      <id>maven-snapshots</id>
      <username>nexus_username</username>
      <password>nexus_password</password>
    </server>
  </servers>
</settings>
```

---

### **Step 10: Configure SonarQube Server**

**Path:**
`Manage Jenkins → System → SonarQube Servers`

* **Name:** `sonar`
* **Server URL:** `http://<sonar_server_ip>:9000`
  *(Example: [http://54.169.71.209:9000](http://54.169.71.209:9000))*
* **Token:** `sonar-token` (select from credentials)

---

### **Step 11: Create a New Pipeline Job**

#### **Create Job**

1. Go to **Jenkins Dashboard**
2. Click **New Item**
3. Enter **Job Name:** `BoardGame`
4. Select **Pipeline**
5. Click **OK**

#### **Basic Configuration**

* **Discard Old Builds:** Max builds = `2`
* **Pipeline Definition:** `Pipeline script`

Sample Pipeline:

```groovy
pipeline {
    agent any
    stages {
        stage('Hello') {
            steps {
                echo 'Hello World'
            }
        }
    }
}
```

---

### **Pipeline Syntax Reference**

#### **Git Checkout**

```groovy
git branch: 'main', credentialsId: 'git-cred', url: 'https://github.com/abrahimcse/Boardgame.git'
```

#### **SonarQube Environment**

```groovy
withSonarQubeEnv(credentialsId: 'sonar-token') {
    // sonar analysis steps
}
```

---

### **Jenkins CI/CD Pipeline Flow**

```
Git Checkout 
   ↓
Compile 
   ↓
Unit Test 
   ↓
Trivy Security Scan 
   ↓
SonarQube Code Analysis 
   ↓
Quality Gate Check 
   ↓
Build JAR 
   ↓
Deploy to Nexus 
   ↓
Build Docker Image 
   ↓
Push to DockerHub 
   ↓
Deploy to Kubernetes 
   ↓
Verify Deployment
```

---
<img width="700" height="367" alt="image" src="https://github.com/user-attachments/assets/0d3d56f9-3f1d-45a6-845d-5bc37905b03f" />



