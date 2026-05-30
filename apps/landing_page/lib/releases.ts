import fs from 'node:fs';
import path from 'node:path';
import { marked } from 'marked';

type FrontMatterValue = string | string[];

export type ReleaseNote = {
  slug: string;
  title: string;
  date: string;
  label: string;
  summary: string;
  image?: string;
  tags: string[];
  highlights: {
    label: string;
    description: string;
  }[];
  sections: {
    title: string;
    body: ReleaseContentBlock[];
  }[];
};

export type ReleaseContentBlock =
  | {
      type: 'html';
      html: string;
    }
  | {
      type: 'image';
      src: string;
      alt: string;
      caption?: string;
    }
  | {
      type: 'video';
      src: string;
      caption?: string;
    };

const releaseDirectory = path.join(process.cwd(), 'content/releases');

export const releaseNotes: ReleaseNote[] = loadReleaseNotes();

export function getLatestReleaseNote() {
  return releaseNotes[0];
}

export function findReleaseNote(slug: string) {
  return releaseNotes.find((release) => release.slug === slug);
}

export function formatReleaseDate(date: string) {
  return new Intl.DateTimeFormat('ja-JP', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    weekday: 'short',
  }).format(new Date(`${date}T00:00:00+09:00`));
}

function loadReleaseNotes() {
  if (!fs.existsSync(releaseDirectory)) {
    return [];
  }

  return fs
    .readdirSync(releaseDirectory)
    .filter(isReleaseFile)
    .map((fileName) => readReleaseNote(fileName))
    .sort((a, b) => b.date.localeCompare(a.date));
}

function isReleaseFile(fileName: string) {
  return /^\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.md$/.test(fileName);
}

function readReleaseNote(fileName: string): ReleaseNote {
  const filePath = path.join(releaseDirectory, fileName);
  const raw = fs.readFileSync(filePath, 'utf8');
  const { frontMatter, body } = splitFrontMatter(raw, fileName);
  const metadata = parseFrontMatter(frontMatter, fileName);
  const parsedBody = parseBody(body);

  return {
    slug: path.basename(fileName, '.md'),
    title: readString(metadata, 'title', fileName),
    date: readString(metadata, 'date', fileName),
    label: readString(metadata, 'label', fileName),
    summary: readString(metadata, 'summary', fileName),
    image: readOptionalString(metadata, 'image'),
    tags: readStringArray(metadata, 'tags', fileName),
    highlights: parsedBody.highlights,
    sections: parsedBody.sections,
  };
}

function splitFrontMatter(raw: string, fileName: string) {
  const normalized = raw.replace(/\r\n/g, '\n');
  const match = /^---\n([\s\S]*?)\n---\n?([\s\S]*)$/.exec(normalized);

  if (!match) {
    throw new Error(`Release note ${fileName} must start with front matter.`);
  }

  return {
    frontMatter: match[1],
    body: match[2],
  };
}

function parseFrontMatter(frontMatter: string, fileName: string) {
  const data: Record<string, FrontMatterValue> = {};
  let currentArrayKey: string | undefined;

  for (const line of frontMatter.split('\n')) {
    if (!line.trim()) {
      continue;
    }

    const arrayItem = /^\s*-\s+(.+)$/.exec(line);
    if (arrayItem && currentArrayKey) {
      const current = data[currentArrayKey];
      if (!Array.isArray(current)) {
        throw new Error(`Front matter key "${currentArrayKey}" in ${fileName} must be an array.`);
      }
      current.push(stripQuotes(arrayItem[1]));
      continue;
    }

    const keyValue = /^([A-Za-z][\w-]*):\s*(.*)$/.exec(line);
    if (!keyValue) {
      throw new Error(`Invalid front matter line in ${fileName}: ${line}`);
    }

    const [, key, value] = keyValue;
    if (!value) {
      data[key] = [];
      currentArrayKey = key;
      continue;
    }

    data[key] = parseFrontMatterValue(value);
    currentArrayKey = undefined;
  }

  return data;
}

