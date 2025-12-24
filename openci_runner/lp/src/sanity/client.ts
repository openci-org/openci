import { createClient } from 'next-sanity'
import { apiVersion, dataset, projectId } from './env'

const isDevelopment = process.env.NODE_ENV === 'development'

export const client = createClient({
  projectId,
  dataset,
  apiVersion,
  useCdn: isDevelopment ? false : true,
})
