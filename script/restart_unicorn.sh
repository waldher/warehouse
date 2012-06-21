#!/bin/bash
let id=`ps ax | grep unicorn | grep master | sed "s/[ ]*\([0-9]*\).*/\1/"`
echo "Old ID: $id"
kill -SIGUSR2 "$id" 
sleep 2
kill -SIGQUIT "$id"
sleep 3
let id=`ps ax | grep unicorn | grep master | sed "s/[ ]*\([0-9]*\).*/\1/"`
echo "New ID: $id"
