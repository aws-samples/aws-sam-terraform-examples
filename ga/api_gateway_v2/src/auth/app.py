import json

def handler(event, context):
    response = {"isAuthorized": False}

    if event["headers"]["Myheader"] == "123456789":
        response["isAuthorized"] = True
    
    return response