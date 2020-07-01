def macros
stage('Checkout') {
  node {
    sh 'rm -rf centreon-warp10-macros && mkdir centreon-warp10-macros'
    dir('centreon-warp10-macros-git') {
      checkout scm
      sh 'git archive HEAD | tar -C ../centreon-warp10-macros -x'
      macros = findFiles glob: "**/*.mc2"
      macros = macros.collect { it.path }
    }
    stash name: 'sources', includes: 'centreon-warp10-macros/**'
  }
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
        sh "docker exec ${container.id} mkdir -p /opt/warp10/macros/${baseDir}"
        sh "docker cp centreon-warp10-macros/${macro} ${container.id}:/opt/warp10/macros/${macro}"

        // Wait for Warp10 to be up.
        def endpoint = container.port(8080)
        def i = 0
        while (i < 60) {
          def exitCode = sh returnStatus: true, script: "curl -f -m 1 --data-binary \"[ ]\" http://${endpoint}/api/v0/exec"
          if (exitCode == 0) {
            break
          }
          sleep 1
          ++i
        }

        // By default, Warp10 refresh macro directory every 5 seconds.
        sleep 6

        // Unit tests are run during .mc2 file loading.
        // Macro should be available if unit tests succeeded.
        def macroName = macro.substring(0, macro.lastIndexOf('.'))
        sh "curl -f --data-binary \"[ '${macroName}' CHECKMACRO ]\" http://${endpoint}/api/v0/exec"

        // Stop container.
        container.stop()
      }
    }
  }
  parallel parallelSteps
}
