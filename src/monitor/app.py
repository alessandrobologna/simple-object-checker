'''
Check on a schedule if a file exists based on a time pattern

see http://strftime.org/ for pattern reference
'''
import logging
import os
from datetime import datetime
import aws_lambda_logging
import boto3
import botocore

log = logging.getLogger()
s3 = boto3.client('s3')
OBJECT_PATTERN=os.environ['OBJECT_PATTERN']
BUCKET=os.environ['BUCKET']

def handler(event, context):
    aws_lambda_logging.setup(
        level=os.environ.get('LOGLEVEL', 'INFO'),
        aws_request_id=context.aws_request_id,
        boto_level='CRITICAL'
    )

    log.info(event)

    now = datetime.now()
    key = now.strftime(OBJECT_PATTERN)
    try:   
        s3.get_object(
            Bucket=BUCKET,
            Key=key
        )
        log.info(f'Found s3://{BUCKET}/{key}')
    except s3.exceptions.NoSuchKey:
        log.error(f'Missing object at s3://{BUCKET}/{key}')

