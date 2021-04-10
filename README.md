# DevSecOps-AWS

This guide will show you how to lauch a multi-account DevSecOps CodePipeline.

Currently only US-East-1 is supported.

1. Fill out the helper table below:

| Project Name     | my-pipeline       |
| Dev Acct #   | 111111111111 |
| Tools (DevOps) Acct # | 222222222222 |
| Target Acct #(s)   | 333333333333,444444444444 |

2. Create the stacks in order (use us-east-1), wait for each stack to fully complete before moving onto the next

Dev Account Stack

DevOps (Tools) Account Stack

Target Account Stacks

3. Log into the Dev account to create a code commit user
- Note the CodeCommit repo name
- Goto https://console.aws.amazon.com/iam/home?region=us-east-1#/users
- Add a user, with the appropriate permissions
- On the user summary, click the "Security credentials" tab
- Then Click the "Upload SSH public key" button and add your public key (ex. id_rsa.pub)
  Make a note of the SSH key ID
  
Update your .ssh/config as follows (enter the SSH Key ID for the user):
Host git-codecommit.*.amazonaws.com
User APKA...
IdentityFile ~/.ssh/id_rsa

- Clone the CodeCommit repo:
  git clone ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/<repo name>
  cd <repo name>
  wget https://securitydude-pipeline-demo.s3.amazonaws.com/stack-for-testing/pipeline-testing.zip
  unzip pipeline-testing.zip
  git checkout -b testing
  git add *.yaml
  git commit -m "Initial Commit"
  git push origin testing

4. Goto the DevOps (Tools) Account, and check CodePipeline. (Pipeline may take up to 2-3 minutes to start)
- The Source and Build Stages should Succeed (note your commit message shows for the "SourceAction"), and then "manually approve" the deployment
- The next stage is the "Release Lambda", which pushes the repo files to the s3 bucket in each of the target accounts.
- Once Lambda Succeeds, goto the target accounts, and view CodePipeline
- Again, Manually approve the deployment.
- Now CloudFormation will run
- Goto CloudFormation and view the resources it has created
- Repeat for any additional target accounts.

5. For testing:
Remove one of the cfn_nag suppression lines from sg1.yaml.
Commit the change to the repo.
A new pipeline run will trigger.
It will fail on the CodeBuild Step.
Goto Build-->Report history, and click on the latest report to view the results.

CodeBuild also checks for valid template syntax, for example, remove a : anywhere in the file and commit the change.  CodeBuild will fail and the bad template will not be released to the test/prod environments.
