pipeline {
    agent any
    triggers {
        githubPush()
    }
    stages {
        stage('Read File') {
            steps {
                sh 'cat hello.txt'
            }
        }
    }
}
