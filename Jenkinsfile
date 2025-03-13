pipeline {
    agent any

    triggers {
        githubPush()
    }
    
    environment {
        REGISTRY = "arkselen"
        IMAGE_NAME = "test"
        IMAGE_TAG = "latest"
        DOCKER_USERNAME = "arkselen"
        DOCKER_TOKEN = credentials('docker_token')
        SSH_KEY = credentials('ssh_key')
        CONTAINER_NAME = "${IMAGE_NAME}_container"
        LOG_FILE = "/var/log/jenkins/disk_usage.log"
    }

    stages {
        stage('Build and Push Docker Image') {
            steps {
                script {
                    sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ."
                    sh "echo \$DOCKER_TOKEN | docker login -u \$DOCKER_USERNAME --password-stdin ${REGISTRY}"
                    sh "docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
        stage('Deploy to Remote Server') {
            steps {
                script {
                    writeFile file: '/tmp/ssh_key', text: SSH_KEY
                    sh 'chmod 600 /tmp/ssh_key'
                    sh """
                        ssh -i /tmp/ssh_key user@your-instance '
                            docker pull ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} && \
                            docker stop ${CONTAINER_NAME} || true && \
                            docker rm ${CONTAINER_NAME} || true && \
                            docker run -d --name ${CONTAINER_NAME} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        '
                    """
                }
            }
        }
        stage('Cleanup Old Docker Images from Registry') {
            steps {
                script {
                    sh "./cleanup_registry.sh ${REGISTRY} ${IMAGE_NAME} \$DOCKER_USERNAME \$DOCKER_TOKEN"
                }
            }
        }
    }
    post {
        always {
            script {
                disk_usage = sh(script: "df -h | grep '/$' | awk '{ print \$5 }' | sed 's/%//'", returnStdout: true).trim()

                if (!fileExists(LOG_FILE)) {
                    writeFile file: LOG_FILE, text: ""
                }

                if (disk_usage.toInteger() > 90) {
                        echo "Disk space is low. Performing remove images"
                        sh "docker system prune -f"
                        
                    sh "echo '$(date +'%Y-%m-%d %H:%M:%S') - Cleanup! Filesystem is $disk_usage% full' >> $LOG_FILE"
                }
            }
        }
    }
}
