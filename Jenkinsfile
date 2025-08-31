pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['create', 'destroy'],
            description: 'Select whether to CREATE or DESTROY resources'
        )
    }

    stages {
        stage('Checkout Terraform Code') {
            steps {
                git branch: 'terraform', credentialsId: 'git-token', url: 'https://github.com/Rahul-Kumar-Paswan/k8s-testing.git'
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    file(credentialsId: 'dev-tfvars', variable: 'TFVARS_FILE'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']
                ]) {
                    sh '''
                        terraform init
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'create' }
            }
            steps {
                withCredentials([
                    file(credentialsId: 'dev-tfvars', variable: 'TFVARS_FILE'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']
                ]) {
                    sh '''
                        terraform plan -var-file=$TFVARS_FILE
                        terraform apply -auto-approve -var-file=$TFVARS_FILE
                    '''
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                withCredentials([
                    file(credentialsId: 'dev-tfvars', variable: 'TFVARS_FILE'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']
                ]) {
                    sh '''
                        terraform plan -destroy -var-file=$TFVARS_FILE
                        terraform destroy -auto-approve -var-file=$TFVARS_FILE
                    '''
                }
            }
        }

        stage('Terraform Outputs') {
            steps {
                withCredentials([
                    file(credentialsId: 'dev-tfvars', variable: 'TFVARS_FILE'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']
                ]) {
                    sh '''
                        echo "==== Final Terraform Outputs for ACTION=$ACTION ===="
                        terraform output || echo "No outputs available (resources may be destroyed)"
                    '''
                }
            }
        }
    }
}
