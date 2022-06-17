## 1. AWS EC2에 Jenkins 서버 구축 (Amazone Linux 2, freetier)
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
## 2. Jenkins CI/CD 구축
0. 빌드 및 배포 방식에도 여러가지가 있습니다. (여기서는 2번을 기준으로 작성하겠습니다)
    ```
    1. AWS S3 + AWS CodeDepoly
    2. Docker Hub
    3. Docker Registry
    4. AWS ECR + AWS ECS
    5. etc...
   ```
2. Github 액세스 토큰 생성
   - scope : repo, admin:repo_hook

3. Jenkins 크리덴셜 추가 (깃허브에서 생성한 액세스 토큰을 jenkins에 추가)
   2021년 8월 13일부터 비밀번호를 사용한 인증은 불가능하므로 이전단계에서 만든 액세스 토큰을 사용합니다.
   Kind : Username with Password
   Username : Github ID
   Password : Github PW가 아닌 액세스 토큰 정보를 입력합니다.

4. 등록할 레포지토리에 github-webhook 추가
  - payload url : {Jenkins URL:PORT}/jenkins/github-webhook/
  - content type : application/json

4. 젠킨스 new item 생성 
   1. 아이템 생성 방식에는 여러가지 방식이 있으나 여기선 **pipeline 방식**을 선택 (프리스타일이 작업하기는 쉬움....)
   2. 파이프라인 설정
      1. Github project 체크
      2. GitHub hook trigger for GITScm polling 체크
      3. Pipeline 설정
      ```
        
      ```

    
레퍼런스
- https://velog.io/@hmyanghm/AWS-EC2%EC%97%90-Jenkins-%EC%84%9C%EB%B2%84-%EA%B5%AC%EC%B6%95
  - AWS EC2에 Jenkins 서버 구축
- https://junhyunny.github.io/information/what-is-ci-cd/
  - docker registry 이용
- https://chiseoksong.medium.com/aws-ci-cd-%ED%99%98%EA%B2%BD-%EA%B5%AC%EC%84%B1-%ED%95%98%EA%B8%B0-with-jenkins-4669fdf56068
  - CodeDepoly + s3 이용
- https://www.dongyeon1201.kr/9026133b-31be-4b58-bcc7-49abbe893044
  - dockerhub 이용
