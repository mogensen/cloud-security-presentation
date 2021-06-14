#!/bin/bash
export PROJECT=$1

echo "Starting Sonarqube.."

# Run sonarqube - wait a few minutes until it has started
docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube

echo "Waiting for Sonarqube.."
until `docker logs sonarqube | grep -q "SonarQube is up"`
do
    echo -n "."
    sleep 0.2;
done
echo "Sonarqube is up. Scanning source code.."

# Scan the source code
docker run --rm -ti -v $(pwd)/$PROJECT:/usr/src --link sonarqube -e SONAR_HOST_URL="http://sonarqube:9000" sonarsource/sonar-scanner-cli -Dsonar.projectKey=$PROJECT

echo See "http://localhost:9000/dashboard?id=$PROJECT"
