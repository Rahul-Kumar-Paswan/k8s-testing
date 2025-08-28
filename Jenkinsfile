pipeline {
    agent any

    tools {
        maven 'maven3'
    }

    environment {
        DOCKER_REGISTRY = "rahulkumarpaswan"
        APP_NAME = "rahulverse-app"
        K8S_NAMESPACE = "rahulverse-prod"
        K8S_CLUSTER_NAME = "rahulverse-cluster"
        AWS_REGION = "ap-south-1"
        BUILD_TAG = "${env.BUILD_NUMBER}"
        NEXUS_REPO = "http://nexus.example.com/repository/maven-releases/"
        SLACK_CHANNEL = "#devops-notifications"
        SCANNER_HOME = tool 'sonar-scanner'
    }

    options {
        skipStagesAfterUnstable()
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '2'))
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'Jenkins', credentialsId: 'git-token', url: 'https://github.com/Rahul-Kumar-Paswan/k8s-testing.git'
            }
        }

        stage('Code Compilation') {
            steps {
                echo "Building Java app"
                sh 'mvn clean compile -B -DskipTests'
            }
        }

        stage('Unit & Integration Tests') {
            steps {
                sh 'mvn test -B'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Security Scan - Gitleaks') {
            steps {
                sh 'gitleaks detect --source=. --report-format=json --report-path=gitleaks-report.json || true'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh """ $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=rahulverse-Project \
                            -Dsonar.projectKey=rahulverse-Project """
                }
            }
        }

        stage('Quality Gate Check') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh """
                    trivy fs --format table -o fs-report.html --exit-code 1 --severity HIGH,CRITICAL .
                """
            }
        }

        stage('Build Artifact & Push to Nexus') {
            steps {
                sh """
                    mvn clean package -DskipTests
                    curl -v -u $NEXUS_USER:$NEXUS_PASSWORD --upload-file target/rahulverse-0.0.1-SNAPSHOT.jar ${NEXUS_REPO}rahulverse-${BUILD_TAG}.jar
                """
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    def imageTag = "${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_TAG}"
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh """
                            docker build -t ${imageTag} .
                            trivy image --format table -o ${APP_NAME}-image-report.html ${imageTag}
                            docker push ${imageTag}
                        """
                        env.IMAGE_TAG = imageTag
                    }
                }
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    input message: 'Approve deployment to PRODUCTION?', ok: 'Deploy'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withKubeConfig(caCertificate: '', clusterName: "${K8S_CLUSTER_NAME}", contextName: '', credentialsId: 'k8s-token', namespace: "${K8S_NAMESPACE}", restrictKubeConfigAccess: false, serverUrl: 'https://30E5A6EE0382334F98E30C0BD1A339D8.gr7.ap-south-1.eks.amazonaws.com') {
                        sh """
                            aws eks update-kubeconfig --region ${AWS_REGION} --name ${K8S_CLUSTER_NAME}
                            kubectl set image deployment/${APP_NAME} ${APP_NAME}=${IMAGE_TAG} -n ${K8S_NAMESPACE}
                            kubectl apply -f K8s-Manifests/configmap.yaml -n $K8S_NAMESPACE
                            kubectl apply -f K8s-Manifests/secrets.yaml -n $K8S_NAMESPACE
                            kubectl apply -f K8s-Manifests/mysql-deploy.yaml -n $K8S_NAMESPACE
                            kubectl apply -f K8s-Manifests/app-deploy.yaml -n $K8S_NAMESPACE
                            kubectl apply -f K8s-Manifests/ingress.yaml -n ${K8S_NAMESPACE}
                            kubectl rollout status deployment/${APP_NAME} -n ${K8S_NAMESPACE} --timeout=120s
                        """
                    }
                }
            }
        }

        stage('Post-Deployment Verification') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: "${K8S_CLUSTER_NAME}", contextName: '', credentialsId: 'k8s-token', namespace: "${K8S_NAMESPACE}", restrictKubeConfigAccess: false, serverUrl: 'https://30E5A6EE0382334F98E30C0BD1A339D8.gr7.ap-south-1.eks.amazonaws.com') {
                    sh """
                        kubectl get pods -n ${K8S_NAMESPACE}
                        kubectl get ingress -n ${K8S_NAMESPACE}
                        EXTERNAL_IP=$(kubectl get svc rahulverse-app -n $K8S_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                        curl -f http://$EXTERNAL_IP/actuator/health || exit 1
                    """
                }
            }
        }
    }

    post {
        success {
            slackSend(channel: "${SLACK_CHANNEL}", color: 'good', message: "✅ Build #${BUILD_NUMBER} deployed successfully: ${IMAGE_TAG}")
        }
        failure {
            slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "❌ Build #${BUILD_NUMBER} failed.")
        }
        always {
            cleanWs()
        }
    }
}
