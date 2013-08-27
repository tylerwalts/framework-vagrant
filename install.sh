#!/bin/bash
#
# Install Vagrant framework
#
# Assumes this is installed as a submodule, and installs itself
# by copying templates and creating symbolic links to common tools.
#

frameworkPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $frameworkPath # For when calling from other paths
targetVagrantPath="$( cd "$frameworkPath/../" && pwd )"

# Get version of this repository that we're working with, to tag copies.
# Assumes this was installed using the sprint-zero framework
frameworkSource="$(cat ../../../.git/modules/tools/vagrant/.framework-vagrant/HEAD) on $(date +%Y-%m-%d_%H%M)"
function copyAndTag {
    filename=$1
    sourceFile=$frameworkPath/$filename
    destFile=$targetVagrantPath/$filename
    if [[ -f $destFile ]]; then
            echo "* Skipping existing template: $destFile"
    else
        echo "Copying: $filename"
        command="cp $sourceFile $destFile"
        $command
        echo "#$frameworkSource" >> $destFile
        copiedFileList=" $copiedFileList $filename "
    fi
}
function symLink {
    filename=$1
    osType="$(uname)"
    if [[ $osType == *WIN* || $osType == *MIN* ]]; then
        # Look for CYGWIN or MINGW
        copyAndTag $filename
    else
        filenameOnly=$(basename "$filename")
        relativePath="${filename%/*}"
        if [[ "$filenameOnly" == "$relativePath" ]]; then
            relativePath=""
        else
            pathCount="$( echo $relativePath | grep -o '/' | wc -l)"
            relativePath=""
            while [[ "$pathCount" != "-1" ]]; do
                relativePath="${relativePath}../"
                (( pathCount-- ))
            done
        fi
        sourceFile="${relativePath}.framework-vagrant/$filename"
        destFile=$targetVagrantPath/$filename
        if [[ -h $destFile ]]; then
            echo "- Updating symlink: $filename"
            rm $destFile
            ln -s $sourceFile $destFile
        elif [[ -e $destFile ]]; then
            echo "* Skipping existing file in place of symlink (customized for project): $destFile"
        else
            echo "Linking: $filename"
            ln -s $sourceFile $destFile
            if [[ "$(grep $filename $targetVagrantPath/.gitignore)" == "" ]];then
                echo "$filename" >> $targetVagrantPath/.gitignore
            fi
        fi
    fi
}

echo "Installing vagrant framework into project repository...
    Notes:
        - Files which the project will want to customize are copied to the project path.
        - Files which should remain unchanged and common between projects are symlinked on Mac/Linux, copied and .gitignored on Windows.
"

# Create directory structure
mkdir -p $targetVagrantPath/nodeLists/ \
    $targetVagrantPath/keys

[[ ! -e $targetVagrantPath/.gitignore \
    || "$(grep 'maintained' $targetVagrantPath/.gitignore)" == "" ]] && \
    echo "# These are maintained by the vagrant framework" >> $targetVagrantPath/.gitignore

# Special case for Vagrantfile - assumes convention and install in project root
if [[ $osType == *WIN* || $osType == *MIN* ]]; then
    ln -s $frameworkPath/Vagrantfile $targetVagrantPath/../../Vagrantfile
else
    cp $frameworkPath/Vagrantfile $targetVagrantPath/../../Vagrantfile
fi

symLink    imageTypes.yaml
copyAndTag vagrant/nodeLists/cluster.yaml
copyAndTag vagrant/nodeLists/dev.yaml

# Setup initial keys
[[ ! -e $targetVagrantPath/keys/.gitignore \
    || "$(grep 'maintained' $targetVagrantPath/keys/.gitignore)" == "" ]] && \
    echo -e " # Your private keys and things go in this directory and should be protected.
# This is to keep this directory always clear and ignored for commit, besides this file.
*\n !.gitignore\n" >> $targetVagrantPath/keys/.gitignore
echo "accessKey: MY_ACCESS_KEY\nsecretKey: MY_SECRET_KEY" > awsKeys.yaml

echo -e "Updating project's README.md..."
[[ ! -e $projectPath/README.md \
    || "$(grep -e '^Vagrant Framework:$' $projectPath/README.md)" == "" ]] \
        && cat $frameworkPath/README.md >> $projectPath/README.md

gitStatus=$(cd $targetVagrantPath && git status vagrant/nodeLists/dev.yaml | grep 'working directory clean' | wc -l | tr -d ' ' )
if [[ "$gitStatus" != "1" ]]; then
    echo -e "\nAdding vagrant templates and links to project repository...\n"
    $(cd $targetVagrantPath && git add .gitignore $copiedFileList)
    echo -e "Remember to review & commit git changes:\n\tcd ..\n\tgit status\n\tgit diff\n\tgit commit -m 'Added vagrant framework artifacts'\n\tgit push\n"
fi

echo -e "\nVagrant installation done."

