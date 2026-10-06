import { spawn } from 'child_process';
import path from 'path';
import fs from 'fs';

const args = process.argv.slice(2).filter((arg) => !arg.startsWith('-'));
const testsDir = path.resolve(__dirname, '../tests');

// Find test files in tests/
const allTestFiles = fs
  .readdirSync(testsDir)
  .filter((f) => f.endsWith('.test.ts') || f.endsWith('.js'));

let targetFiles: string[] = [];
if (args.length > 0) {
  const pattern = args[0].toLowerCase();
  if (pattern === 'all') {
    targetFiles = allTestFiles;
  } else {
    targetFiles = allTestFiles.filter((f) => f.toLowerCase().includes(pattern));
  }
  if (targetFiles.length === 0) {
    console.error(`❌ No test files matching "${args[0]}" found in tests/`);
    process.exit(1);
  }
} else {
  targetFiles = allTestFiles;
}

console.log(`🚀 HabOS TypeScript Test Runner executing: ${targetFiles.join(', ')}\n`);

async function runTest(file: string): Promise<boolean> {
  const filePath = path.join(testsDir, file);
  return new Promise((resolve) => {
    const child = spawn('npx', ['tsx', filePath], {
      stdio: 'inherit',
      cwd: path.resolve(__dirname, '..'),
    });

    child.on('close', (code) => {
      resolve(code === 0);
    });
  });
}

async function main() {
  let passedCount = 0;
  let failedCount = 0;

  for (const file of targetFiles) {
    const success = await runTest(file);
    if (success) {
      passedCount++;
    } else {
      failedCount++;
    }
  }

  console.log(`\n========================================`);
  console.log(`Test Suites: ${passedCount} passed, ${failedCount} failed, ${targetFiles.length} total`);
  console.log(`========================================\n`);

  if (failedCount > 0) {
    process.exit(1);
  }
}

main();
