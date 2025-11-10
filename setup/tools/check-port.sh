#!/bin/bash

usage() {
  echo "Usage: $0 <start_port> <end_port>"
  echo "Example: $0 7000 7005"
  exit 1
}

queryPort() {
  # lsof -i :7000 | awk 'NR>1 {print $2}' | unique
  lsof -nP | grep ':7000' | awk '{print $2}' | sort -u
}

function printOutput() {
  port=$1
  status=$2
  output=$3
  echo "Checking port ${port}... ${status}"
  # printf "Checking port %s... %s\n" "$port" "$status"
  if [ ! -z "$output" ]; then
    # echo -e "$output\n"
    # printf "%s\n\n" "$output"

    # pid="echo '$output' | grep ':7000' | awk '{ print \$2 }' | sort -u"
    getPid="lsof -nP | grep ':7000' | awk '{ print \$2 }' | sort -u"
    pid=`eval $getPid`
    echo $pid
    getProc="ps -p $pid -o comm="
    res=`eval $getProc`
    echo $res
    echo -e "\n"
  fi
}

checkPorts() {
  local start=$1
  local end=$2

  if ! [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ ]]; then
    echo "Error: Ports must be numeric."
    usage
  fi
  if [ "$start" -gt "$end" ]; then
    echo "Error: start_port must be <= end_port."
    usage
  fi

  for port in $(seq "$start" "$end")
  do
    output=$(lsof -i :"$port")
    if [ -n "$output" ]; then
      status="in use"
    else
      status="available"
    fi
    printOutput "$port" "$status" "$output"
  done
}

if [ $# -lt 2 ]; then
  usage
fi

checkPorts "$1" "$2"

# docker ps | grep 7000