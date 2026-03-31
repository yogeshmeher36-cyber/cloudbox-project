pipeline {
    agent any

    parameters {
        string(
            name: 'BRANCH_NAME',
            defaultValue: 'main',
            description: 'Git branch to build (e.g. main, develop, feature/xyz)'
        )
        choice(
            name: 'DEPLOY_ENV',
            choices: ['staging', 'production'],
            description: 'Target deployment environment'
        )
    }

    environment {
        AWS_ACCOUNT_ID  = '002645521749'
        AWS_REGION      = 'eu-north-1'
        ECR_REPO_NAME   = 'cloudbox-app'
        ECR_REGISTRY    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG       = "${params.DEPLOY_ENV}-${BUILD_NUMBER}"
        DOCKER_IMAGE    = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out branch: ${params.BRANCH_NAME}"
                git branch: "${params.BRANCH_NAME}",
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/yogeshmeher36-cyber/cloudbox-project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image for environment: ${params.DEPLOY_ENV}"
                sh """
                    docker build -t ${DOCKER_IMAGE} .
                    docker tag ${DOCKER_IMAGE} ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest
                """
            }
        }

        stage('Push to ECR') {
            steps {
                echo "Pushing image to ECR: ${DOCKER_IMAGE}"
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    docker push ${DOCKER_IMAGE}
                    docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest
                """
            }
        }

        stage('Deploy on EC2') {
            steps {
                echo "Deploying to ${params.DEPLOY_ENV} environment"
                sh """
                    # Stop and remove any existing container for this environment
                    docker-compose down --remove-orphans || true

                    # Export variables needed by docker-compose.yml
                    export DOCKER_IMAGE=${DOCKER_IMAGE}
                    export DEPLOY_ENV=${params.DEPLOY_ENV}

                    # Pull the latest image from ECR
                    aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    docker pull ${DOCKER_IMAGE}

                    # Start the container using Docker Compose
                    docker-compose up -d

                    # Confirm the container is running
                    docker ps | grep cloudbox
                """
            }
        }
    }   // <-- This closing brace was missing

    post {
        success {
            echo "✅ Deployment to ${params.DEPLOY_ENV} succeeded! Image: ${DOCKER_IMAGE}"
        }
        failure {
            echo "❌ Pipeline failed. Check the logs above for details."
        }
        always {
            sh "docker image prune -f || true"
        }
    }
}
