pipeline {
    agent any

    // ─────────────────────────────────────────────
    // PARAMETERS  (Step 1 requirement)
    // Jenkins UI will show a form before each build
    // ─────────────────────────────────────────────
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

    // ─────────────────────────────────────────────
    // ENVIRONMENT VARIABLES
    // Replace the values below with your own:
    //   AWS_ACCOUNT_ID  – your 12-digit AWS account number
    //   AWS_REGION      – region where your ECR lives
    //   ECR_REPO_NAME   – name of your ECR repository
    // ─────────────────────────────────────────────
    environment {
        AWS_ACCOUNT_ID  = '123456789012'          // <-- replace with your AWS Account ID
        AWS_REGION      = 'us-east-1'             // <-- replace with your AWS region
        ECR_REPO_NAME   = 'cloudbox-app'          // <-- replace with your ECR repo name
        ECR_REGISTRY    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG       = "${params.DEPLOY_ENV}-${BUILD_NUMBER}"
        DOCKER_IMAGE    = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
    }

    stages {

        // ─── Stage 1: Checkout code from GitHub ───
        stage('Checkout') {
            steps {
                echo "Checking out branch: ${params.BRANCH_NAME}"
                git branch: "${params.BRANCH_NAME}",
                    credentialsId: 'github-credentials',   // Jenkins credential ID for GitHub
                    url: 'https://github.com/YOUR_USERNAME/cloudbox-project.git'  // <-- replace with your GitHub repo URL
            }
        }

        // ─── Stage 2: Build Docker Image ───
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image for environment: ${params.DEPLOY_ENV}"
                sh """
                    docker build -t ${DOCKER_IMAGE} .
                    docker tag ${DOCKER_IMAGE} ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest
                """
            }
        }

        // ─── Stage 3: Login to ECR and Push Image ───
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

        // ─── Stage 4: Deploy on EC2 using Docker Compose ───
        stage('Deploy on EC2') {
            steps {
                echo "Deploying to ${params.DEPLOY_ENV} environment"
                sh """
                    # Stop and remove any existing container for this environment
                    docker compose down --remove-orphans || true

                    # Export variables needed by docker-compose.yml
                    export DOCKER_IMAGE=${DOCKER_IMAGE}
                    export DEPLOY_ENV=${params.DEPLOY_ENV}

                    # Pull the latest image from ECR
                    aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    docker pull ${DOCKER_IMAGE}

                    # Start the container using Docker Compose
                    docker compose up -d

                    # Confirm the container is running
                    docker ps | grep cloudbox
                """
            }
        }
    }

    // ─────────────────────────────────────────────
    // POST-BUILD ACTIONS
    // ─────────────────────────────────────────────
    post {
        success {
            echo "✅ Deployment to ${params.DEPLOY_ENV} succeeded! Image: ${DOCKER_IMAGE}"
        }
        failure {
            echo "❌ Pipeline failed. Check the logs above for details."
        }
        always {
            // Clean up local Docker images to save disk space
            sh "docker image prune -f || true"
        }
    }
}
