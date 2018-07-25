# Script for starting the SSH Agent
# By: Eric Brown
#----------------------------------
eval `keychain --agents ssh --eval ~/.ssh/github_intuition_id_rsa`
