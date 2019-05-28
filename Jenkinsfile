// Default pod template
node {
  echo 'Hello World'
  sh '''
    env
    git clone https://globalrepository.mastercard.int/stash/scm/pipe/cjoc-pks.git
    cd cjoc-pks
    ls -al
    hostname
  '''
}
 
// Target 'maven' pod template
node ('maven') {
  echo 'Hello World'
  sh '''
    env
    git clone https://globalrepository.mastercard.int/stash/scm/pipe/cjoc-pks.git
    cd cjoc-pks
    ls -al
    hostname
  '''
 
  stage ('Maven') {
    // Target 'maven' container in this 'maven' pod
    container('maven') { sh 'mvn -version' }
  }
}