pipeline {
    agent any
    stages {
    environment {
            TARGET_HOST = "ec2-user@3.38.168.99"
        }
        stage('Checkout') {
            steps {
                git branch: 'master',
                    credentialsId: 'github_access_token',
                    url : 'https://github.com/leeworld9/Test_Jenkins.git'
            }
        }
        stage('build') {
            steps {
                    sh "chmod +x ./gradlew"
                    sh "./gradlew clean"
                    sh "./gradlew build"
                    sh "docker build -t leeworld9/backend ."
                }
        }
        stage('pushing to dockerhub') {
            steps {
             withCredentials([usernamePassword(credentialsId: 'docker_hub', usernameVariable: 'docker_user', passwordVariable: 'docker_pwd')]) {
                        sh "docker login -u ${docker_user} -p ${docker_pwd}"
                }
                sh "docker push leeworld9/backend"
             }
        }


        stage('deploy') {
            steps {
                sshagent (credentials: ['matching_backend_ssh']) {
                sh """
                    ssh -o StrictHostKeyChecking=no ${TARGET_HOST} '
                        hostname
                        docker pull leeworld9/backend
                    '
                """
                }

            }
        }
    }
}