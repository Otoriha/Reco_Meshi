/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string
  readonly VITE_CONFIRMABLE_ENABLED: string
  readonly VITE_CONTACT_FORM_URL: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
