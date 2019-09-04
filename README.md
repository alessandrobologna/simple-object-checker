# Simple Object Checker
Check if an object with specified name pattern exists on s3 on a schedule, emits a error log in CloudWatch logs, and creates a custom metric for the log. An alarm can then be created based on the desired criteria on this metric.

## Use case
Every time you need to know if a backup ran or not...

## Setup

1. Create and activate a Python Virtual Environment:

```bash
python3 -m pip install --user virtualenv
python3 -m virtualenv venv
source venv/bin/activate
```

2. Install SAM

```bash
pip install --upgrade aws-sam-cli
```

## Configuration

Some environment variables need to be configured before deployment:

NAME|DESCRIPTION|DEFAULT
---|---|---
STAGE|an identifier for the deployment stage, such as "dev" or "prod"|dev
UPSTREAM|The url for the service to be proxied|https://www.example.com/
SCHEDULE|A schedule expression for CloudWatch Events|cron(0 12 * * ? *)
BUCKET_NAME|The bucket to check|example-bucket
OBJECT_PATTERN|A python strftime compatibile pattern to locate the object|path/to/sample-%Y-%m-%d

## Deployment

Run `make` to get a list of make targets:

```bash
$ make
Commands:
all                            build all (including runtime)
bucket                         creates the bucket for the lambda code
build                          run sam build
clean                          removes build artifacts
deploy                         run sam deploy
package                        run sam package
redeploy                       build, package and deploy
runtime                        build the lambda runtime layer
```

Run the `make bucket` target to create an s3 bucket for the code deployment. It needs to be done only once, and it will create a bucket named <aws-account-number>.sam.code.

After exporting the required environment variables, run `make all` to build the base lambda layer, and deploy to your AWS account. For subsequent deployments you can just run `make redeploy`