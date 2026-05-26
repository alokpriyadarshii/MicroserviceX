#!/bin/bash
docker push ${REPOSITORY_PREFIX}/spring-animalclinic-config-server:${VERSION}
docker push ${REPOSITORY_PREFIX}/spring-animalclinic-discovery-server:${VERSION}
docker push ${REPOSITORY_PREFIX}/spring-animalclinic-api-gateway:${VERSION}
docker push ${REPOSITORY_PREFIX}/spring-animalclinic-visits-service:${VERSION}
docker push ${REPOSITORY_PREFIX}/spring-animalclinic-vets-service:${VERSION}
docker push ${REPOSITORY_PREFIX}/spring-animalclinic-customers-service:${VERSION}
docker push ${REPOSITORY_PREFIX}/spring-animalclinic-admin-server:${VERSION}
docker push ${REPOSITORY_PREFIX}/spring-animalclinic-genai-service:${VERSION}
