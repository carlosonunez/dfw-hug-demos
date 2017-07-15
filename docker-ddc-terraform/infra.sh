#!/bin/bash

usage() {
  echo "./infra (plan|apply) [terraform_options]"
  echo "Runs a Terraform plan or deployment while fetching the latest terraform.tfvars."
  echo "**NOTE**: S3_INFRASTRUCTURE_BUCKET must be defined for your environment. \
Set it to the location of the terraform.tfvars file in S3."
  echo "**NOTE**: TARGET_ENVIRONMENT also needs to be set to the environment you wish to deploy."
  echo "**NOTE**: awscli must be installed. Install it with \"pip install awscli\"."
}

our_current_ip=$(curl -Ls http://canihazip.com/s | cut -f1 -d, | tr -d ' ')
our_current_region=$AWS_REGION

if [ "$1" != "plan" ] && [ "$1" != "apply" ]
then
  usage
  echo "ERROR: You can only run 'plan' or 'apply' with this script."
  echo "Use 'terraform' for any other Terraform subcommands"
  exit 1
elif [ "$1" == "help" ]
then
  usage
  exit 0
fi

if [ "$S3_INFRASTRUCTURE_BUCKET" == "" ]
then
  usage
  echo "ERROR: You must define S3_INFRASTRUCTURE_BUCKET before running this script."
  exit 1
fi

if [ "$TARGET_ENVIRONMENT" == "" ]
then
  usage
  echo "ERROR: TARGET_ENVIRONMENT needs to be defined in your environment \
before running this script."
  exit 1
fi

if [ "$(which aws)" == "" ]
then
  usage
  echo "ERROR: awscli must be installed for this script to work."
  exit 1
fi

if [ "$(which terraform)" == "" ]
then
  usage
  echo "ERROR: Terraform must be installed to run this script."
  exit 1
fi

terraform_tfvars_remote_path=\
  "s3://$S3_INFRASTRUCTURE_BUCKET/$TARGET_ENVIRONMENT/terraform.tfvars"
terraform_tfvars_fetch_result=\
  "$(aws s3 cp $terraform_tfvars_remote_path 'terraform.tfvars.new' 2>/dev/null; \
  echo $?)"
if [ "$terraform_tfvars_fetch_result" != "0" ]
then
  echo "ERROR: Could not fetch $terraform_tfvars_remote_path/terraform.tfvars."
  exit 1
fi

if [ -f "terraform.tfvars" ]
then
  unsaved_local_tfvars_changes="$(diff 'terraform.tfvars' 'terraform.tfvars.new' | \
    grep '<')"
  if [ "$unsaved_local_tfvars_changes" != "" ]
  then
    echo "ERROR: You have unsaved changes to your local Terraform tfvars. \
Please upload them before running this script again."
  else
    rm 'terraform.tfvars'
    mv 'terraform.tfvars.new' 'terraform.tfvars'
  fi 
fi

terraform get && \
terraform $1 -var "aws_region=$our_current_region" \
  -var "terraform_deployer_ip=$our_current_ip"
