import {
  app,
  HttpRequest,
  HttpResponseInit,
  InvocationContext,
} from '@azure/functions';

app.http('health', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'health',
  handler: async (
    request: HttpRequest,
    context: InvocationContext
  ): Promise<HttpResponseInit> => {
    context.log('Health check requested');

    return {
      jsonBody: {
        status: 'ok',
        timestamp: new Date().toISOString(),
      },
    };
  },
});
