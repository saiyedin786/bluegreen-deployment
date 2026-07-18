

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