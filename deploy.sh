#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

function _logger() {
    echo -e "$(date) ${YELLOW}[*] $@ ${NC}"
}

export PROJECT_ID=sam-rest

export AWS_PROFILE=default
export AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r '.Account' | tr -d '\n')
export AWS_REGION=${AWS_REGION:-"ap-southeast-1"}

export AWS_S3_BUCKET=${PROJECT_ID}-${AWS_ACCOUNT}
## aws s3api create-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION} || true
# aws s3api create-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION}
# aws s3api put-bucket-versioning --bucket ${S3_BUCKET} --versioning-configuration Status=Enabled

started_time=$(date '+%d/%m/%Y %H:%M:%S')

echo
echo "#########################################################"
_logger "[+] Verify the prerequisites environment"
echo "#########################################################"
echo

## DEBUG
echo "[x] Verify AWS CLI": $(aws  --version)
echo "[x] Verify git":     $(git  --version)
echo "[x] Verify jq":      $(jq   --version)
echo "[x] Verify nano":    $(nano --version)
echo "[x] Verify Docker":  $(docker version)
echo "[x] Verify Docker Deamon":  $(docker ps -q)
# echo "[x] Verify nvm":     $(nvm ls)
echo "[x] Verify Node.js": $(node --version)
echo "[x] Verify CDK":     $(cdk  --version)
echo "[x] Verify Python":  $(python  -V)
echo "[x] Verify Python3": $(python3 -V)
# echo "[x] Verify kubectl":  $(kubectl version --client)

echo $AWS_ACCOUNT + $AWS_REGION + $AWS_S3_BUCKET
currentPrincipalArn=$(aws sts get-caller-identity --query Arn --output text)
## Just in case, you are using an IAM role, we will switch the identity from your STS arn to the underlying role ARN.
currentPrincipalArn=$(sed 's/\(sts\)\(.*\)\(assumed-role\)\(.*\)\(\/.*\)/iam\2role\4/' <<< $currentPrincipalArn)
echo $currentPrincipalArn

cdk bootstrap aws://${AWS_ACCOUNT}/${AWS_REGION} \
    --bootstrap-bucket-name ${AWS_S3_BUCKET} \
    --termination-protection \
    --tags cost=Job4U

# cat cicd-pipeline/config/config.ts
cd cicd-pipeline

echo "Install the dependencies, unit test, and build ..."
npm install
# npm run test
npm run build

rm -rf cdk.out/*.* cdk.context.json

started_time=$(date '+%d/%m/%Y %H:%M:%S')

echo
echo "#########################################################"
_logger "[+] [START] Deploy CI/CD Pipeline at ${started_time}"
echo "#########################################################"
echo

# cdk diff
# cdk synth
cdk deploy --all --require-approval never

## Commit code to the CodeCommit repository: 
## pip install git-remote-codecommit <-- cloud9.sh
# cd ../sam-rest
cd ..
git clone codecommit::ap-southeast-1://$PROJECT_ID dist/sam-rest

rsync -av -R sam-rest/ dist/

cd dist/sam-rest

git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

git config --global user.name "Thanh Nguyen"
git config --global user.email "nnthanh101@gmail.com"

# aws codecommit list-repositories
# git remote rm origin
git init
git add .
git commit -m "🚀 CI/CD Pipeline >> employee-service"
git remote add origin codecommit::$AWS_REGION://$PROJECT_ID
# git remote add origin codecommit::ap-southeast-1://sam-rest
# git remote add origin https://git-codecommit.$AWS_REGION.amazonaws.com/v1/repos/$PROJECT_ID
git push -u origin master

## Danger!!! Cleanup the CDK Stack
# echo "Cleanup the CDK Stack ..."
# cd ../../cicd-pipeline
# cdk destroy --require-approval never

ended_time=$(date '+%d/%m/%Y %H:%M:%S')
echo
echo "#########################################################"
echo -e "${RED} [END] CI/CD Pipeline at ${ended_time} - ${started_time} ${NC}"
echo "#########################################################"
echo
