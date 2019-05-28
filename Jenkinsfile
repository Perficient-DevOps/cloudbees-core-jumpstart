// Default pod template
node {
  echo 'Hello World'
  sh '''
    env
    git clone https://github.com/Perficient-DevOps/cloudbees-core-jumpstart.git
    cd cloudbees-core-jumpstart
    ls -al
    hostname
  '''
}
 
// Target 'maven' pod template
node ('maven') {
  echo 'Hello World'
  sh '''
    env
    git clone https://github.com/Perficient-DevOps/cloudbees-core-jumpstart.git
    cd cloudbees-core-jumpstart
    ls -al
    hostname
  '''
 
  stage ('Maven') {
    // Target 'maven' container in this 'maven' pod
    container('maven') { sh 'mvn -version' }
  }
}