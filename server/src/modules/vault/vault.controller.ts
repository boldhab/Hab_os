import { Request, Response } from 'express';
import vaultService from './vault.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

// --- SEARCH & TAGS ---

export const searchVault = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const search = (req.query.search as string) || '';
  const result = await vaultService.searchVault(authReq.user!.id, search);
  return ApiResponse.success(res, result, 'Vault search results');
});

export const getVaultTags = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const tags = await vaultService.getVaultTags(authReq.user!.id);
  return ApiResponse.success(res, tags, 'Vault tags retrieved');
});

// --- NOTES ---

export const createNote = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const note = await vaultService.createNote(authReq.user!.id, req.body);
  return ApiResponse.success(res, note, 'Note created successfully', 201);
});

export const getNotes = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await vaultService.getNotes(authReq.user!.id, req.query);
  return ApiResponse.success(res, result, 'Notes retrieved successfully');
});

export const getNoteById = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const note = await vaultService.getNoteById(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, note, 'Note retrieved successfully');
});

export const updateNote = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const note = await vaultService.updateNote(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, note, 'Note updated successfully');
});

export const deleteNote = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await vaultService.deleteNote(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Note deleted successfully');
});

// --- GRAPH & LINKS ---

export const linkNotes = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { sourceNoteId, targetNoteId } = req.body;
  const link = await vaultService.linkNotes(authReq.user!.id, sourceNoteId, targetNoteId);
  return ApiResponse.success(res, link, 'Notes linked successfully', 201);
});

export const unlinkNotes = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { sourceNoteId, targetNoteId } = req.body;
  const result = await vaultService.unlinkNotes(authReq.user!.id, sourceNoteId, targetNoteId);
  return ApiResponse.success(res, result, 'Notes unlinked successfully');
});

export const getNoteGraph = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const graph = await vaultService.getNoteGraph(authReq.user!.id);
  return ApiResponse.success(res, graph, 'Note graph retrieved');
});

export default {
  searchVault,
  getVaultTags,
  createNote,
  getNotes,
  getNoteById,
  updateNote,
  deleteNote,
  linkNotes,
  unlinkNotes,
  getNoteGraph,
};
