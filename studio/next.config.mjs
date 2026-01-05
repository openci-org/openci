import rehypeShiki from '@shikijs/rehype'
import nextMDX from '@next/mdx'
import { Parser } from 'acorn'
import jsx from 'acorn-jsx'
import escapeStringRegexp from 'escape-string-regexp'
import * as path from 'path'
import { recmaImportImages } from 'recma-import-images'
import remarkGfm from 'remark-gfm'
import { remarkRehypeWrap } from 'remark-rehype-wrap'
import remarkUnwrapImages from 'remark-unwrap-images'
import { unifiedConditional } from 'unified-conditional'

/** @type {import('next').NextConfig} */
const nextConfig = {
  pageExtensions: ['js', 'jsx', 'ts', 'tsx', 'mdx'],
}

function remarkMDXLayout(source, metaName) {
  let parser = Parser.extend(jsx())
  let parseOptions = { ecmaVersion: 'latest', sourceType: 'module' }

  return (tree) => {
    let imp = `import _Layout from '${source}'`
    let exp = `export default function Layout(props) {
      return <_Layout {...props} ${metaName}={${metaName}} />
    }`

    tree.children.push(
      {
        type: 'mdxjsEsm',
        value: imp,
        data: { estree: parser.parse(imp, parseOptions) },
      },
      {
        type: 'mdxjsEsm',
        value: exp,
        data: { estree: parser.parse(exp, parseOptions) },
      },
    )
  }
}

const withMDX = nextMDX({
  extension: /\.mdx$/,
  options: {
    recmaPlugins: [recmaImportImages],
    rehypePlugins: [
      [
        rehypeShiki,
        {
          defaultColor: false,
          themes: {
            light: 'min-light',
            dark: 'min-dark',
          },
          cssVariablePrefix: '--shiki-',
        },
      ],
      [
        remarkRehypeWrap,
        {
          node: { type: 'mdxJsxFlowElement', name: 'Typography' },
          start: ':root > :not(mdxJsxFlowElement)',
          end: ':root > mdxJsxFlowElement',
        },
      ],
    ],
    remarkPlugins: [
      remarkGfm,
      remarkUnwrapImages,
      [
        unifiedConditional,
        [
          new RegExp(`^${escapeStringRegexp(path.resolve('src/app/blog'))}`),
          [[remarkMDXLayout, '@/app/blog/wrapper', 'article']],
        ],
        [
          new RegExp(`^${escapeStringRegexp(path.resolve('src/app/work'))}`),
          [[remarkMDXLayout, '@/app/work/wrapper', 'caseStudy']],
        ],
      ],
    ],
  },
})

export default withMDX(nextConfig)
