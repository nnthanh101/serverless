export PROJECT_ID=sam-rest

export AWS_PROFILE=default
export AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r '.Account' | tr -d '\n')
export AWS_REGION=${AWS_REGION:-"ap-southeast-1"}

export S3_BUCKET=${PROJECT_ID}-${AWS_ACCOUNT}-${AWS_REGION}
## aws s3api create-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION} || true
aws s3api create-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION}
aws s3api put-bucket-versioning --bucket ${S3_BUCKET} --versioning-configuration Status=Enabled

echo "Installing the dependencies & Unit-Testing ..."
npm install
npm run test

sam build
sam deploy --stack-name ${PROJECT_ID}                   \
           --template-file template.yml                 \
           --region ${AWS_REGION} --confirm-changeset --no-fail-on-empty-changeset \
           --capabilities CAPABILITY_NAMED_IAM          \
           --s3-bucket ${S3_BUCKET} --s3-prefix backend \
           --config-file samconfig.toml                 \
           --no-confirm-changeset                       \
           --tags \
              Project=${PROJECT_ID}

echo "Testing AWS cloud resources from local development environments ..."

echo "Please verify the Boto3 >> `pip3 install boto3` ..."
./get-vars.py ${PROJECT_ID} > local-env.json
          
## Unit Test
echo "Unit Test ..."
sam local invoke --env-vars local-env.json    \
          getAllItemsFunction                 \
          -e events/employee-service/event-get-all-items.json
         #  getByIdFunction                     \
         #  -e events/employee-service/event-get-by-id.json
         #  putItemFunction                     \
         #  -e events/employee-service/event-post-item.json 

## Integration Test
echo "Integration Test ..."
AWS_SAM_STACK_NAME=${PROJECT_ID} npm run integ-test

# echo "Template to create a cognito backend to use with HTTP APIs JWT authorizer. Includes option to add Cognito User Groups as custom scopes for route access."
# sam deploy --stack-name ${PROJECT_ID}                   \
#            --template-file template.cognito.yml         \
#            --region ${AWS_REGION} --confirm-changeset --no-fail-on-empty-changeset \
#            --capabilities CAPABILITY_NAMED_IAM          \
#            --s3-bucket ${S3_BUCKET} --s3-prefix backend \
#            --config-file samconfig.toml                 \
#            --no-confirm-changeset                       \
#            --tags \
#               Project=${PROJECT_ID}      

## Danger!!! Cleanup
# echo "Cleanup ..."
# aws cloudformation delete-stack --stack-name ${PROJECT_ID}