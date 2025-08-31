pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    stages {
        stage('Checkout Terraform Code') {
            steps {
                git branch: 'Jenkins', credentialsId: 'git-token', url: 'https://github.com/Rahul-Kumar-Paswan/k8s-testing.git'
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([file(credentialsId: 'dev-tfvars', variable: 'TFVARS_FILE')]) {
                    sh '''
                        terraform init
                        terraform plan -var-file=$TFVARS_FILE
                        terraform apply -auto-approve -var-file=$TFVARS_FILE
                    '''
                }
            }
        }

        stage('Export EKS Info') {
            steps {
                script {
                    env.K8S_CLUSTER_URL = sh(script: "terraform output -raw eks_cluster_endpoint", returnStdout: true).trim()
                    env.K8S_CLUSTER_CA  = sh(script: "terraform output -raw eks_cluster_ca", returnStdout: true).trim()
                }
            }
        }
    }
}
