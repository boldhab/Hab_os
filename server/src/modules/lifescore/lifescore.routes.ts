import { Router, Request, Response } from 'express';
const router = Router();
router.get('/', (_req: Request, res: Response) => { res.json({ message: 'Lifescore endpoint ready' }); });
export default router;
