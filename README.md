# Simple Trivia Service - a Serverless Single and Multi-player Trivia Game

This application shows how to build both single and multiplayer games using Serverless architectures and managed services from AWS.  Information about how this project works and how serverless architectures perform was published on the blog [Building a serverless multi-player game that scales](https://aws.amazon.com/blogs/compute/building-a-serverless-multiplayer-game-that-scales/).

Important: this application uses various AWS services and there are costs associated with these services after the Free Tier usage - please see the [AWS Pricing page](https://aws.amazon.com/pricing/) for details. You are responsible for any AWS costs incurred. No warranty is implied in this example.

## Project Organization

```bash
.
├── README.MD                   <-- This instructions file
├── backend                     <-- Source code for the serverless backend
├── frontend                    <-- Source code for the Vue.js frontend
```

## Requirements
1. An [AWS Account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html)
2. A [Terraform Cloud Account](https://app.terraform.io/signup/account)
3. [AWS CLI >= v1.18 installed](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) and [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) with Admin privileges
4. [Terraform CLI => 0.15.0 installed](https://tfswitch.warrensbox.com/Install/)
5. [AWS CDK v1.57.0 installed](https://docs.aws.amazon.com/cdk/latest/guide/getting_started.html#getting_started_install)
6. [NodeJS v12.x installed](https://nodejs.org/en/download/package-manager/)
7. [Vue.js and Vue CLI (v. 4.5) installed](https://vuejs.org/v2/guide/installation.html)
8. Optional [AWS Amplify installed and configured to access the account you are using](https://docs.amplify.aws/cli/start/install)

## Installation Instructions
The installation instructions are broken down into three parts, starting with the backend, deploying a dashboard, and concluding with the frontend.

### Backend Setup

This set of steps will deploy a number of AWS resources to your account, including DynamoDB tables, Lambda functions, API Gateway instances, and Cognito User Pools.