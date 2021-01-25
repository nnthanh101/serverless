export PROJECT_ID=sam-app
export AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r '.Account' | tr -d '\n')
export AWS_REGION=${AWS_REGION:-"ap-southeast-1"}

export S3_BUCKET=${PROJECT_ID}-${AWS_ACCOUNT}-${AWS_REGION}
## aws s3api create-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION} || true
aws s3api create-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION}
aws s3api put-bucket-versioning --bucket ${S3_BUCKET} --versioning-configuration Status=Enabled

echo "Installing the dependencies & Unit-Testing ..."
cd docker
npm install
npm run test
cd ..

echo "Testing AWS cloud resources from local development environments ..."
sam build --cached --parallel

## Unit Test
echo "Unit Test ..."
sam local invoke CrawlFunction --event events/event.json

## Integration Test
echo "run the API locally on port 3000 ..."
echo sam local start-api
echo curl http://127.0.0.1:3000/crawl

## Create a new ECR repository to store the Container Image 
aws ecr create-repository --repository-name ${PROJECT_ID}  \
                          --image-tag-mutability IMMUTABLE \
                          --image-scanning-configuration scanOnPush=true

aws ecr get-login-password \
        --region ${AWS_REGION} | docker login --username AWS \
        --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com                          

## Deploying in a CI/CD pipeline
sam package --output-template-file packaged-template.yaml \
            --image-repository ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_ID}

## Deploying the Application
## For multiple repositories
## --image-repositories CrawlFunction=${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_ID} \
sam deploy --stack-name ${PROJECT_ID}                   \
           --template-file packaged-template.yaml       \
           --image-repository ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_ID} \
           --s3-bucket ${S3_BUCKET} --s3-prefix ${PROJECT_ID}                        \
           --region ${AWS_REGION} --confirm-changeset --no-fail-on-empty-changeset   \
           --capabilities CAPABILITY_NAMED_IAM          \
           --config-file samconfig.toml                 \
           --no-confirm-changeset                       \
           --tags \
              Project=${PROJECT_ID}

# echo "Please verify the Boto3 >> `pip3 install boto3` ..."
# ./get-vars.py ${PROJECT_ID} > local-env.json
# sam logs -n CrawlFunction --stack-name ${PROJECT_ID} --tail

## Danger!!! Cleanup
# echo "Cleanup ..."
# aws cloudformation delete-stack --stack-name ${PROJECT_ID}