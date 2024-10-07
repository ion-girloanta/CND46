import boto3
import json
import os

# Initialize SQS client for Region A and Region B
sqs_a = boto3.client('sqs', region_name=os.environ['REGION_A'])
sqs_b = boto3.client('sqs', region_name=os.environ['REGION_B'])

def lambda_handler(event, context):
    # Loop through each record in the SQS event
    for record in event['Records']:
        # Extract message body from the SQS event
        message_body = record['body']

        # Forward the message to Region B's SQS queue
        response = sqs_b.send_message(
            QueueUrl=os.environ['QUEUE_URL_REGION_B'],  # The SQS queue URL for Region B
            MessageBody=message_body
        )

        print(f"Message forwarded to Region B: {response['MessageId']}")

    return {
        'statusCode': 200,
        'body': json.dumps('Message forwarded successfully')
    }
