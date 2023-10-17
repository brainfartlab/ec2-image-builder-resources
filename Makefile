ifndef AWS_PROFILE
	AWS_PROFILE=default
endif

AWS_ACCOUNT=$(shell aws sts get-caller-identity --profile $(AWS_PROFILE) | jq -r '.Account')

STACK=ImageBuilderResources

CFN_PACKAGED=packaged.yml
CFN_LOCATION=cfn-assets-$(AWS_ACCOUNT)

ib-upload:
	aws s3 sync components s3://$(CFN_LOCATION)/ib/components

cfn-package: ib-upload
	aws cloudformation package \
		--profile $(AWS_PROFILE) \
		--template-file template.yml \
		--s3-bucket $(CFN_LOCATION) \
		--s3-prefix packages \
		--output-template-file $(CFN_PACKAGED)

cfn-deploy: cfn-package
	aws cloudformation deploy \
		--profile $(AWS_PROFILE) \
		--template-file $(CFN_PACKAGED) \
		--stack-name $(STACK) \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			AssetsBucket=$(CFN_LOCATION) \
			VpcId=$(VPC_ID) \
			SubnetId=$(SUBNET_ID)

cfn-delete:
	aws cloudformation delete-stack \
		--profile $(AWS_PROFILE) \
		--stack-name $(STACK)
