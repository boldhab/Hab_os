import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';

export interface CodeSnippetInput {
  language: string;
  code: string;
  description?: string | null;
}

export interface CreateVaultNoteDTO {
  title: string;
  content: string;
  tags?: string[];
  codeSnippets?: CodeSnippetInput[];
  isMistakeSolution?: boolean;
  categoryId?: string | null;
}

export interface UpdateVaultNoteDTO {
  title?: string;
  content?: string;
  tags?: string[];
  codeSnippets?: CodeSnippetInput[];
  isMistakeSolution?: boolean;
  categoryId?: string | null;
}

export interface VaultSearchQuery {
  search?: string;
  tag?: string;
  isMistakeSolution?: boolean;
  page?: number;
  limit?: number;
}

// ==========================================
// 1. VAULT NOTES & SNIPPETS (UC-121 to UC-126)
// ==========================================

export const createNote = async (userId: string, data: CreateVaultNoteDTO) => {
  if (data.categoryId) {
    const category = await prisma.category.findFirst({
      where: { id: data.categoryId, userId },
    });
    if (!category) throw new ApiError(404, 'Category not found');
  }

  const note = await prisma.vaultNote.create({
    data: {
      title: data.title,
      content: data.content || '',
      tags: data.tags || [],
      codeSnippets: data.codeSnippets ? (data.codeSnippets as unknown as Prisma.InputJsonValue) : Prisma.JsonNull,
      isMistakeSolution: data.isMistakeSolution || false,
      categoryId: data.categoryId || null,
      userId,
    },
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  return note;
};

export const getNotes = async (userId: string, query: VaultSearchQuery) => {
  const { search, tag, isMistakeSolution, page = 1, limit = 20 } = query;
  const skip = (page - 1) * limit;

  const where: Prisma.VaultNoteWhereInput = { userId };

  if (isMistakeSolution !== undefined) where.isMistakeSolution = isMistakeSolution;
  if (tag) where.tags = { has: tag };

  if (search && search.trim() !== '') {
    where.OR = [
      { title: { contains: search, mode: 'insensitive' } },
      { content: { contains: search, mode: 'insensitive' } },
    ];
  }

  const [notes, total] = await Promise.all([
    prisma.vaultNote.findMany({
      where,
      skip,
      take: limit,
      orderBy: { updatedAt: 'desc' },
      include: {
        category: { select: { id: true, name: true, color: true, icon: true } },
      },
    }),
    prisma.vaultNote.count({ where }),
  ]);

  return {
    notes,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    },
  };
};

export const getNoteById = async (userId: string, noteId: string) => {
  const note = await prisma.vaultNote.findFirst({
    where: { id: noteId, userId },
    include: {
      category: true,
      sourceLinks: { include: { targetNote: true } },
      targetLinks: { include: { sourceNote: true } },
    },
  });

  if (!note) {
    throw new ApiError(404, 'Vault note not found');
  }

  return note;
};

export const updateNote = async (userId: string, noteId: string, data: UpdateVaultNoteDTO) => {
  const existing = await prisma.vaultNote.findFirst({
    where: { id: noteId, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Vault note not found');
  }

  const updated = await prisma.vaultNote.update({
    where: { id: noteId },
    data: {
      title: data.title,
      content: data.content,
      tags: data.tags,
      codeSnippets: data.codeSnippets !== undefined ? (data.codeSnippets as unknown as Prisma.InputJsonValue) : undefined,
      isMistakeSolution: data.isMistakeSolution,
      categoryId: data.categoryId,
    },
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  return updated;
};

export const deleteNote = async (userId: string, noteId: string) => {
  const existing = await prisma.vaultNote.findFirst({
    where: { id: noteId, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Vault note not found');
  }

  await prisma.vaultNote.delete({ where: { id: noteId } });
  return { message: 'Vault note deleted successfully' };
};

// ==========================================
// 2. SEARCH & TAG MANAGEMENT (UC-127, UC-128)
// ==========================================

export const searchVault = async (userId: string, search: string) => {
  const notes = await prisma.vaultNote.findMany({
    where: {
      userId,
      OR: [
        { title: { contains: search, mode: 'insensitive' } },
        { content: { contains: search, mode: 'insensitive' } },
      ],
    },
    take: 20,
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  return {
    notes,
    totalResults: notes.length,
  };
};

export const getVaultTags = async (userId: string) => {
  const notes = await prisma.vaultNote.findMany({
    where: { userId },
    select: { tags: true },
  });

  const tagSet = new Set<string>();
  notes.forEach((n: { tags: string[] }) => n.tags.forEach((t: string) => tagSet.add(t)));

  return Array.from(tagSet).sort();
};

// ==========================================
// 3. NOTE GRAPH & LINKS (UC-129 to UC-133)
// ==========================================

export const linkNotes = async (userId: string, sourceNoteId: string, targetNoteId: string) => {
  const [source, target] = await Promise.all([
    prisma.vaultNote.findFirst({ where: { id: sourceNoteId, userId } }),
    prisma.vaultNote.findFirst({ where: { id: targetNoteId, userId } }),
  ]);

  if (!source || !target) {
    throw new ApiError(404, 'One or both notes not found');
  }

  const link = await prisma.noteLink.upsert({
    where: {
      sourceNoteId_targetNoteId: {
        sourceNoteId,
        targetNoteId,
      },
    },
    update: {},
    create: {
      sourceNoteId,
      targetNoteId,
    },
  });

  return link;
};

export const unlinkNotes = async (userId: string, sourceNoteId: string, targetNoteId: string) => {
  await prisma.noteLink.deleteMany({
    where: {
      sourceNoteId,
      targetNoteId,
    },
  });

  return { message: 'Notes unlinked successfully' };
};

export const getNoteGraph = async (userId: string) => {
  const [notes, links] = await Promise.all([
    prisma.vaultNote.findMany({
      where: { userId },
      select: { id: true, title: true, tags: true },
    }),
    prisma.noteLink.findMany({
      where: {
        sourceNote: { userId },
      },
      select: { id: true, sourceNoteId: true, targetNoteId: true },
    }),
  ]);

  const nodes = notes.map((n) => ({
    id: n.id,
    label: n.title,
    tags: n.tags,
  }));

  const edges = links.map((l) => ({
    id: l.id,
    source: l.sourceNoteId,
    target: l.targetNoteId,
  }));

  return {
    nodes,
    edges,
    totalNodes: nodes.length,
    totalEdges: edges.length,
  };
};

export default {
  createNote,
  getNotes,
  getNoteById,
  updateNote,
  deleteNote,
  searchVault,
  getVaultTags,
  linkNotes,
  unlinkNotes,
  getNoteGraph,
};
