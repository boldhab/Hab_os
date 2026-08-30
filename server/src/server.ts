import dotenv from 'dotenv';
dotenv.config();

import app from './app';
import logger from './utils/logger';
import { initNotificationScheduler } from './modules/notifications/notifications.service';

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  logger.info(`🚀 HABos TypeScript Server running on port ${PORT}`);
  initNotificationScheduler();
});
