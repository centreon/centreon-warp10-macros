def macros
stage('Checkout') {
  dir('centreon-warp10-macros-git') {
    checkout scm
    sh 'git archive HEAD | tar -C ../centreon-warp10-macros -x'
    macros = findFiles glob: "**/*.mc2"
  }
  stash name: 'sources', includes: 'centreon-warp10-macros/**'
}

stage('Unit tests') {
  def parallelSteps = [:]
  for (x in macros) {
    def macro = x
    parallelSteps[macro] = {
      node {
        // Get sources.
        sh 'rm -rf centreon-warp10-macros'
        unstash('sources')

        // Prepare container.
        def baseDir = macro.substring(0, macro.lastIndexOf('/'))
        def container = docker.image('warp10io/warp10').run('-p 8080')
        sh "docker exec ${container.id} mkdir /opt/warp10/macros/${baseDir}"
        sh "docker cp centreon-warp10-macros/${macro} ${container.id}:/opt/warp10/macros/${macro}"

        // By default, Warp10 refresh macro directory every 5 seconds.
        sleep 5

        // Unit tests are run during .mc2 file loading.
        // Macro should be available if unit tests succeeded.
        def macroName = macro.substring(0, macro.lastIndefOf('.'))
        def containerPort = container.port(8080)
        sh "curl -f --data-binary "[ '${macroName}' CHECKMACRO ]" http://localhost:${containerPort}/api/v0/exec"

        // Stop container.
        container.stop()
      }
    }
  }
  parallel parallelSteps
}
