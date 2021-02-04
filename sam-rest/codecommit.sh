export PROJECT_ID=sam-rest
# export AWS_PROFILE=default
# export AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r '.Account' | tr -d '\n')
export AWS_REGION=${AWS_REGION:-"ap-southeast-1"}

git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

git config --global user.name "Thanh Nguyen"
git config --global user.email "nnthanh101@gmail.com"

## aws codecommit list-repositories
## git remote rm origin
# git init
git add .
git commit -m "🚀 CI/CD Pipeline >> employee-service"
# git remote add origin codecommit::$AWS_REGION://$PROJECT_ID
## git remote add origin codecommit::ap-southeast-1://sam-rest
## git remote add origin https://git-codecommit.$AWS_REGION.amazonaws.com/v1/repos/$PROJECT_ID
# git push -u origin master
git push
