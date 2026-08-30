import dotenv from 'dotenv';
dotenv.config();

import bcrypt from 'bcryptjs';
import prisma from '../src/config/db';

/**
 * CLI Access Recovery Script
 * Usage: npx ts-node scripts/reset-password.ts --email=user@example.com --password=newpassword
 */
async function main() {
  const args = process.argv.slice(2);
  let email = '';
  let newPassword = '';

  args.forEach((arg) => {
    if (arg.startsWith('--email=')) {
      email = arg.replace('--email=', '').trim();
    } else if (arg.startsWith('--password=')) {
      newPassword = arg.replace('--password=', '').trim();
    }
  });

  if (!email || !newPassword) {
    console.error('Usage error: Please provide both --email and --password arguments.');
    console.error('Example: npx ts-node scripts/reset-password.ts --email=admin@habos.local --password=MyNewSecretPass123!');
    process.exit(1);
  }

  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    console.error(`User with email "${email}" not found in database.`);
    process.exit(1);
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);

  await prisma.user.update({
    where: { id: user.id },
    data: { password: hashedPassword },
  });

  // Revoke all existing refresh tokens for security
  const revokedCount = await prisma.refreshToken.deleteMany({
    where: { userId: user.id },
  });

  console.log(`✅ Success: Password for user "${email}" (${user.name || 'User'}) has been updated successfully.`);
  console.log(`🔒 Revoked ${revokedCount.count} active refresh token session(s).`);
}

main()
  .catch((err) => {
    console.error('Error resetting password:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
