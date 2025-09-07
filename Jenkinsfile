pipeline {
    agent any

    tools {
        maven 'maven3'
    }

    environment {
        DOCKER_REGISTRY = "rahulkumarpaswan"
        APP_NAME = "rahulverse-app"
        K8S_NAMESPACE = "rahulverse-prod"
        K8S_CLUSTER_NAME = "rahulverse-eks"
        AWS_REGION = "ap-south-1"
        BUILD_VERSION = "${env.BUILD_NUMBER}"
        SLACK_CHANNEL = "#rahulverse-notification"
        SCANNER_HOME = tool 'sonar-scanner'
    }

    options {
        skipStagesAfterUnstable()
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '2'))
    }

    stages {
        stage("Cleanup Workspace"){
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                git branch: 'Jenkins-test', credentialsId: 'git-token', url: 'https://github.com/Rahul-Kumar-Paswan/k8s-testing.git'
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
                sh '''
                docker run -d --name mysql-test \
                -e MYSQL_ROOT_PASSWORD=rootpassword \
                -e MYSQL_DATABASE=rahulverseDB \
                -e MYSQL_USER=appuser \
                -e MYSQL_PASSWORD=apppass \
                -p 3306:3306 mysql:8.0
                '''
                sleep 30
                sh 'mvn test -B -Dspring.datasource.url=jdbc:mysql://localhost:3306/rahulverseDB -Dspring.datasource.username=appuser -Dspring.datasource.password=apppass'
            }
            post {
                always {
                    sh 'docker rm -f mysql-test || true'
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
                            -Dsonar.projectKey=rahulverse-Project -Dsonar.java.binaries=target/classes"""
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

        stage('Build Artifact & Deploy to Nexus') {
            steps {
                withMaven(globalMavenSettingsConfig: 'rahulverse', maven: 'maven3') {
                    sh 'mvn clean deploy -DskipTests'
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    def imageTag = "${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_VERSION}"
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
                    withKubeConfig(caCertificate: '', clusterName: "${K8S_CLUSTER_NAME}", contextName: '', credentialsId: 'k8s-token', namespace: "${K8S_NAMESPACE}", restrictKubeConfigAccess: false, serverUrl: 'https://3174F31CE88EB45229482FD3D9BB6B0A.gr7.ap-south-1.eks.amazonaws.com') {
                        sh """
                            kubectl apply -f K8s-Manifests/configmap.yaml -n ${K8S_NAMESPACE}
                            kubectl apply -f K8s-Manifests/secrets.yaml -n ${K8S_NAMESPACE}
                            kubectl apply -f K8s-Manifests/mysql-deploy.yaml -n ${K8S_NAMESPACE}
                            kubectl apply -f K8s-Manifests/app-deploy.yaml -n ${K8S_NAMESPACE}
                            sleep 20
                            kubectl get pods -n ${K8S_NAMESPACE}
                            kubectl describe pod \$(kubectl get pods -l app=${APP_NAME} -n ${K8S_NAMESPACE} -o jsonpath='{.items[0].metadata.name}') -n ${K8S_NAMESPACE}
                            kubectl set image deployment/${APP_NAME} ${APP_NAME}=${IMAGE_TAG} -n ${K8S_NAMESPACE}
                            sleep 20
                            kubectl rollout status deployment/${APP_NAME} -n ${K8S_NAMESPACE} --timeout=120s
                        """
                    }
                }
            }
        }

        stage('Post-Deployment Verification') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: "${K8S_CLUSTER_NAME}", contextName: '', credentialsId: 'k8s-token', namespace: "${K8S_NAMESPACE}", restrictKubeConfigAccess: false, serverUrl: 'https://3174F31CE88EB45229482FD3D9BB6B0A.gr7.ap-south-1.eks.amazonaws.com') {
                    sh """
                        kubectl get pods -n ${K8S_NAMESPACE}
                        kubectl get svc -n ${K8S_NAMESPACE}
                    """
                }
            }
        }
    }

    post {
        success {
            slackSend(channel: "${SLACK_CHANNEL}", color: 'good', message: "✅ Build #${BUILD_NUMBER} deployed successfully: ${env.IMAGE_TAG ?: 'not-built'}")
        }
        failure {
            slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "❌ Build #${BUILD_NUMBER} failed.")
        }
        always {
            cleanWs()
        }
    }
}
