#!/bin/bash

set -e
set -x

main() {
    goToWorkingDirectory
    checkDependencies
    runTests
}

goToWorkingDirectory() {
    cd `dirname $0`
    cd `git rev-parse --show-toplevel`
    cd "IntegrationTests"
}

checkDependencies() {
    installCommandLineToolsIfNeeded
    setupPyenv
    installPyTest
    installRequirementsTxt
}

# Required to build python via pyenv
installCommandLineToolsIfNeeded() {
    pkgutil --pkg-info=com.apple.pkg.CLTools_Executables || installCommandLineTools
}

installCommandLineTools() {
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    local savedIFS=$IFS
    IFS=$'\n'
    for packageName in $(softwareupdate -l|grep "\*.*Command Line"|awk -F"*" '{print $2}'|sed -e 's/^ *//')
    do
        softwareupdate -i "$packageName"
    done
    IFS=$savedIFS
}

runTests() {
    if [[ "$PYCACHE_ENABLED" == "true" ]]
    then
        pytest
    else
        pytest --cache-clear
    fi
}

# Allows to use python in isolated environment.
# Better solution is to use something like Docker, but with OSX inside container.
setupPyenv() {
    local pythonVersion="3.7.1"
    local envName="ios-runner-tests"

    which pyenv || brew install pyenv
    which pyenv-virtualenv || brew install pyenv-virtualenv

    pyenv install -s "$pythonVersion"

    pyenv virtualenv "$pythonVersion" "$envName" || true

    # After those commands pip3/python3/pytest will refer to those in virtualenv
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"

    pyenv local "$envName"
}

installPyTest() {
    pip3 install pytest
}

installRequirementsTxt() {
    pip3 install -r "requirements.txt"
}

main
