#!/usr/bin/env bash
# used by vscode launch config to run build_runner in debug mode
mapped=""

for arg in "$@"; do
    if [[ $arg != -* ]]; then
      # echo "Skipping: $arg"
      continue
    fi

    if [ $arg = "--pause_isolates_on_exit" ]; then
      arg="--pause-isolates-on-exit"
    fi

    if [ $arg = "--pause_isolates_on_start" ]; then
      arg="--pause-isolates-on-start"
    fi

    mapped="$mapped --dart-jit-vm-arg=$arg"
done


rm lib/injector/injector.config.dart # force rebuild
fvm dart run build_runner build $mapped