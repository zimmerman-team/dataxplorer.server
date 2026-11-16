// Where the server reaches dx.backend and general-ai-api.
//
// Set DX_BACKEND_URL and AIAPI_URL: infra.dx does in Docker, and .env.example
// does for running on your machine. Without them the server falls back to the
// old submodule setup's rule, so a server still deployed that way keeps
// working: the service name, plus -<ENV_TYPE> outside production.

function legacyHost(name: string, subdomainSet: boolean): string {
  const envType = process.env.ENV_TYPE;
  if (envType && envType !== 'prod') return `${name}-${envType}`;
  return subdomainSet ? name : 'localhost';
}

export const DX_BACKEND_URL = (
  process.env.DX_BACKEND_URL ??
  `http://${legacyHost('dx-backend', !!process.env.BACKEND_SUBDOMAIN)}:4004`
).replace(/\/$/, '');

export const AIAPI_URL = (
  process.env.AIAPI_URL ??
  `http://${legacyHost('ai-api', !!process.env.AIAPI_SUBDOMAIN)}:5000`
).replace(/\/$/, '');
