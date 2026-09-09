import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { encryptToken, decryptToken } from '../../utils/crypto';

export interface SyncGitHubDTO {
  username: string;
  accessToken?: string | null;
  publicReposCount?: number;
  totalCommits?: number;
  currentStreak?: number;
  longestStreak?: number;
}

export interface ImportRepoDTO {
  repoName: string;
  owner: string;
  repoUrl: string;
  description?: string | null;
  language?: string | null;
  technologies?: string[];
  color?: string;
}

/**
 * Helper: GitHub API request headers
 */
const getGitHubHeaders = (token?: string | null) => {
  const headers: Record<string, string> = {
    'Accept': 'application/vnd.github.v3+json',
    'User-Agent': 'HabOS-Personal-OS',
  };
  if (token && token.trim() !== '') {
    headers['Authorization'] = `token ${token.trim()}`;
  }
  return headers;
};

// ==========================================
// 1. GITHUB INTEGRATION CORE (UC-53 to UC-58)
// ==========================================

export const getGitHubStats = async (userId: string) => {
  const stats = await prisma.gitHubIntegration.findUnique({
    where: { userId },
  });

  if (!stats) return null;

  const { accessToken, ...sanitized } = stats;
  return {
    ...sanitized,
    hasAccessToken: Boolean(accessToken && accessToken.trim() !== ''),
  };
};

export const syncGitHub = async (userId: string, data: SyncGitHubDTO) => {
  let publicReposCount = data.publicReposCount || 0;
  let totalCommits = data.totalCommits || 0;
  let recentCommits: Array<{ repo: string; message: string; date: string }> = [];

  // Determine active token (plaintext for API call, encrypt for DB storage)
  const existingIntegration = await prisma.gitHubIntegration.findUnique({
    where: { userId },
  });

  let plainToken = data.accessToken ?? '';
  if (!plainToken && existingIntegration?.accessToken) {
    plainToken = decryptToken(existingIntegration.accessToken);
  }

  // If username provided, try fetching live data from GitHub public API
  try {
    const userRes = await fetch(`https://api.github.com/users/${data.username}`, {
      headers: getGitHubHeaders(plainToken),
    });

    if (userRes.ok) {
      const userData = (await userRes.json()) as { public_repos?: number };
      publicReposCount = userData.public_repos ?? publicReposCount;

      // Fetch recent public push events to extract commits
      const eventsRes = await fetch(`https://api.github.com/users/${data.username}/events`, {
        headers: getGitHubHeaders(data.accessToken),
      });

      if (eventsRes.ok) {
        const events = (await eventsRes.json()) as Array<{
          type: string;
          repo: { name: string };
          created_at: string;
          payload: { commits?: Array<{ message: string }> };
        }>;

        const pushEvents = events.filter((e) => e.type === 'PushEvent');
        pushEvents.forEach((ev) => {
          if (ev.payload.commits) {
            ev.payload.commits.forEach((c) => {
              recentCommits.push({
                repo: ev.repo.name,
                message: c.message,
                date: ev.created_at,
              });
            });
          }
        });
        totalCommits = recentCommits.length > 0 ? recentCommits.length : totalCommits;
      }
    }
  } catch (err) {
    console.warn('GitHub public API fetch failed, falling back to supplied data:', err);
  }

  const encryptedAccessToken = plainToken ? encryptToken(plainToken) : '';

  const integration = await prisma.gitHubIntegration.upsert({
    where: { userId },
    update: {
      username: data.username,
      accessToken: encryptedAccessToken,
      publicReposCount,
      totalCommits: Math.max(totalCommits, data.totalCommits || 0),
      currentStreak: data.currentStreak || 0,
      longestStreak: data.longestStreak || 0,
      recentCommitsJson: recentCommits.length > 0 ? JSON.parse(JSON.stringify(recentCommits)) : undefined,
      lastSyncedAt: new Date(),
    },
    create: {
      userId,
      username: data.username,
      accessToken: encryptedAccessToken,
      publicReposCount,
      totalCommits: Math.max(totalCommits, data.totalCommits || 0),
      currentStreak: data.currentStreak || 0,
      longestStreak: data.longestStreak || 0,
      recentCommitsJson: recentCommits.length > 0 ? JSON.parse(JSON.stringify(recentCommits)) : undefined,
      lastSyncedAt: new Date(),
    },
  });

  const { accessToken: _storedToken, ...sanitized } = integration;
  return {
    ...sanitized,
    hasAccessToken: Boolean(plainToken && plainToken.trim() !== ''),
  };
};

