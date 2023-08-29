import json
import requests

def open_handler(event, context):

    try:
        ip = requests.get("http://checkip.amazonaws.com/")
    except requests.RequestException as e:
        # Send some context about this error to Lambda Logs
        print(e)

        raise e

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello TF World",
            "location": ip.text.replace("\n", "")
        }),
    }
