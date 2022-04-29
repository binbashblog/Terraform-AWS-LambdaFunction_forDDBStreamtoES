import boto3
import requests
import os
from requests_aws4auth import AWS4Auth

region = os.environ['ES_REGION'] 
service = 'es'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

host = os.environ['ES_HOST'] # the Amazon ES domain, with https://
index = 'lambda-index'
type = 'lambda-type'
url = host + '/' + index + '/' + type + '/'

headers = { "Content-Type": "application/json" }

def handler(event, context):
    count = 0
    print('==============================')
    print(event)    
    # 1) Iterate over each record
    try:
        for record in event['Records']:
            # 2) Get the primary key for use as the Elasticsearch ID
            id = record['dynamodb']['alertId']['S']
            
            # 3) Handle event by event type
            if record['eventName'] == 'INSERT':
                handle_insert(record)
            elif record['eventName'] == 'MODIFY':
                handle_modify(record)
            elif record['eventName'] == 'REMOVE':
                handle_remove(record)
        print('==============================')
        return "Success!"
    except Exception as e:
        print(e)
        print('====================')
        return "Error!"

def handle_insert(record):
    print("Received INSERT Event...handling it")
    # 4) Get NewImage and PUT into ES 
    document = record['dynamodb']['NewImage']
    r = requests.put(url + id, auth=awsauth, json=document, headers=headers)

    # 5) Print row added
    print('New row ADDED with alertId=' + id)
    print('INSERT event has been handled')

    count += 1
    return str(count) + ' records processed.'

def handle_modify(record):
    print("Received MODIFY Event...handling it")
    # 4) Get NewImage and POST into ES
    document = record['dynamodb']['NewImage']
    r = requests.post(url + id, auth=awsauth, json=document, headers=headers)

    # 5) Print row modified
    print('Existing row MODIFIED with alertId=' + id)
    print('MODIFY event has been handled')

    count += 1
    return str(count) + ' records processed.'

def handle_remove(record):
    print("Received REMOVED Event...handling it")
    # 4) Get OldImage and DELETE from ES
    document = record['dynamodb']['OldImage']
    r = requests.delete(url + id, auth=awsauth)

    # 5) Print row deleted
    print('DELETED row with alertId=' + id)
    print('REMOVE event has been handled')

    count += 1
    return str(count) + ' records processed.'
