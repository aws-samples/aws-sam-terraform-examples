# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

from operator import truediv
import boto3
from botocore.config import Config
import json
import os
import uuid
import ptvsd

# ptvsd.enable_attach(address=('0.0.0.0', 9999), redirect_output=True)
# ptvsd.wait_for_attach()

client = boto3.client('dynamodb')
sts = boto3.client('sts')

DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME")
EVENT_DATA_FIELDS = ["BookTitle", "ReviewScore"]


def validate_event(event):
    print(event)
    valid_flag = True
    msg = None
    
    print(event['ReviewScore'])
    if not validate_review_score(event['ReviewScore']):
        valid_flag = False
        msg = "Review score is not valid"
    
    # Check if all data fields are present in the event
    if not all(k in event for k in EVENT_DATA_FIELDS):
        valid_flag = False
        msg = "Invalid input"
    
    return (valid_flag, msg)


def validate_review_score(score):
    if 1 <= int(score) <= 10:
        return True
    else:
        return False


def save_to_ddb(ddb_payload):
    return client.put_item(
        TableName=DYNAMODB_TABLE_NAME,
        Item=ddb_payload
    )


def lambda_handler(event, context):    
    processed_event = json.loads(event['body'])
    review_id = uuid.uuid4()
    response = None
    
    # Check if event data is valid
    event_validation, msg = validate_event(processed_event)

    if event_validation is True:

        ddb_payload = {
            'ReviewId': {
                'S': str(review_id)
            },
            'BookTitle': {
                'S': processed_event['BookTitle']
            },
            'ReviewScore': {
                'N': processed_event['ReviewScore']
            }
        }

        if "ReviewText" in processed_event:
            ddb_payload['ReviewText'] = {
                'S': processed_event['ReviewText']
            }

        data = save_to_ddb(ddb_payload)

        print(data)
        data['ResponseMetadata']['HTTPStatusCode']
        
        response = {
            'statusCode': 200,
            'body': 'successfully created item!',
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
        }

    else:
        response = {
            'statusCode': 400,
            'body': msg,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    
    return(response)
