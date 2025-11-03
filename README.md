# 🚀 AWS Track 1 — Deploy Node.js App to EC2 using AWS CI/CD Pipeline

โปรเจกต์นี้สาธิตการสร้าง **CI/CD Pipeline บน AWS**  
เพื่อให้เมื่อคุณ `git push` โค้ดขึ้น GitHub — ระบบจะ **Build และ Deploy ไปยัง EC2 อัตโนมัติ**

---

## 🧩 Architecture Overview

```
GitHub → CodePipeline → CodeBuild → S3 → CodeDeploy → EC2
```

**บริการที่ใช้**

- **GitHub** → Source code repository
- **AWS CodePipeline** → ตัว orchestration ควบคุมทุกขั้นตอน
- **AWS CodeBuild** → สร้าง build artifact
- **Amazon S3** → เก็บ artifact ที่ได้จาก build
- **AWS CodeDeploy** → Deploy จาก S3 ไปยัง EC2
- **Amazon EC2** → เครื่องจริงที่รันแอป Node.js

---

## ⚙️ Setup Steps

### 1. เตรียม Environment

```bash
export REGION=ap-southeast-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ARTIFACT_BUCKET=my-artifacts-$ACCOUNT_ID-$REGION
export GITHUB_OWNER=theerawatzuz
export GITHUB_REPO=aws-track1
export BRANCH=main
```

สร้าง S3 สำหรับเก็บ artifact:

```bash
aws s3 mb s3://$ARTIFACT_BUCKET --region $REGION
```

---

### 2. สร้าง IAM Roles

#### 🧱 CodeBuild Role

```bash
aws iam create-role --role-name CodeBuild-Ec2App-Role   --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "codebuild.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy --role-name CodeBuild-Ec2App-Role   --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess
```

ให้สิทธิ์เข้าถึง S3 artifact:

```bash
cat > /tmp/cb-s3-access.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": ["s3:GetObject","s3:PutObject","s3:DeleteObject"], "Resource": "arn:aws:s3:::$ARTIFACT_BUCKET/*" },
    { "Effect": "Allow", "Action": ["s3:GetBucketLocation","s3:ListBucket"], "Resource": "arn:aws:s3:::$ARTIFACT_BUCKET" }
  ]
}
EOF

aws iam put-role-policy --role-name CodeBuild-Ec2App-Role   --policy-name codebuild-artifact-bucket-access   --policy-document file:///tmp/cb-s3-access.json
```

---

#### ⚙️ CodeDeploy Role

```bash
aws iam create-role --role-name CodeDeploy-Ec2App-Role   --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "codedeploy.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy --role-name CodeDeploy-Ec2App-Role   --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole
```

---

#### 🧭 CodePipeline Role

ใช้ role ที่มีชื่อ `workshop-service` (หรือสร้างใหม่)  
แนบ policy สำคัญให้ครบ:

```bash
aws iam attach-role-policy --role-name workshop-service   --policy-arn arn:aws:iam::aws:policy/AWSCodeDeployFullAccess
aws iam attach-role-policy --role-name workshop-service   --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess
aws iam attach-role-policy --role-name workshop-service   --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-role-policy --role-name workshop-service   --policy-arn arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess
```

เพิ่มสิทธิ์ใช้ GitHub Connection:

```bash
cat > /tmp/use-connection.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "codestar-connections:UseConnection",
    "Resource": "$CONNECTION_ARN"
  }]
}
EOF

aws iam put-role-policy --role-name workshop-service   --policy-name pipeline-use-connection   --policy-document file:///tmp/use-connection.json
```

---

### 3. สร้าง CodeDeploy Application & Deployment Group

```bash
aws deploy create-application --application-name ec2-app

aws deploy create-deployment-group   --application-name ec2-app   --deployment-group-name ec2-app-dg   --service-role-arn arn:aws:iam::$ACCOUNT_ID:role/CodeDeploy-Ec2App-Role   --ec2-tag-filters Key=Role,Value=web,Type=KEY_AND_VALUE   --deployment-config-name CodeDeployDefault.AllAtOnce
```

---

### 4. สร้าง CodeBuild Project

```bash
aws codebuild create-project   --name ec2-app-build   --source type=CODEPIPELINE   --artifacts type=CODEPIPELINE   --environment type=LINUX_CONTAINER,computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:7.0   --service-role arn:aws:iam::$ACCOUNT_ID:role/CodeBuild-Ec2App-Role
```

---

