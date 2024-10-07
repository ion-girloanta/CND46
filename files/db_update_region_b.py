import boto3
import json
import os
import pymysql  # or psycopg2 for PostgreSQL

# Initialize the RDS database connection
def connect_to_db():
    return pymysql.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        db=os.environ['DB_NAME']
    )

def lambda_handler(event, context):
    # Loop through each record in the SQS event
    for record in event['Records']:
        # Extract message body
        message_body = json.loads(record['body'])

        product_id = message_body['product_id']
        quantity = message_body['quantity']

        # Connect to the database and update stock
        connection = connect_to_db()
        try:
            with connection.cursor() as cursor:
                # Update stock in the database (adjust query to your schema)
                update_query = "UPDATE products SET stock = stock - %s WHERE product_id = %s"
                cursor.execute(update_query, (quantity, product_id))
                connection.commit()
        finally:
            connection.close()

    return {
        'statusCode': 200,
        'body': json.dumps('Stock updated successfully')
    }
