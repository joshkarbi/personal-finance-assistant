#!/bin/bash

# Start the first process
export PRODUCTION=true && npm start &
  
# Start the second process
systemctl service nginx start
  
# Wait for any process to exit
wait -n
  
# Exit with status of process that exited first
exit $?