function parseFrontMatterValue(value: string): FrontMatterValue {
  const trimmed = value.trim();

  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    return trimmed
      .slice(1, -1)
      .split(',')
      .map((item) => stripQuotes(item))
      .filter(Boolean);
  }

  return stripQuotes(trimmed);
}

function stripQuotes(value: string) {
  return value.trim().replace(/^["']|["']$/g, '');
}

function readString(metadata: Record<string, FrontMatterValue>, key: string, fileName: string) {
  const value = metadata[key];

  if (typeof value !== 'string' || !value) {
    throw new Error(`Release note ${fileName} is missing required "${key}" front matter.`);
  }

  return value;
}

function readOptionalString(metadata: Record<string, FrontMatterValue>, key: string) {
  const value = metadata[key];

  return typeof value === 'string' && value ? value : undefined;
}

function readStringArray(metadata: Record<string, FrontMatterValue>, key: string, fileName: string) {
  const value = metadata[key];

  if (!Array.isArray(value)) {
    throw new Error(`Release note ${fileName} is missing required "${key}" array front matter.`);
  }

  return value;
}

function parseBody(body: string) {
  const markdownSections = splitMarkdownSections(body);
  const highlightSection = markdownSections.find((section) => section.title === '今週のハイライト');

  return {
    highlights: highlightSection ? parseHighlights(highlightSection.body) : [],
    sections: markdownSections
      .filter((section) => section.title !== '今週のハイライト')
      .map((section) => ({
        title: section.title,
        body: parseContentBlocks(section.body),
      })),
  };
}

function splitMarkdownSections(body: string) {
  const sections: { title: string; body: string }[] = [];
  let currentTitle: string | undefined;
  let currentLines: string[] = [];

  for (const line of body.replace(/\r\n/g, '\n').split('\n')) {
    const heading = /^##\s+(.+)$/.exec(line);

    if (heading) {
      if (currentTitle) {
        sections.push({
          title: currentTitle,
          body: currentLines.join('\n').trim(),
        });
      }
      currentTitle = heading[1].trim();
      currentLines = [];
      continue;
    }

    if (currentTitle) {
      currentLines.push(line);
    }
  }

  if (currentTitle) {
    sections.push({
      title: currentTitle,
      body: currentLines.join('\n').trim(),
    });
  }

  return sections;
}

function parseHighlights(body: string) {
  return body
    .split('\n')
    .map((line) => /^-\s+(.+)$/.exec(line.trim())?.[1])
    .filter((line): line is string => Boolean(line))
    .map((line) => {
      const bold = /^\*\*(.+?)\*\*:?\s*(.*)$/.exec(line);
      if (bold) {
        return {
          label: bold[1].trim(),
          description: bold[2].trim(),
        };
      }

      const colon = /^(.+?)[:：]\s*(.+)$/.exec(line);
      if (colon) {
        return {
          label: colon[1].trim(),
          description: colon[2].trim(),
        };
      }

      return {
        label: line,
        description: line,
      };
    });
}

function parseContentBlocks(body: string) {
  return body
    .split(/\n{2,}/)
    .map((paragraph) => parseContentBlock(paragraph.trim()))
    .filter((block): block is ReleaseContentBlock => Boolean(block));
}

function parseContentBlock(block: string): ReleaseContentBlock | undefined {
  if (!block) {
    return undefined;
  }

  const image = /^!\[([^\]]*)\]\((.+)\)$/.exec(block);
  if (image) {
    const resource = parseMarkdownResource(image[2]);
    return {
      type: 'image',
      src: resource.src,
      alt: image[1].trim(),
      caption: resource.caption,
    };
  }

  const video = /^@\[video\]\((.+)\)$/.exec(block);
  if (video) {
    const resource = parseMarkdownResource(video[1]);
    return {
      type: 'video',
      src: resource.src,
      caption: resource.caption,
    };
  }

  return {
    type: 'html',
    html: marked.parse(block, { async: false }) as string,
  };
}

function parseMarkdownResource(value: string) {
  const match = /^(\S+)(?:\s+"([^"]+)")?$/.exec(value.trim());

  if (!match) {
    throw new Error(`Invalid media resource: ${value}`);
  }

  return {
    src: match[1],
    caption: match[2]?.trim(),
  };
}
