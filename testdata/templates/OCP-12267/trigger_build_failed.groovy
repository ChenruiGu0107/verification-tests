node{
        stage 'build'
        def build = openshiftBuild apiURL: '<repl_env>', authToken: '', bldCfg: 'frontend', buildName: '', checkForTriggeredDeployments: 'false', commitID: '', namespace: '<repl_ns>', showBuildLogs: 'false', verbose: 'false', waitTime: '1', waitUnit: 'sec'

}
