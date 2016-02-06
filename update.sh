#!/bin/bash
gigaspacesVersion=11.0.0-14711-M10
gigaspacesRepoProbe=$HOME/.m2/repository/com/gigaspaces/gs-openspaces/$gigaspacesVersion/

# Update this script
if [ "$1" != "pulled" ]; then
  echo -e "Pulling latest root module"
  git pull
  ./update.sh pulled
  exit 0
fi

# Probes the gigaspace installation
if [ ! -d "$gigaspacesRepoProbe" ]; then
  echo "Gigaspaces is not available in the maven repository."
  echo "Download Gigaspaces v$gigaspacesVersion and run <gigaspaces home>/tools/maven/installmavenrep.sh"
  exit 1
fi

# Check the github ssh keys in case the root is not using ssh
if [ "$(cat .git/config | grep git@github.com)" == "" ]; then
  echo "Verifying github ssh keys"
  gitlogin=$(ssh -T git@github.com 2>&1 | sed -e '/Hi/!d' -e 's/^Hi \([^!]*\).*$/\1/')
  if [ "$gitlogin" == "" ]; then
    echo "You don't have a valid github ssh key. See https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/"
    exit 1
  else
    echo "Authenticated as $gitlogin"
  fi
fi

# Parse modules from the pom.xml
modules=$(sed -e '/<module>/!d' -e 's/^.*<module>\([^>]*\)<\/module>.*$/\1/' pom.xml)

# Check for orphaned subdirectories
directories=$(ls)
for directory in $directories; do
  if [[ -d "$directory" && ! "$modules" =~ $directory ]]; then
    echo "The directory $directory looks like an orphaned module and could probably be deleted."
  fi
done

# Clone or pull all modules in the background
for module in $modules; do
  if [ ! -d "$module" ]; then
    git clone git@github.com:kelisec/$module.git > ".$module.log" 2>&1 &
  else
    pushd . > /dev/null
    cd "$module"
    if [ "$(git status --porcelain)" == "" ]; then
      git pull > "../.$module.log" 2>&1 &
    else
      echo -e "\033[1;31mModule $module contains modified files and was not updated!\033[0m" > "../.$module.log"
    fi
    popd > /dev/null
  fi
done

# Wait for background jobs to finish
echo "Updating modules..."
wait
echo

# Print the git output for each module
for module in $modules; do
  echo -e "\033[1mModule $module:\033[0m"
  cat ".$module.log"
  rm ".$module.log"
  echo
done

echo "done!"
