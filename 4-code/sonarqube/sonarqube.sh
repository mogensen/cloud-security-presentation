#!/bin/bash

if [[ "$1" = "-h" || "$1" = "--help" ]] ; then
  echo "Usage: "
  echo "$0 src-dir"
  echo "Additional parameters can be passed to sonar-scanner-cli like this"
  echo "$0 src-dir -Dsonar.java.binaries=./target/classes"
  exit 0
fi

export PROJECT=$1
shift # remove first argument - additional arguments are in "$@"

echo "Starting Sonarqube.."

# Run sonarqube - wait a few minutes until it has started
if [ -z $(docker ps | grep  sonarqube)]; then
  docker run -d --name sonarqube -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true -e SONAR_FORCEAUTHENTICATION=false -p 9000:9000 -p 9092:9092 sonarqube
else
  echo "Sonarqube already started"
fi


echo "Waiting for Sonarqube.."
until `docker logs sonarqube | grep -q "SonarQube is up"`
do
    echo -n "."
    sleep 0.2;
done

echo "Sonarqube is up. Scanning source code.."

# Scan the source code
docker run --rm -ti -v $(pwd)/$PROJECT:/usr/src --link sonarqube -e SONAR_HOST_URL="http://sonarqube:9000"   sonarsource/sonar-scanner-cli -Dsonar.projectKey=$PROJECT "$@"
echo
echo "See http://localhost:9000/dashboard?id=$PROJECT"
