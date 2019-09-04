STAGE ?= "dev"
BUCKET_NAME ?= "example-bucket"
PROJECT ?= "sam-s3-monitor"
REGION ?= "$(shell aws configure get region)"
CODE_BUCKET ?= "$(shell aws sts get-caller-identity --query "Account" --output text).sam.code"
PYTHON_VERSION ?= "python3.7"
SCHEDULE ?= "cron(0 12 * * ? *)"
OBJECT_PATTERN ?= path/to/sample-%Y-%m-%d
BUCKET_NAME ?= example-bucket
.PHONY: help runtime clean bucket build package deploy redeploy undeploy

help:
	@echo "Commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


clean:  ## removes build artifacts
	@rm -rf .aws-sam  runtime/python

bucket:  ## creates the bucket for the lambda code
	@aws s3api create-bucket --bucket $(CODE_BUCKET) --region $(REGION) >/dev/null \
		&& printf "> \033[36mBucket s3://$(CODE_BUCKET) created\033[0m\n"

runtime: ## build the lambda runtime layer
	@printf "> \033[36mBuilding Runtime Layer...\033[0m\n"
	@PY_DIR=runtime/python/lib/$(PYTHON_VERSION)/site-packages &&\
	rm -rf $$PY_DIR && mkdir -p $$PY_DIR &&\
	pip install -r runtime/requirements.txt -t $$PY_DIR --no-warn-conflicts --ignore-installed --quiet
	@printf "> \033[36mCompleted\033[0m\n"


build: ## run sam build
	@printf "> \033[36mBuilding Application...\033[0m\n"
	@sam build --parameter-overrides ParameterKey=PythonVersion,ParameterValue=$(PYTHON_VERSION) >/dev/null
	@printf "> \033[36mCompleted\033[0m\n"

package: ## run sam package
	@printf "> \033[36mPackaging Application...\033[0m\n"
	@aws cloudformation package --s3-bucket $(CODE_BUCKET) --template-file .aws-sam/build/template.yaml --output-template-file .aws-sam/build/packaged.yaml >/dev/null
	@printf "> \033[36mCompleted\033[0m\n"

deploy: ## run sam deploy
	@printf "> \033[36mDeploying Application...\033[0m\n"
	@aws cloudformation deploy --template-file .aws-sam/build/packaged.yaml --stack-name cf-stack-$(PROJECT)-$(STAGE) --capabilities CAPABILITY_IAM \
		--parameter-overrides \
		Stage=$(STAGE) \
		ProjectName=$(PROJECT) \
		BucketName=$(BUCKET_NAME) \
		ObjectPattern=$(OBJECT_PATTERN) \
		Schedule='$(SCHEDULE)'
	@printf "> \033[36mCompleted\033[0m\n"


redeploy: build package deploy ## build, package and deploy
	@printf " \033[33mAll services built, packaged and deployed!\033[0m\n"

all: runtime build package deploy ## build all (including runtime)
	@printf " \033[33mCreated runtime, built all services, packaged and deployed!\033[0m\n"

undeploy: ## run aws cloudformation delete stack
	@aws cloudformation delete-stack --stack-name cf-stack-$(PROJECT)-$(STAGE) &&\
	aws cloudformation wait stack-delete-complete --stack-name cf-stack-$(PROJECT)-$(STAGE)
	@printf " \033[33mAll resources undeployed!\033[0m\n"
