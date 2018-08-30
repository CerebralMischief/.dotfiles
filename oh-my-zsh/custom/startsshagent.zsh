# Script for starting the SSH Agent
# By: Eric Brown
#----------------------------------
eval `keychain --agents ssh --eval ~/.ssh/id_rsa`
