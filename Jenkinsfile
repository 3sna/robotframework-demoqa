pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        // robotframework-browser 20.x needs Python 3.10+; /usr/bin/python3 on macOS is 3.9
        PYTHON = '/usr/local/bin/python3.13'
    }

    parameters {
        string(
            name: 'TEST_ID',
            defaultValue: 'All',
            trim: true,
            description: 'All = run every test, otherwise the ID of one test (e.g. TC03)'
        )
    }

    stages {
        stage('Checkout GitHub Project') {
            steps {
                // Reuses the job's repository, branch and credentials
                checkout scm
            }
        }

        stage('Setup Python and Browser') {
            steps {
                sh '''
                    # Remove results from previous builds, keep the tracked placeholder
                    find reports -mindepth 1 ! -name .gitkeep -exec rm -rf {} +
                    "$PYTHON" -m venv --clear .venv
                    .venv/bin/python -m pip install --upgrade pip
                    .venv/bin/pip install -r requirements.txt
                    .venv/bin/rfbrowser install chromium
                '''
            }
        }

        stage('Run Robot Framework Tests') {
            steps {
                script {
                    // TEST_ID is read by the shell, not interpolated by Groovy
                    int result = sh(
                        script: '''
                            if [ "$TEST_ID" = "All" ] || [ -z "$TEST_ID" ]; then
                                .venv/bin/robot \
                                    --outputdir reports \
                                    --variable HEADLESS:True \
                                    tests/
                            else
                                .venv/bin/robot \
                                    --outputdir reports \
                                    --variable HEADLESS:True \
                                    --test "$TEST_ID *" \
                                    tests/
                            fi
                        ''',
                        returnStatus: true
                    )

                    env.ROBOT_EXIT_CODE = "${result}"
                }
            }
        }
    }

    post {
        always {
            // Publish the Robot Framework HTML report
            publishHTML(target: [
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'reports',
                reportFiles: 'report.html',
                reportName: 'Robot Framework HTML Report'
            ])

            // Archive all generated reports and screenshots
            archiveArtifacts(
                artifacts: 'reports/**',
                allowEmptyArchive: true
            )

            // Publish Robot Framework test results and trends
            script {
                if (fileExists('reports/output.xml')) {
                    robot(
                        outputPath: 'reports',
                        outputFileName: 'output.xml',
                        reportFileName: 'report.html',
                        logFileName: 'log.html'
                    )
                }

                // Preserve the actual test result
                if (env.ROBOT_EXIT_CODE &&
                    env.ROBOT_EXIT_CODE != '0') {
                    currentBuild.result = 'FAILURE'
                }
            }
        }
    }
}
