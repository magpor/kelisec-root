#!/bin/bash

if [ "$#" == "0" ]; then
  echo "Usage: $0 <git arguments>"
  exit 1
fi

echo "Running git $* in parallel on all submodules"
echo

modules=$(grep "<module>" pom.xml | sed 's/^.*<module>\([^>]*\)<\/module>.*$/\1/')

for module in $modules; do
  if [ ! -d "$module" ]; then
    echo "Module $module does not exist. Run the update script!"
  else
    pushd . > /dev/null
    cd "$module"
    git "$@" > "../$module.log" &
    popd > /dev/null
  fi
done

wait

for module in $modules; do
  echo -e "\033[1mModule $module:\033[0m"
  cat "$module.log"
  rm "$module.log"
  echo
done
