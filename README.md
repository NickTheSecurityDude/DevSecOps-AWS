# DevSecOps-AWS

This guide will show you how to lauch a multi-account DevSecOps CodePipeline.

In order to help protect your supply chain (Development Operation) its important to reduce your blast radius and enforce separate of duties.  Therefore, for pipelines its important to use multiple accounts.  Typically this would be one dev account for the developers, which will contain your CodeCommit repos, then a second account will contain your DevOps tools, so your build server, pipeline, artifact bucket etc, and the rest of the accounts will be your differen environments, ex. test, prod, etc.

We turn CodePipeline into a DevSecOps pipeline by using CFN_NAG to check out templates for common security issues before deploying them.

Currently only US-East-1 is supported.

Here's how to get started:

1. Create a helper table like the below:

| Field      | Value |
| ----------- | ----------- |
| Project Name     | my-pipeline       |
| Dev Acct #   | 111111111111 |
| Tools (DevOps) Acct # | 222222222222 |
| Target Acct #(s)   | 333333333333,444444444444 |

2. Create the three stacks in order (use us-east-1), wait for each stack to fully complete and log out before moving onto the next,  if you have multiple targets, run the target stack in each of the target accounts.

| Order | Stack     | Launch |
| --------- | ----------- | ----------- |
| 1 | Dev Account Stack | [![Dev Account Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png "Launch Dev Account Stack")](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=dev-stack&templateURL=https://securitydude-pipeline-demo.s3.amazonaws.com/dev-templates/pipeline-MASTER.yaml) |
| 2 | DevOps (Tools) Account Stack | [![DevOps (Tools) Account Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png "Launch DevOps (Tools) Account Stack")](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=devops-stack&templateURL=https://securitydude-pipeline-demo.s3.amazonaws.com/devops-templates/pipeline-MASTER.yaml) |
| 3 | Target Account Stack(s) | [![Target Account Stack(s)](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png "Target Account Stack(s) Stack")](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=target-stack&templateURL=https://securitydude-pipeline-demo.s3.amazonaws.com/target-templates/pipeline-MASTER.yaml) |

3. Log into the Dev account to create a code commit user
- Note the CodeCommit repo name
- Goto https://console.aws.amazon.com/iam/home?region=us-east-1#/users
- Add a user, with the appropriate permissions
- On the user summary, click the "Security credentials" tab
- Then Click the "Upload SSH public key" button and add your public key (ex. id_rsa.pub)
  Make a note of the SSH key ID
  
Update your .ssh/config as follows (enter the SSH Key ID for the user):
```
Host git-codecommit.*.amazonaws.com
User APKA...
IdentityFile ~/.ssh/id_rsa
```

- Clone the CodeCommit repo:
```
git clone ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/<repo name>
cd <repo name>
wget https://securitydude-pipeline-demo.s3.amazonaws.com/stack-for-testing/pipeline-testing.zip
unzip pipeline-testing.zip
git checkout -b testing
git add *.yaml
git commit -m "Initial Commit"
git push origin testing
```

4. Goto the DevOps (Tools) Account, and check CodePipeline. (Pipeline may take up to 2-3 minutes to start)
- The Source and Build Stages should Succeed (note your commit message shows for the "SourceAction"), and then "manually approve" the deployment
- The next stage is the "Release Lambda", which pushes the repo files to the s3 bucket in each of the target accounts.
- Lambda will Succeed.
 
5. Now, goto the target accounts, and view CodePipeline
- Again, Manually approve the deployment.
- Now CloudFormation will run
- Goto CloudFormation and view the resources it has created
- Repeat for any additional target accounts.

6. For testing:
Remove one of the cfn_nag suppression lines from sg1.yaml.
Commit the change to the repo.
A new pipeline run will trigger.
It will fail on the CodeBuild Step.
Goto Build-->Report history, and click on the latest report to view the results.

7. CodeBuild also checks for valid template syntax, for example, remove a : anywhere in the file and commit the change.  CodeBuild will fail and the bad template will not be released to the test/prod environments.

(c) Copyright 2021 - NickTheSecurityDude

Disclaimer:
For informational/educational purposes only. Bugs are likely and can be reported on github.
Using this will incur AWS charges.
