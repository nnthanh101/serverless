import * as cdk from '@aws-cdk/core';

import s3 = require('@aws-cdk/aws-s3');
import codeCommit = require('@aws-cdk/aws-codecommit');
import codePipeline = require('@aws-cdk/aws-codepipeline');
import codePipelineActions = require('@aws-cdk/aws-codepipeline-actions');
import codeBuild = require('@aws-cdk/aws-codebuild');

import { configurationMetaData } from "../config/config";

/**
 * CI/CD Pipeline consists of Amazon CodePipeline, CodeCommit, CodeBuild, and CodeDeploy.
 */
export class CicdPipelineStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here

    /**
     * Step 1. Add codeCommitRepo as Source stage to CodePipeline.
     */

    /** [Developer Tools >> CodeArtifact] The code that defines your stack goes here */
    const artifactsBucket = new s3.Bucket(this, "ArtifactsBucket");

    /** [Developer Tools >> CodeCommit] Creating a CodeCommit repository for the sam-rest */
    const codeCommitRepo = new codeCommit.Repository(
      this,
      configurationMetaData.codeCommitRepoName,
      {
        repositoryName: configurationMetaData.codeCommitRepoName,
        description: "The CodeCommit repository",
      }
    );

    /** [Developer Tools >> CodePipeline] Pipeline creation starts */
    const pipeline = new codePipeline.Pipeline(this, 'CodePipeline', {
      artifactBucket: artifactsBucket
    });

    /** [CodePipeline >> Artifact] Declare source code as a artifact */
    const sourceOutput = new codePipeline.Artifact();
    
    /** 1. Add Source stage to Pipeline */
    pipeline.addStage({
      stageName: 'Source',
      actions: [
        new codePipelineActions.CodeCommitSourceAction({
          actionName: 'CodeCommit_Source',
          repository: codeCommitRepo,
          output: sourceOutput,
        }),
      ],
    });

    /**
     * Step 2. Add the buildProject as Build stage to the CodePipeline
     */
    
    /** Declare build output as artifacts */
    const buildOutput = new codePipeline.Artifact();

    /** Declare a new CodeBuild project */
    const buildProject = new codeBuild.PipelineProject(this, 'Build', {
      environment: { buildImage: codeBuild.LinuxBuildImage.AMAZON_LINUX_2_2 },
      environmentVariables: {
        'PACKAGE_BUCKET': {
          value: artifactsBucket.bucketName
        }
      }
    });

    /** Add the build stage to the Pipeline */
    pipeline.addStage({
      stageName: 'Build',
      actions: [
        new codePipelineActions.CodeBuildAction({
          actionName: 'CodeBuild',
          project: buildProject,
          input: sourceOutput,
          outputs: [buildOutput],
        }),
      ],
    });

    /** 
     * Step 3. Deploy stage 
     * 
     * 3.1. CreateChangeSet
     * 3.2. Deploy
     */
    pipeline.addStage({
      stageName: 'Deploy',
      actions: [
        new codePipelineActions.CloudFormationCreateReplaceChangeSetAction({
          actionName: 'CreateChangeSet',
          templatePath: buildOutput.atPath(configurationMetaData.samTemplatePath),
          stackName: configurationMetaData.samStackName,
          adminPermissions: true,
          changeSetName: configurationMetaData.samStackName + '-changeset',
          runOrder: 1
        }),
        new codePipelineActions.CloudFormationExecuteChangeSetAction({
          actionName: 'Deploy',
          stackName: configurationMetaData.samStackName,
          changeSetName: configurationMetaData.samStackName + '-changeset',
          runOrder: 2
        }),
      ]
    });

  }
}
