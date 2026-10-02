import { Response } from 'express';
import EventEmitter from 'events';
import logger from '../../utils/logger';

class ProjectEventBus extends EventEmitter {
  private clients: Map<string, Set<Response>> = new Map();

  addClient(projectId: string, res: Response) {
    if (!this.clients.has(projectId)) {
      this.clients.set(projectId, new Set());
    }
    this.clients.get(projectId)!.add(res);
    logger.debug(`[ProjectEventBus] Client connected for project ${projectId}. Total clients: ${this.clients.get(projectId)!.size}`);
  }

  removeClient(projectId: string, res: Response) {
    const set = this.clients.get(projectId);
    if (set) {
      set.delete(res);
      logger.debug(`[ProjectEventBus] Client disconnected for project ${projectId}. Remaining clients: ${set.size}`);
      if (set.size === 0) {
        this.clients.delete(projectId);
      }
    }
  }

  emitProjectUpdate(projectId: string, payload: { type: string; event?: string; details?: any; timestamp?: string }) {
    const set = this.clients.get(projectId);
    if (!set || set.size === 0) return;

    const data = JSON.stringify({
      projectId,
      ...payload,
      timestamp: payload.timestamp || new Date().toISOString(),
    });

    const sseMessage = `event: project:updated\ndata: ${data}\n\n`;

    set.forEach((res) => {
      try {
        res.write(sseMessage);
      } catch (err) {
        logger.warn(`[ProjectEventBus] Failed to write SSE message to client: ${(err as Error).message}`);
      }
    });
  }
}

export const projectEventBus = new ProjectEventBus();
export default projectEventBus;