// ==========================================
// 2. FETCH USER REPOSITORIES LIST
// ==========================================

export const listGitHubRepositories = async (userId: string) => {
  const integration = await prisma.gitHubIntegration.findUnique({
    where: { userId },
  });

  if (!integration || !integration.username) {
    throw new ApiError(400, 'GitHub is not connected. Please connect your GitHub account first.');
  }

  const decryptedToken = integration.accessToken ? decryptToken(integration.accessToken) : '';

  const endpoint = decryptedToken
    ? 'https://api.github.com/user/repos?sort=updated&per_page=50'
    : `https://api.github.com/users/${integration.username}/repos?sort=updated&per_page=50`;

  const response = await fetch(endpoint, {
    headers: getGitHubHeaders(decryptedToken),
  });

  if (!response.ok) {
    throw new ApiError(response.status, `Failed to fetch repositories from GitHub (${response.statusText})`);
  }

  const rawRepos = (await response.json()) as Array<{
    id: number;
    name: string;
    full_name: string;
    description: string | null;
    html_url: string;
    language: string | null;
    stargazers_count: number;
    forks_count: number;
    open_issues_count: number;
    updated_at: string;
    owner: { login: string };
  }>;

  // Map to clean HabOS DTO
  const repositories = rawRepos.map((r) => ({
    id: r.id,
    name: r.name,
    fullName: r.full_name,
    owner: r.owner.login,
    description: r.description,
    repoUrl: r.html_url,
    primaryLanguage: r.language,
    starsCount: r.stargazers_count,
    forksCount: r.forks_count,
    openIssuesCount: r.open_issues_count,
    lastUpdated: r.updated_at,
  }));

  return {
    username: integration.username,
    totalFetched: repositories.length,
    repositories,
  };
};

// ==========================================
// 3. IMPORT REPO AS A HABOS PROJECT
// ==========================================

export const importRepositoryAsProject = async (userId: string, data: ImportRepoDTO) => {
  // Check if project with this repoUrl already exists
  const existing = await prisma.project.findFirst({
    where: { userId, repoUrl: data.repoUrl },
  });

  if (existing) {
    return {
      project: existing,
      isNewlyCreated: false,
      message: 'Repository is already linked to this HabOS project.',
    };
  }

  const technologies = data.technologies && data.technologies.length > 0
    ? data.technologies
    : (data.language ? [data.language] : ['GitHub']);

  const project = await prisma.project.create({
    data: {
      title: data.repoName,
      description: data.description || `Imported from GitHub: ${data.owner}/${data.repoName}`,
      repoUrl: data.repoUrl,
      technologies,
      color: data.color || '#10B981',
      status: 'IN_PROGRESS',
      progress: 0.0,
      userId,
    },
  });

  return {
    project,
    isNewlyCreated: true,
    message: 'GitHub repository successfully imported as a HabOS project.',
  };
};

// ==========================================
// 4. DEEP REPO & COMMIT CADENCE ANALYSIS
// ==========================================

