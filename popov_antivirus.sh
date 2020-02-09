#!/bin/bash

# Small joke-program "Popov's antivirus"
# Script had been written after reading posts about russian "genius programmer" Denis Popov.

for i in {1..150}
  do
    printf '%s'  "checking is ....."
    echo -n "$i%"
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    sleep 0.05
    case "$i" in
      10) printf "Checking wallpapers - ok!\n";;
      26) echo 'Checking somthing - Ok! ';;
    esac
  done
echo 'viruses are absent! OK'
# echo 'some words about geeses :-)'
echo; echo

for i in {1..10}; do
    echo -en "\rLoading...\t$i%"
    sleep 0.1
done
echo