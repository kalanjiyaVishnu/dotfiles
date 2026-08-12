#!/bin/bash

environment="$1"
es_home="$ES_HOME"
if [ "$environment" == "qa" ]; then  
  echo "~/.ssh/casa-qa 9403"
  ssh -i ~/.ssh/casa-qa -nNt -L 9403:localhost:9200 ubuntu@4.240.53.19

elif [ "$environment" == "master" ]; then
  echo "Local"
  "$es_home"
elif [ "$environment" == "prod" ]; then
  echo "ssh/casa-production 9404"
  ssh -i ~/.ssh/casa-production -nNt -L 9404:localhost:9200 ubuntu@deploy.casa.ajira.tech
elif [ "$environment" == "preprod" ]; then
  echo "ssh/casa-preprod 9402"
  ssh -i ~/.ssh/casa-preprod -nNT  -L 9402:localhost:9200 ubuntu@deploy.qa.casaretail.ai
else
  echo "Invalid environment. Please specify 'qa', 'master', or 'prod'. 'preprod'"
fi
