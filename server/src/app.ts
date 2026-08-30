import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import errorHandler from './middleware/errorHandler';

import authRoutes from './modules/auth/auth.routes';
import taskRoutes from './modules/tasks/tasks.routes';
import scheduleRoutes from './modules/schedule/schedule.routes';
import habitRoutes from './modules/habits/habits.routes';
import focusRoutes from './modules/focus/focus.routes';
import projectRoutes from './modules/projects/projects.routes';
import courseRoutes from './modules/courses/courses.routes';
import gymRoutes from './modules/gym/gym.routes';
import financeRoutes from './modules/finance/finance.routes';
import goalRoutes from './modules/goals/goals.routes';
import vaultRoutes from './modules/vault/vault.routes';
import aiRoutes from './modules/ai/ai.routes';
import lifeScoreRoutes from './modules/lifescore/lifescore.routes';
import dashboardRoutes from './modules/dashboard/dashboard.routes';
import searchRoutes from './modules/search/search.routes';
import notificationRoutes from './modules/notifications/notifications.routes';
import integrationRoutes from './modules/integrations/integrations.routes';
import techRoutes from './modules/tech/tech.routes';
import analyticsRoutes from './modules/analytics/analytics.routes';

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Health Check
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// Domain API Routes (Complete 24 Modules)
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/lifescore', lifeScoreRoutes);
app.use('/api/v1/tasks', taskRoutes);
app.use('/api/v1/schedule', scheduleRoutes);
app.use('/api/v1/habits', habitRoutes);
app.use('/api/v1/focus', focusRoutes);
app.use('/api/v1/projects', projectRoutes);
app.use('/api/v1/courses', courseRoutes);
app.use('/api/v1/gym', gymRoutes);
app.use('/api/v1/finance', financeRoutes);
app.use('/api/v1/goals', goalRoutes);
app.use('/api/v1/vault', vaultRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/search', searchRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/integrations', integrationRoutes);
app.use('/api/v1/tech', techRoutes);
app.use('/api/v1/analytics', analyticsRoutes);

// Global Error Handler
app.use(errorHandler);

export default app;
