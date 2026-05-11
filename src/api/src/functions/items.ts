import {
  app,
  HttpRequest,
  HttpResponseInit,
  InvocationContext,
} from '@azure/functions';
import { getPrisma } from '../lib/db.js';

// GET /api/items
app.http('listItems', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'items',
  handler: async (
    request: HttpRequest,
    context: InvocationContext
  ): Promise<HttpResponseInit> => {
    const prisma = getPrisma();
    const items = await prisma.item.findMany({ orderBy: { createdAt: 'desc' } });
    return { jsonBody: items };
  },
});

// GET /api/items/{id}
app.http('getItem', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'items/{id}',
  handler: async (
    request: HttpRequest,
    context: InvocationContext
  ): Promise<HttpResponseInit> => {
    const id = Number(request.params.id);
    if (isNaN(id)) {
      return { status: 400, jsonBody: { error: 'Invalid item ID' } };
    }

    const prisma = getPrisma();
    const item = await prisma.item.findUnique({ where: { id } });
    if (!item) {
      return { status: 404, jsonBody: { error: 'Item not found' } };
    }

    return { jsonBody: item };
  },
});

// POST /api/items
app.http('createItem', {
  methods: ['POST'],
  authLevel: 'anonymous',
  route: 'items',
  handler: async (
    request: HttpRequest,
    context: InvocationContext
  ): Promise<HttpResponseInit> => {
    const body = (await request.json()) as {
      title?: string;
      description?: string;
      userId?: number;
    };

    if (!body.title) {
      return { status: 400, jsonBody: { error: 'Title is required' } };
    }
    if (!body.userId) {
      return { status: 400, jsonBody: { error: 'userId is required' } };
    }

    const prisma = getPrisma();
    const item = await prisma.item.create({
      data: {
        title: body.title,
        description: body.description ?? null,
        userId: body.userId,
      },
    });

    return { status: 201, jsonBody: item };
  },
});

// PUT /api/items/{id}
app.http('updateItem', {
  methods: ['PUT'],
  authLevel: 'anonymous',
  route: 'items/{id}',
  handler: async (
    request: HttpRequest,
    context: InvocationContext
  ): Promise<HttpResponseInit> => {
    const id = Number(request.params.id);
    if (isNaN(id)) {
      return { status: 400, jsonBody: { error: 'Invalid item ID' } };
    }

    const prisma = getPrisma();
    const existing = await prisma.item.findUnique({ where: { id } });
    if (!existing) {
      return { status: 404, jsonBody: { error: 'Item not found' } };
    }

    const body = (await request.json()) as {
      title?: string;
      description?: string;
      completed?: boolean;
    };

    const item = await prisma.item.update({
      where: { id },
      data: {
        ...(body.title !== undefined && { title: body.title }),
        ...(body.description !== undefined && { description: body.description }),
        ...(body.completed !== undefined && { completed: body.completed }),
      },
    });

    return { jsonBody: item };
  },
});

// DELETE /api/items/{id}
app.http('deleteItem', {
  methods: ['DELETE'],
  authLevel: 'anonymous',
  route: 'items/{id}',
  handler: async (
    request: HttpRequest,
    context: InvocationContext
  ): Promise<HttpResponseInit> => {
    const id = Number(request.params.id);
    if (isNaN(id)) {
      return { status: 400, jsonBody: { error: 'Invalid item ID' } };
    }

    const prisma = getPrisma();
    const existing = await prisma.item.findUnique({ where: { id } });
    if (!existing) {
      return { status: 404, jsonBody: { error: 'Item not found' } };
    }

    await prisma.item.delete({ where: { id } });
    return { status: 204 };
  },
});
