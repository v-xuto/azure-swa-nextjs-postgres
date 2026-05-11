import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main(): Promise<void> {
  console.log('🌱 Seeding database...');

  const alice = await prisma.user.upsert({
    where: { email: 'alice@example.com' },
    update: {},
    create: {
      email: 'alice@example.com',
      name: 'Alice',
      items: {
        create: [
          { title: 'Create your app', description: 'Choose your frontend framework, ORM, and auth preferences to generate your Azure project.', completed: true },
          { title: 'Develop locally', description: 'Run your full stack locally with Docker PostgreSQL, SWA CLI, and hot reload across frontend and API.', completed: true },
        ],
      },
    },
  });

  const bob = await prisma.user.upsert({
    where: { email: 'bob@example.com' },
    update: {},
    create: {
      email: 'bob@example.com',
      name: 'Bob',
      items: {
        create: [
          { title: 'Deploy to Azure', description: 'Provision infrastructure and deploy your app in one command with azd up.', completed: false },
          { title: 'Set up CI/CD', description: 'Configure GitHub Actions with OIDC to auto-deploy on push with azd pipeline config.', completed: false },
        ],
      },
    },
  });

  console.log(`✅ Seeded ${alice.name} and ${bob.name}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
