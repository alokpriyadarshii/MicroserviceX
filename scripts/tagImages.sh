#!/bin/bash
docker tag ${REPOSITORY_PREFIX}/spring-animalclinic-config-server ${REPOSITORY_PREFIX}/spring-animalclinic-config-server:${VERSION}
docker tag ${REPOSITORY_PREFIX}/spring-animalclinic-discovery-server ${REPOSITORY_PREFIX}/spring-animalclinic-discovery-server:${VERSION}
docker tag ${REPOSITORY_PREFIX}/spring-animalclinic-api-gateway ${REPOSITORY_PREFIX}/spring-animalclinic-api-gateway:${VERSION}
docker tag ${REPOSITORY_PREFIX}/spring-animalclinic-visits-service ${REPOSITORY_PREFIX}/spring-animalclinic-visits-service:${VERSION}
docker tag ${REPOSITORY_PREFIX}/spring-animalclinic-vets-service ${REPOSITORY_PREFIX}/spring-animalclinic-vets-service:${VERSION}
docker tag ${REPOSITORY_PREFIX}/spring-animalclinic-customers-service ${REPOSITORY_PREFIX}/spring-animalclinic-customers-service:${VERSION}
docker tag ${REPOSITORY_PREFIX}/spring-animalclinic-admin-server ${REPOSITORY_PREFIX}/spring-animalclinic-admin-server:${VERSION}
docker tag ${REPOSITORY_PREFIX}/spring-animalclinic-genai-service ${REPOSITORY_PREFIX}/spring-animalclinic-genai-service:${VERSION}
