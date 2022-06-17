pipeline {
    agent any
    environment {

    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'master',
                    credentialsId: 'github_access_token',
                    url : 'https://github.com/leeworld9/Test_Jenkins.git'
            }
        }
        stage('build') {
            steps {
                dir ('backend') {
                    sh "chmod +x gradlew"
                    sh "./gradlew clean"
                    sh './gradlew build'
                    sh "docker build -t leeworld9/backend ."
                }
            }
        }
        stage('pushing to dockerhub') {
            steps {
             withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'docker_user', passwordVariable: 'docker_pwd')]) {
                        sh "docker login -u ${docker_user} -p ${docker_pwd}"
                    }
                sh "docker push leeworld9/backend"
        }
//         stage('deploy') {
//             steps {
//                 script {
//                     try {
//                         sh '$SSH_CMD $DOCKER stop front-end'
//                         sh '$SSH_CMD $DOCKER rm front-end'
//                     } catch (e) {
//                         sh 'echo "fail to stop and remove container"'
//                     }
//                     withCredentials([usernamePassword(credentialsId: 'private_registry_credential', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
//                         sh 'docker login $AWS_PUBLIC_IP:5000 -u $USERNAME -p $PASSWORD'
//                         sh '$SSH_CMD $DOCKER login localhost:5000 -u $USERNAME -p $PASSWORD'
//                 }
//                 sh 'docker push $AWS_PUBLIC_IP:5000/front-end:latest'
//                 sh '$SSH_CMD $DOCKER pull localhost:5000/front-end:latest'
//                 sh '$SSH_CMD $DOCKER run -d --name front-end -p 3000:80 localhost:5000/front-end:latest'
//                 }
//             }
        }
    }
}
