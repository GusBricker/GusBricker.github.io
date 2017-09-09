---
layout:         post_colorful
title:          "ECS + Gitlab CI/CD Pipeline Skeleton"
subtitle:       "Automation!"
date:           2017-09-08
title_style:    "color:#80bfff"
subtitle_style: "color:#488bce"
author_style:   "color:#488bce"
header-img: "img/docker_plus_gitlab.png"
---


Automating container deployment is an important step into making your infrastructure easier to manage and scale. Administrators should be
moving away from nursing their systems into higher level thinking where you design once and then automate changes on top of that system.

Below is a useful starting point for a Gitlab CI skeleton for building and pushing Docker containers into Amazon's Elastic Container Service.

## Skeleton .gitlab-ci.yml

<!-- language: markdown-->
    variables:
        IMAGE_NAME: "amazing-image"
        CLUSTER_ARN: "ARN of ECS cluster"
        SERVICE_ARN: "ARN of ECS service"
        TASK_DEFINITION: "Task definition name in the service"
        ECR_ADDRESS: "Container registry address"
        ECS_REGION: "ECS region"

    stages:
        - build

    build_job:
        stage: build
        artifacts:
            paths:
                - task-definition-${CI_COMMIT_SHA}.json
            expire_in: 52 week
        script:
            - docker build -t "${IMAGE_NAME}" .
            - eval $(aws ecr get-login --no-include-email --region "${ECS_REGION}")
            - docker tag "${IMAGE_NAME}:latest" "${ECR_ADDRESS}:${CI_COMMIT_SHA}"
            - docker push "${ECR_ADDRESS}:${CI_COMMIT_SHA}"
            - sed -e "s;%BUILD_VERSION%;${CI_COMMIT_SHA};g" task-definition-base.json > task-definition-${CI_COMMIT_SHA}.json
            - aws ecs register-task-definition --family "${TASK_DEFINITION}" --cli-input-json "file://task-definition-${CI_COMMIT_SHA}.json"
            - aws ecs update-service --cluster "${CLUSTER_ARN}" --service "${SERVICE_ARN}" --task-definition "${TASK_DEFINITION}"


### Operational Breakdown

1. Build the image.
2. Log into ECR.
3. Tag the latest build we have produced with the ECR address and the commit hash.
4. Create a new task defintion file locally based off the "base" version in the repository. The new task definition is locked to the version of the docker image produced by replacing the `%BUILD_VERSION%` parameter with the commit hash.
5. Register the new task definition with ECR.
6. Tell the service to use the latest task definition available (by not specifying a revision with the `--task-definition` switch) which will be the new one registered in the previous step.

A base task definition is required, a oneliner to generate this based on an existing task defintion:
`aws ecs describe-task-definition --task-definition <TASK_DEFINITION_NAME> | jq $({containerDefinitions: .taskDefinition.containerDefinitions, volumes: .taskDefinition.volumes}) | jq $(.containerDefinitions[0].image=)\"<ECR_ADDRESS>:%BUILD_VERSION%\" > task-definition-base.json`

The `<TASK_DEFINITION_NAME>` and `<ECR_ADDRESS>` should be replaced with appropriate values to match your setup and the `%BUILD_VERSION%` placeholder should be
left in the base file as build **step 4** will replace this with the commit hash.


### Docker and CI/CD Quirks

As of writing, Docker 17.06.0 doesn't gracefully cleanup stale images. This will cause your CI server's disk to fill up pretty quickly. A good tool to
cleanup old containers is [docker-gc](https://github.com/spotify/docker-gc).

Given your CI server should be pushing the images to a registry somewhere, there is usually no point keeping old images around. Therefore running docker-gc in an hourly CRON job as shown: `MINIMUM_IMAGES_TO_SAVE=1 FORCE_IMAGE_REMOVAL=1 /usr/sbin/docker-gc` should help alleviate maintenance.


### Further Enhancements/Considerations

- The skeleton has no concept of production/testing environments.
- ECR has a limit of 1000 images and needs to be cleaned up periodically.


### Useful Sources
[1](https://aws.amazon.com/blogs/devops/set-up-a-build-pipeline-with-jenkins-and-amazon-ecs)
[2](https://stackoverflow.com/questions/31485031/ecs-service-automating-deploy-with-new-docker-image)
[3](https://serverfault.com/questions/682340/update-the-container-of-a-service-in-amazon-ecs)