export const analyzeRepository = async (userId: string, owner: string, repo: string) => {
  const integration = await prisma.gitHubIntegration.findUnique({
    where: { userId },
  });

  const decryptedToken = integration?.accessToken ? decryptToken(integration.accessToken) : '';
  const headers = getGitHubHeaders(decryptedToken);

  // Fetch Commits, Languages, and Open Issues in parallel
  const [commitsRes, langRes, issuesRes] = await Promise.all([
    fetch(`https://api.github.com/repos/${owner}/${repo}/commits?per_page=30`, { headers }),
    fetch(`https://api.github.com/repos/${owner}/${repo}/languages`, { headers }),
    fetch(`https://api.github.com/repos/${owner}/${repo}/issues?state=open&per_page=20`, { headers }),
  ]);

  let commits: Array<{
    sha: string;
    message: string;
    author: string;
    date: string;
  }> = [];

  if (commitsRes.ok) {
    const rawCommits = (await commitsRes.json()) as Array<{
      sha: string;
      commit: {
        message: string;
        author: { name: string; date: string };
      };
    }>;

    commits = rawCommits.map((c) => ({
      sha: c.sha.substring(0, 7),
      message: c.commit.message.split('\n')[0], // First line
      author: c.commit.author.name,
      date: c.commit.author.date,
    }));
  }

  // Language percentage distribution
  let languages: Array<{ language: string; percentage: number }> = [];
  if (langRes.ok) {
    const langObj = (await langRes.json()) as Record<string, number>;
    const totalBytes = Object.values(langObj).reduce((sum, b) => sum + b, 0);
    if (totalBytes > 0) {
      languages = Object.entries(langObj).map(([lang, bytes]) => ({
        language: lang,
        percentage: Number(((bytes / totalBytes) * 100).toFixed(1)),
      }));
    }
  }

  // Open Issues / Potential Backlog Items
  let openIssues: Array<{
    id: number;
    title: string;
    number: number;
    labels: string[];
    createdAt: string;
  }> = [];

  if (issuesRes.ok) {
    const rawIssues = (await issuesRes.json()) as Array<{
      id: number;
      title: string;
      number: number;
      labels: Array<{ name: string }>;
      created_at: string;
      pull_request?: unknown;
    }>;

    // Filter out PRs, keep only issues
    openIssues = rawIssues
      .filter((i) => !i.pull_request)
      .map((i) => ({
        id: i.id,
        title: i.title,
        number: i.number,
        labels: i.labels.map((l) => l.name),
        createdAt: i.created_at,
      }));
  }

  // Commit Cadence Analysis (Activity by Day)
  const commitDates = commits.map((c) => c.date.split('T')[0]);
  const cadenceByDate: Record<string, number> = {};
  commitDates.forEach((d) => {
    cadenceByDate[d] = (cadenceByDate[d] || 0) + 1;
  });

  const activeCodingDays = Object.keys(cadenceByDate).length;
  const recentVelocity = commits.length > 0 ? (commits.length / Math.max(activeCodingDays, 1)).toFixed(1) : '0';

  return {
    repository: `${owner}/${repo}`,
    analysisSummary: {
      recentCommitsAnalyzed: commits.length,
      activeCodingDaysInSample: activeCodingDays,
      averageCommitsPerActiveDay: recentVelocity,
      openIssuesCount: openIssues.length,
    },
    technologies: languages,
    recentCommits: commits.slice(0, 10),
    openIssues,
  };
};

// ==========================================
// 5. LEETCODE INTEGRATION (UC-59 to UC-64)
// ==========================================

export const getLeetCodeStats = async (userId: string) => {
  const stats = await prisma.leetCodeIntegration.findUnique({
    where: { userId },
  });

  return stats;
};

export const syncLeetCode = async (userId: string, data: { username: string; easySolved?: number; mediumSolved?: number; hardSolved?: number; currentStreak?: number; longestStreak?: number }) => {
  const easy = data.easySolved || 0;
  const medium = data.mediumSolved || 0;
  const hard = data.hardSolved || 0;
  const totalSolved = easy + medium + hard;

  const integration = await prisma.leetCodeIntegration.upsert({
    where: { userId },
    update: {
      username: data.username,
      easySolved: easy,
      mediumSolved: medium,
      hardSolved: hard,
      totalSolved,
      currentStreak: data.currentStreak || 0,
      longestStreak: data.longestStreak || 0,
      lastSyncedAt: new Date(),
    },
    create: {
      userId,
      username: data.username,
      easySolved: easy,
      mediumSolved: medium,
      hardSolved: hard,
      totalSolved,
      currentStreak: data.currentStreak || 0,
      longestStreak: data.longestStreak || 0,
      lastSyncedAt: new Date(),
    },
  });

  return integration;
};

export default {
  getGitHubStats,
  syncGitHub,
  listGitHubRepositories,
  importRepositoryAsProject,
  analyzeRepository,
  getLeetCodeStats,
  syncLeetCode,
};
