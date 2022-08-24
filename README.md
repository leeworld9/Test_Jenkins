## 1. AWS EC2에 Jenkins 서버 구축 
### (Amazone Linux 2, freetier)
1. EC2 접속 (ssh)   
    ```$ ssh -i "your-pem-file.pem" ec2-user@your-ec2-dns-주소```

2. Amazon Corretto 11 (java) 설치   
   ```$ sudo yum install java-11-amazon-corretto```

3. Jenkins 설치   
    ```
    $ sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
    $ sudo rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
    $ sudo yum install jenkins
    ```
   
4. 프리티어 EC2 스왑 파티션 생성
    ```
    // 메모리 상태 확인 (swap 파일 메모리가 0인 것을 확인)
    $free -h
   
    // swap 파일을 생성해준다. (메모리 상태 확인 시 swap이 있었지만 디렉토리 파일은 만들어줘야한다.)
    $ sudo mkdir /var/spool/swap
    $ sudo touch /var/spool/swap/swapfile
    $ sudo dd if=/dev/zero of=/var/spool/swap/swapfile count=2048000 bs=1024

    // swap 파일을 설정한다.
    $ sudo chmod 600 /var/spool/swap/swapfile
    $ sudo mkswap /var/spool/swap/swapfile
    $ sudo swapon /var/spool/swap/swapfile

    // swap 파일을 등록한다.
    $ sudo vim /etc/fstab
   
    // 해당 파일 아래쪽에 하단 내용 입력 후 저장
    /var/spool/swap/swapfile    none    swap    defaults    0 0

    // 메모리 상태 확인 (swap 파일이 정상적으로 적용된것을 확인)
    $free -h
    ```
   
5. Docker & Git 설치 (인터넷에 자료가 많으니 설명 생략)
    - Docker 실행간에 권한 문제가 발생할 경우 _4. Reference_ 참고

◉ Tip : 아래 명령어로 서비스가 부팅 시 자동 실행되도록 설정할 수 있다.   
```
    sudo systemctl enable {서비스명} 
```

## 2. Jenkins CI/CD 구축
빌드 및 배포 방식에도 여러가지가 있습니다. (여기서는 2번을 기준으로 작성하겠습니다)
```
1. AWS S3 + AWS CodeDepoly
2. Docker Hub
3. Docker registry
4. AWS ECR + AWS ECS
5. etc...
```

1. Github 액세스 토큰 생성
   - scope : repo, admin:repo_hook

2. Jenkins에서 pipeline 작성간에 필요한 크리덴셜 추가 
   1. `Github 액세스 토큰`을 크리덴셜에 추가
      - 2021년 8월 13일부터 비밀번호를 사용한 인증은 불가능하므로 이전단계에서 만든 액세스 토큰을 사용합니다.
      - Kind : Username with Password
      - Username : Github ID
      - Password : Github PW가 아닌 액세스 토큰 정보를 입력합니다.
   2. `배포할 서버의 ssh key 값`을 크리덴셜에 추가
      - Kind : SSH Username with private key
      - Username : ssh 계정명 (ex: ec2-user)
      - Private Key : ssh 로그인 시 필요한 pam 파일의 값
   3. 빌드파일을 업로드할 `Docker Hub 계정`을 크리덴셜에 추가

3. 빌드 할 레포지토리에 github-webhook 추가
   - payload url : {Jenkins URL:PORT}/jenkins/github-webhook/
   - content type : application/json

4. 젠킨스 new item 생성 
   1. 아이템 생성 방식에는 여러가지 방식이 있으나 여기선 **pipeline 방식**을 선택 
      1. Freestyle Project가 작업하기는 쉽다.
   2. 파이프라인 설정
      1. Github project 체크
      2. GitHub hook trigger for GITScm polling 체크
      3. Pipeline 설정
         - 'Pipeline script for SCM' 으로 설정하면, pipeline을 "Jenkinsfile"에 작성하여 사용할 수 있다.
         - 사용할 repository 주소와 빌드 할 branch 입력
         - 'Script Path'에 "Jenkinsfile" 입력
         
5. 젠킨스에서 **SSH Agent** 플러그인 설치

6. 프로젝트 폴더에 "Jenkinsfile" 생성 및 pipeline 작성
   ```
    pipeline {
        agent any
        environment {
            TARGET_HOST = "ec2-user@3.38.168.99"
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
                            docker run -d -p 8080:8080 -it leeworld9/backend:latest
                        '
                    """
                    }
                }
            }
        }
    }
   ```

7. 프로젝트 폴더에 "Dockerfile" 생성 및 작성
   ```
    FROM openjdk:11-jre-slim
    
    COPY /build/libs/*.jar application.jar
    
    CMD ["java", "-jar", "/application.jar"]
   ```

8. 당연하지만, 배포할 서버에는 도커가 이미 설치되어 있어야한다.

    
## 3. 추가 작업 필요
- 젠킨스 서버 : 새로 업데이트 된 빌드를 도커 허브에 푸시할 때, 기존 도커 빌드 이미지 삭제하는 스크립트 필요
- 배포 서버 : 새로 업데이트 된 빌드를 실행할 때, 기존 컨테이너 중지 & 기존 도커 이미지 삭제하는 스크립트 필요
- Docker Hub 업로드시에 버전 관리 필요.

## 4. 마침
- 해당 방식(Docker Hub)으로 사용해본 결과, 로그 저장시에 굉장히 불편함이 많았다.
- 개인적으로는 바로 ec2 서버에 배포할 수 있는 방식이 더 편하고 작업하기 수월하였다.
    
## 5. Reference
- https://velog.io/@hmyanghm/AWS-EC2%EC%97%90-Jenkins-%EC%84%9C%EB%B2%84-%EA%B5%AC%EC%B6%95
  - AWS EC2에 Jenkins 서버 구축
- https://junhyunny.github.io/information/what-is-ci-cd/
  - Docker registry 이용
- https://chiseoksong.medium.com/aws-ci-cd-%ED%99%98%EA%B2%BD-%EA%B5%AC%EC%84%B1-%ED%95%98%EA%B8%B0-with-jenkins-4669fdf56068
  - AWS CodeDepoly + AWS S3 이용
- https://www.dongyeon1201.kr/9026133b-31be-4b58-bcc7-49abbe893044
  - Docker Hub 이용 & 버전 관리 스크립트 참고
- https://velog.io/@hmyanghm/AWS-EC2%EC%97%90-Docker-%EC%84%A4%EC%B9%98
  - 위 자료를 참고하여, 도커 사용 시 권한 문제 해결 가능
- https://royleej9.tistory.com/m/entry/Jenkins-SSH-%EC%82%AC%EC%9A%A9-pipeline-SSH-Agent
  - SSH Agent에 대한 자세한 설명이 나와 있음.
