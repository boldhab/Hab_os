import env from './config/env';
import app from './app';
import logger from './utils/logger';
import { initScheduler } from './jobs/scheduler';

const PORT = env.PORT;

app.listen(PORT, () => {
  logger.info(`🚀 HABos TypeScript Server running on port ${PORT} [${env.NODE_ENV}]`);
  initScheduler();
});
