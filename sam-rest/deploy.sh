export PROJECT_ID=sam-rest
export AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r '.Account' | tr -d '\n')
export AWS_REGION=${AWS_REGION:-"ap-southeast-1"}

export S3_BUCKET=${PROJECT_ID}-${AWS_ACCOUNT}-${AWS_REGION}
## aws s3api create-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION} || true
aws s3api create-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION}
aws s3api put-bucket-versioning --bucket ${S3_BUCKET} --versioning-configuration Status=Enabled

echo "Installing the dependencies & Unit-Testing ..."
npm install
npm run test

sam deploy --stack-name ${PROJECT_ID}                   \
           --region ${AWS_REGION} --confirm-changeset --no-fail-on-empty-changeset \
           --capabilities CAPABILITY_NAMED_IAM          \
           --s3-bucket ${S3_BUCKET} --s3-prefix backend \
           --config-file samconfig.toml                 \
           --no-confirm-changeset                       \
           --tags \
              Project=${PROJECT_ID}

echo "Testing AWS cloud resources from local development environments ..."
./get-vars.py sam-rest > local-env.json
          
sam local invoke --env-vars local-env.json    \
          getAllItemsFunction                 \
          -e events/employee-service/event-get-all-items.json
         #  getByIdFunction                     \
         #  -e events/employee-service/event-get-by-id.json
         #  putItemFunction                     \
         #  -e events/employee-service/event-post-item.json         