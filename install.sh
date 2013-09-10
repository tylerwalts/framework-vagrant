#!/bin/bash
#
# Install Vagrant framework
#
# Assumes this is installed as a submodule, and installs itself
# by copying templates and creating symbolic links to common tools.
#

frameworkPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
projectPath="$1"
targetVagrantPath="$1/tools/vagrant"

if [[ ! -d $projectPath ]]; then 
  echo "The target Vagrant of [$projectPath] installation path is invalid"
  exit 127
fi

# Get version of this repository that we're working with, to tag copies.
# Assumes this was installed using the sprint-zero framework
frameworkSource="$(cd $frameworkPath && git rev-parse --short HEAD) on $(date +%Y-%m-%d_%H%M)"

function copyAndTag {
    local filename=$1
    local destFile=$2
    local sourceFile=$frameworkPath/$filename

    [[ "$destFile" == "" ]] && destFile=$targetVagrantPath/$filename
    
    if [[ -f $destFile ]]; then
      echo "* Skipping existing template: $destFile"
    else
      echo "Copying: $filename"
      local command="cp $sourceFile $destFile"
      $command
      echo "#$frameworkSource" >> $destFile
    fi
}

function symLink {
    local filename=$1
    local destFile=$2 # Optional arg.  Default is relative path
    local relativeSourcePath=$3 # Optional arg.  Default is relative path
    
    osType="$(uname)"
    if [[ $osType == *WIN* || $osType == *MIN* ]]; then
      # Look for CYGWIN or MINGW
      copyAndTag $filename
    else
      # Build Destination Link
      [[ "$destFile" == "" ]] && destFile=$targetVagrantPath/$filename

      local sourceFile
      local filenameOnly
      local relativePath
      local pathCount
        
      # Build Source Link
      if [[ "$relativeSourcePath" != "" ]]; then
          sourceFile="${relativeSourcePath}.framework-vagrant/$filename"
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
      fi

      # Check and make link
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

copyAndTag Vagrantfile "$projectPath/Vagrantfile"
copyAndTag imageTypes.yaml
copyAndTag nodeLists/cluster.yaml
copyAndTag nodeLists/dev.yaml

# Setup initial keys
[[ ! -e $targetVagrantPath/keys/.gitignore \
    || "$(grep 'maintained' $targetVagrantPath/keys/.gitignore)" == "" ]] && \
    echo -e " # Your private keys and things go in this directory and should be protected.
# This is to keep this directory always clear and ignored for commit, besides this file.
*\n !.gitignore\n" >> $targetVagrantPath/keys/.gitignore
echo -e "accessKey: MY_ACCESS_KEY\nsecretKey: MY_SECRET_KEY\nkeypair: MY_KEYPAIR\nkeypath: tools/vagrant/keys/MY_KEYFILE.pem" > $targetVagrantPath/keys/awsKeys.yaml

echo -e "Updating project's README.md..."
[[ ! -e $targetVagrantPath/README.md \
    || "$(grep -e '^Vagrant Framework:$' $targetVagrantPath/README.md)" == "" ]] \
        && cat $frameworkPath/README.md >> $targetVagrantPath/README.md

echo -e "\nVagrant installation done."

