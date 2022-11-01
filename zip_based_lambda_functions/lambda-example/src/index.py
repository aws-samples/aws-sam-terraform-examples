# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import json

def lambda_handler(event, context):
    event_body = json.loads(event['body'])
    print(event_body)

    return {
        'statusCode': 200,
        'body': "Request Received!",
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        }
    }
