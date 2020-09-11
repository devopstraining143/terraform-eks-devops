# Terraform - Provision an EKS Cluster
Creating Kubernetes Cluster using AWS EKS service. We will create Jenkins & Jenkins JNLP Agent docker images and will deploy into EKS nodes. Jenkins JNLP Agent images will be configured as Jenkins Cloud Nodes for build and deploy. This setup helps to achieve Jenkins Master Slave deployments.

- First setup the Terraform
- Install and setup the AWS CLI
- Update provider.tf with new aws cli profile, OR  
  Setup below variables in environment  
  AWS_ACCESS_KEY_ID  
  AWS_SECRET_ACCESS_KEY  
  AWS_DEFAULT_REGION  
  
#### Run Terraform commands

```bash
terraform init
terraform fmt
terraform validate
terraform plan --auto-approve
terraform apply --auto-approve
terraform output
```  

#### Setup Tools
Install kubectl > https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html

Setup AWS IAM Authenticator > https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html

Setup kubeconfig > https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html

Setup kubectl for newly created EKS cluster using below command

```bash
aws eks --region us-east-2 update-kubeconfig --name devopstools-EKS-Cluster --profile awsprofilename
```

#### Kubectl commands 

```bash
kubectl get nodes
kubectl get pods 
kubectl get deployments
kubectl get all
```
Install the EFS Drivers in EKS Cluster. (https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html)

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
```

Terraform will create EFS in AWS, we are going to use in Jenkins/Agents pods. As we are going to create & destroy pods we are going to use EFS/Elastic File system to persist all Jenkins configurations.

Find EFS ID from Terraform Output and update file, jenkins-setup -> jenkins-main.yaml. (Search for #TODO)

Go to AWS Console EFS and configure Manage Network Access. Select the desired VPC, Subnets with Security group. We need Security Group with NFS port and source as EKS VPC cidr and attached the SG to your cluster, Node groups and EFS. This is required for EFS to connect with K8 Nodes/EC2s.

Now, create Jenkins Server using below command

```bash
kubectl apply -f jenkins-setup/set-default-mem-cpu.yaml  
kubectl apply -f jenkins-setup/jenkins-main.yaml  
```

How to access Jenkins Server inside private subnet?

```bash
kubectl expose deployment jenkins --type=LoadBalancer --name=jenkins-external
```

How to do Port Fowarding?

```bash
kubectl port-forward jenkins-pod  7000:8080
```

Jenkins How to Disable CSRF? Go to -  "Manage Jenkins" / "Script Console"

```bash
import jenkins.model.Jenkins
def instance = Jenkins.instance
instance.setCrumbIssuer(null)
```

Other Commands

```bash
kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts

eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster nextgen-sandbox-EKS-Cluster --approve --profile awsprofilename
```
#### Setup Jenkins

- Create Credentials for GitHub access. Go to Jenkins -> Credentials.

  Note ID of credentials which will be used in Jenkins pipeline to chekcout code for build & deploy

- Setup Jenkin Agent nodes using Kuberenets. Go to Jenkins -> Configure Clouds.

  Add New Cloud and choose Kuberenets.
  
    | Kubernetes Lables | Values |
    |---|---|
    | Name            | kubernetes | 
    | Kubernetes URL  | https://D3B91C88541FE906FAE014C758A35F89.gr7.us-east-2.eks.amazonaws.com|  
    | Pod Lables      | Key: jenkins, Value: slave |    
    | Node Selector   | NodeGroupName=devopstools-EKS-Cluster-NG-2 | 
    | Workspace Volume| Empty Dir Workspace Volume | 

    | Add Container   | Values  |
    |---|---|
    | Name               | jnlp  |
    | Docker Image       | devopstraining143/custom-jenkins-jnlp   |
    | Usage              | Use this node as much as possible  |
    | Working Directory  | /home/jenkins/agent | 
    | Allocate pseudo-TTY| Yes | 
    | Request CPU        | 1.5 |
    | Request Memory     | 1.5Gi |
    | Limit CPU          | 3 | 
    | Limit Memory       | 3Gi |  
    
    | Volumes    | Values |
    |---|---|
    | Host Path  | /run/docker.sock |  
    | Mount Path | /var/run/docker.sock |    
      
  
#### (Optional) Modifying Jenkins Master & Agent docker images.

- Current Master/Agent Jenkins docker images containes Maven, Unzip, Git, Terraform and AWS CLI.

```bash
docker build -f 1-Dockerfile-jenkins -t custom-jenkins .
docker build -f 1-Dockerfile-jenkins -t devopstraining143/custom-jenkins:2.236 .
docker tag custom-jenkins devopstraining143/custom-jenkins:2.236
docker push devopstraining143/custom-jenkins:2.236
```
##### Jenkins Slave/Agent with JNLP
```bash
docker build -f 2-Dockerfile-JNLP -t devopstraining143/custom-jenkins-jnlp .
docker tag custom-jenkins-jnlp devopstraining143/custom-jenkins-jnlp
docker push devopstraining143/custom-jenkins-jnlp
```  

#### How to push to AWS ECR?

```bash
aws ecr get-login --registry-ids 551587375342 --no-include-email --region us-east-1 --profile -awsprofilename-

Above command will return AWS login to docker command to run now.

docker tag custom-jenkins:latest 551587375342.dkr.ecr.us-east-1.amazonaws.com/custom-jenkins:latest
docker push 551587375342.dkr.ecr.us-east-1.amazonaws.com/custom-jenkins:latest
```


### How to execute kubectl commands from Terraform?

- Refer website: https://gavinbunney.github.io/terraform-provider-kubectl/docs/provider
- For windows download 'terraform-provider-kubectl-windows-386.exe' from website: https://github.com/gavinbunney/terraform-provider-kubectl/releases/tag/v1.5.0
- Rename the file to 'terraform-provider-kubectl.exe' and paste to directory '.terraform/plugins/windows_amd64/'.




##### Ref
- https://dzone.com/articles/dockerizing-jenkins-2-setup-and-using-it-along-wit  


