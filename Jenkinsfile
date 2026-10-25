pipeline {
    agent any

    options {
        timestamps()
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

        stage('Detect Agent OS') {
            steps {
                script {
                    // A PYTHON variable set on the Jenkins node takes precedence over these defaults.
                    // robotframework-browser 20.x needs Python 3.10+
                    if (!env.PYTHON) {
                        if (!isUnix()) {
                            env.PYTHON = 'py -3.13'
                        } else if (sh(script: 'uname', returnStdout: true).trim() == 'Darwin') {
                            // /usr/bin/python3 on macOS is 3.9: use the python.org install
                            env.PYTHON = '/usr/local/bin/python3.13'
                        } else {
                            env.PYTHON = 'python3'
                        }
                    }
                    echo "Using Python: ${env.PYTHON}"
                }
            }
        }

        stage('Setup Python and Browser') {
            steps {
                script {
                    if (isUnix()) {
                        sh '''
                            # Remove results from previous builds, keep the tracked placeholder
                            find reports -mindepth 1 ! -name .gitkeep -exec rm -rf {} +
                            "$PYTHON" -m venv --clear .venv
                            .venv/bin/python -m pip install --upgrade pip
                            .venv/bin/pip install -r requirements.txt
                            # On Linux, system libraries are installed once by an admin (see README)
                            .venv/bin/rfbrowser install chromium
                        '''
                    } else {
                        bat '''
                            rem Remove results from previous builds, keep the tracked placeholder
                            powershell -NoProfile -Command "Get-ChildItem reports -Exclude .gitkeep | Remove-Item -Recurse -Force"
                            %PYTHON% -m venv --clear .venv
                            .venv\\Scripts\\python -m pip install --upgrade pip
                            .venv\\Scripts\\pip install -r requirements.txt
                            .venv\\Scripts\\rfbrowser install chromium
                        '''
                    }
                }
            }
        }

        stage('Run Robot Framework Tests') {
            steps {
                script {
                    // TEST_ID is read by the shell, not interpolated by Groovy
                    int result
                    if (isUnix()) {
                        result = sh(
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
                                        --test "*$TEST_ID -*" \
                                        tests/
                                fi
                            ''',
                            returnStatus: true
                        )
                    } else {
                        result = bat(
                            script: '''
                                set FILTER=
                                if not "%TEST_ID%"=="All" if not "%TEST_ID%"=="" set FILTER=--test "*%TEST_ID% -*"
                                .venv\\Scripts\\robot --outputdir reports --variable HEADLESS:True %FILTER% tests
                            ''',
                            returnStatus: true
                        )
                    }

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
