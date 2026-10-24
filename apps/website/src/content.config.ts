import { defineCollection } from "astro:content";
import { glob } from "astro/loaders";
import { z } from "astro/zod";
import { docsLoader, i18nLoader } from "@astrojs/starlight/loaders";
import { docsSchema, i18nSchema } from "@astrojs/starlight/schema";
const pages = defineCollection({
  loader: glob({
    base: "./content",
    pattern: "*/blog/*.md",
    generateId: ({ entry }) =>
      entry.replace(/\.md$/, "").replace(/\/index$/, ""),
  }),
  schema: z
    .object({
      layout: z.enum(["blog-index", "blog-article"]),
      title: z.string(),
      description: z.string(),
      category: z.string().optional(),
      date: z
        .string()
        .regex(/^\d{4}-\d{2}-\d{2}$/)
        .optional(),
      readTime: z.string().optional(),
      author: z.string().optional(),
      coverLabel: z.string().optional(),
      coverTitle: z.string().optional(),
    })
    .superRefine((data, ctx) => {
      if (data.layout === "blog-article" && (!data.date || !data.category))
        ctx.addIssue({
          code: "custom",
          message: "Blog articles require date and category",
        });
    }),
});
export const collections = {
  pages,
  docs: defineCollection({ loader: docsLoader(), schema: docsSchema() }),
  i18n: defineCollection({ loader: i18nLoader(), schema: i18nSchema() }),
};
