import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  ScanCommand,
  PutCommand,
  GetCommand,
  DeleteCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});

const dynamo = DynamoDBDocumentClient.from(client);

const tableName = "appointments";

export const handler = async (event, context) => {
  let body;
  let statusCode = 200;
  const headers = {
    "Content-Type": "application/json",
  };

  try {
    switch (event.routeKey) {
      case "DELETE /appointments/{id}":
        await dynamo.send(
          new DeleteCommand({
            TableName: 'appointments',
            Key: {
              id: event.pathParameters.id,
            },
          })
        );
        body = `Deleted appointment ${event.pathParameters.id}`;
        break;
      case "GET /appointments/{id}":
        body = await dynamo.send(
          new GetCommand({
            TableName: 'appointments',
            Key: {
              id: event.pathParameters.id,
            },
          })
        );
        body = body.Item;
        break;
      case "GET /appointments":
        body = await dynamo.send(
          new ScanCommand({ TableName: 'appointments' })
        );
        body = body.Items;
        break;
      case "PUT /items":
        let requestJSON = JSON.parse(event.body);
        await dynamo.send(
          new PutCommand({
            TableName: 'appointments',
            Item: {
              name: requestJSON.name,
              email: requestJSON.email,
              service: requestJSON.service,
              date: requestJSON.date,
              time: requestJSON.time
            },
          })
        );
        body = `Success!`;
        break;
      default:
        throw new Error(`Unsupported route: "${event.routeKey}"`);
    }
  } catch (err) {
    statusCode = 400;
    body = err.message;
  } finally {
    body = JSON.stringify(body);
  }

  return {
    statusCode,
    body,
    headers,
  };
};