### 5. สร้าง CodePipeline (GitHub → Build → Deploy)

สร้าง pipeline file `/tmp/pipeline.json`:

```json
{
  "pipeline": {
    "name": "ec2-app-pipeline",
    "roleArn": "arn:aws:iam::526703406914:role/service-role/workshop-service",
    "artifactStore": {
      "type": "S3",
      "location": "my-artifacts-526703406914-ap-southeast-1"
    },
    "stages": [
      {
        "name": "Source",
        "actions": [
          {
            "name": "GitHub",
            "actionTypeId": {
              "category": "Source",
              "owner": "AWS",
              "provider": "CodeStarSourceConnection",
              "version": "1"
            },
            "outputArtifacts": [{ "name": "src" }],
            "configuration": {
              "ConnectionArn": "arn:aws:codeconnections:ap-southeast-1:526703406914:connection/811b7aec-ffd9-43e3-bbed-6cd0928beee4",
              "FullRepositoryId": "theerawatzuz/aws-track1",
              "BranchName": "main",
              "DetectChanges": "true",
              "OutputArtifactFormat": "CODE_ZIP"
            }
          }
        ]
      },
      {
        "name": "Build",
        "actions": [
          {
            "name": "Build",
            "actionTypeId": {
              "category": "Build",
              "owner": "AWS",
              "provider": "CodeBuild",
              "version": "1"
            },
            "inputArtifacts": [{ "name": "src" }],
            "outputArtifacts": [{ "name": "build" }],
            "configuration": { "ProjectName": "ec2-app-build" }
          }
        ]
      },
      {
        "name": "Deploy",
        "actions": [
          {
            "name": "Deploy",
            "actionTypeId": {
              "category": "Deploy",
              "owner": "AWS",
              "provider": "CodeDeploy",
              "version": "1"
            },
            "inputArtifacts": [{ "name": "build" }],
            "configuration": {
              "ApplicationName": "ec2-app",
              "DeploymentGroupName": "ec2-app-dg"
            }
          }
        ]
      }
    ],
    "version": 1
  }
}
```

สร้าง pipeline:

```bash
aws codepipeline create-pipeline --cli-input-json file:///tmp/pipeline.json
```

---

### 6. สร้าง EC2 Instance

```bash
aws ec2 run-instances   --image-id ami-0f9fc25dd2506cf6d   --instance-type t3.micro   --iam-instance-profile Name=CodeDeployInstanceProfile   --key-name track1-key   --security-group-ids sg-xxxxxxx   --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Track1-Web},{Key=Role,Value=web}]'   --user-data file://install/codedeploy-agent.sh
```

---

### 7. เริ่ม Pipeline และตรวจสถานะ

```bash
aws codepipeline start-pipeline-execution --name ec2-app-pipeline
```

ตรวจสอบว่าแต่ละ stage สำเร็จหรือไม่:

```bash
aws codepipeline list-action-executions --pipeline-name ec2-app-pipeline   --query 'actionExecutionDetails[].{Stage:stageName,Status:status,Summary:output.executionResult.externalExecutionSummary}'
```

ดู Deployment ล่าสุด:

```bash
aws deploy list-deployments   --application-name ec2-app   --deployment-group-name ec2-app-dg   --query 'deployments[0]' --output text
```

---

### 8. ตรวจสอบใน EC2

```bash
ssh -i ~/Desktop/track1-key.pem ec2-user@<public-ip>
sudo tail -n 50 /var/log/ec2-app.log
```

เปิดเบราว์เซอร์หรือ curl:

```bash
curl http://<public-ip>:3000
```

ผลลัพธ์:

```
Hello from GitHub v2 Pipeline!
```

---

## 💰 ค่าใช้จ่ายโดยประมาณ

| Service        | ราคาโดยประมาณ        |
| -------------- | -------------------- |
| CodePipeline   | $1 / เดือน           |
| CodeBuild      | 100 นาทีแรกฟรี       |
| CodeDeploy     | ฟรี (EC2 targets)    |
| S3             | ~$0.01–0.02 ต่อเดือน |
| EC2 (t3.micro) | ฟรี (Free Tier)      |

---

## 🧠 สรุป

- ✅ **Build** อยู่ใน AWS CodeBuild (managed container)
- ✅ **Deploy** โดย CodeDeploy ไปยัง EC2
- ✅ **Trigger อัตโนมัติ** เมื่อมีการ `git push`
- ✅ **Pipeline ครบวงจร** (Source → Build → Deploy)

---
