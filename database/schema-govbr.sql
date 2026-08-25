-- Modelo de referência para a versão Gov.br.
-- Executar somente após revisão da equipe de banco, segurança e jurídico.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS cadastro;

CREATE TABLE IF NOT EXISTS cadastro.municipality (
  ibge_code CHAR(7) PRIMARY KEY,
  name TEXT NOT NULL,
  uf CHAR(2) NOT NULL,
  geom geometry(MultiPolygon, 4326),
  source_version TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (ibge_code ~ '^[0-9]{7}$')
);
CREATE INDEX IF NOT EXISTS municipality_geom_gix ON cadastro.municipality USING GIST (geom);

CREATE TABLE IF NOT EXISTS cadastro.source_reference (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type TEXT NOT NULL CHECK (source_type IN ('CASA_CIVIL','IBGE','SGB','CEMADEN','S2ID','OUTRA')),
  title TEXT NOT NULL,
  version TEXT NOT NULL,
  source_url TEXT,
  content_sha256 CHAR(64),
  published_at DATE,
  loaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (source_type, version)
);

CREATE TABLE IF NOT EXISTS cadastro.indication (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ibge_code CHAR(7) NOT NULL REFERENCES cadastro.municipality(ibge_code),
  source_id UUID NOT NULL REFERENCES cadastro.source_reference(id),
  indication_status TEXT NOT NULL CHECK (indication_status IN ('INDICADO','NAO_INDICADO','REVOGADO')),
  methodology_version TEXT,
  effective_from DATE NOT NULL,
  effective_to DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS indication_ibge_idx ON cadastro.indication (ibge_code, effective_from DESC);

CREATE TABLE IF NOT EXISTS cadastro.identity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  govbr_sub TEXT NOT NULL UNIQUE,
  display_name TEXT,
  email TEXT,
  trust_level TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cadastro.organization (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_type TEXT NOT NULL CHECK (organization_type IN ('MUNICIPIO','ESTADO','UNIAO','CONTROLE')),
  legal_name TEXT NOT NULL,
  ibge_code CHAR(7) REFERENCES cadastro.municipality(ibge_code),
  uf CHAR(2),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cadastro.access_grant (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  identity_id UUID NOT NULL REFERENCES cadastro.identity(id),
  organization_id UUID NOT NULL REFERENCES cadastro.organization(id),
  role_code TEXT NOT NULL,
  scope_type TEXT NOT NULL CHECK (scope_type IN ('PUBLICO','MUNICIPIO','UF','NACIONAL','PROCESSO')),
  scope_value TEXT,
  granted_by UUID REFERENCES cadastro.identity(id),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  CHECK (revoked_at IS NULL OR revoked_at >= granted_at)
);
CREATE INDEX IF NOT EXISTS access_grant_identity_idx ON cadastro.access_grant (identity_id, revoked_at, expires_at);

CREATE TABLE IF NOT EXISTS cadastro.registration (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ibge_code CHAR(7) NOT NULL REFERENCES cadastro.municipality(ibge_code),
  status TEXT NOT NULL DEFAULT 'RASCUNHO' CHECK (status IN ('RASCUNHO','ENVIADO','EM_ANALISE','PENDENCIA','DEVOLVIDO','APROVADO','EFETIVADO','SUSPENSO','ARQUIVADO')),
  created_by UUID NOT NULL REFERENCES cadastro.identity(id),
  responsible_name TEXT,
  responsible_role TEXT,
  attestation_required BOOLEAN NOT NULL DEFAULT FALSE,
  attestation_at TIMESTAMPTZ,
  effective_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS registration_ibge_status_idx ON cadastro.registration (ibge_code, status);

CREATE TABLE IF NOT EXISTS cadastro.registration_event (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id UUID NOT NULL REFERENCES cadastro.registration(id),
  from_status TEXT,
  to_status TEXT NOT NULL,
  actor_id UUID NOT NULL REFERENCES cadastro.identity(id),
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cadastro.document (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id UUID REFERENCES cadastro.registration(id),
  obligation_id UUID,
  original_name TEXT NOT NULL,
  storage_key TEXT NOT NULL UNIQUE,
  mime_type TEXT NOT NULL,
  size_bytes BIGINT NOT NULL CHECK (size_bytes > 0),
  sha256 CHAR(64) NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  scan_status TEXT NOT NULL DEFAULT 'PENDING' CHECK (scan_status IN ('PENDING','CLEAN','INFECTED','ERROR')),
  visibility TEXT NOT NULL DEFAULT 'RESTRICTED' CHECK (visibility IN ('PUBLIC','RESTRICTED','INTERNAL')),
  uploaded_by UUID NOT NULL REFERENCES cadastro.identity(id),
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS document_hash_registration_idx ON cadastro.document (registration_id, sha256, version);

CREATE TABLE IF NOT EXISTS cadastro.obligation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id UUID NOT NULL REFERENCES cadastro.registration(id),
  article_item CHAR(1) NOT NULL CHECK (article_item IN ('I','II','III','IV','V','VI','VII')),
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDENTE' CHECK (status IN ('PENDENTE','EM_ANDAMENTO','ENVIADO','VALIDADO','VENCIDO')),
  due_at DATE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (registration_id, article_item)
);

CREATE TABLE IF NOT EXISTS cadastro.audit_event (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES cadastro.identity(id),
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  request_id TEXT,
  ip_hash TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS audit_event_entity_idx ON cadastro.audit_event (entity_type, entity_id, created_at DESC);
CREATE INDEX IF NOT EXISTS audit_event_actor_idx ON cadastro.audit_event (actor_id, created_at DESC);

CREATE OR REPLACE VIEW cadastro.public_municipality_status AS
SELECT
  m.ibge_code,
  m.name,
  m.uf,
  EXISTS (
    SELECT 1 FROM cadastro.indication i
    WHERE i.ibge_code = m.ibge_code
      AND i.indication_status = 'INDICADO'
      AND i.effective_to IS NULL
  ) AS indicated,
  r.status AS registration_status,
  m.geom
FROM cadastro.municipality m
LEFT JOIN LATERAL (
  SELECT status FROM cadastro.registration r0
  WHERE r0.ibge_code = m.ibge_code
  ORDER BY r0.updated_at DESC LIMIT 1
) r ON TRUE;

-- Recomendações: RLS, papéis de banco distintos, views públicas dedicadas,
-- criptografia/segredo no ambiente institucional e migrações versionadas.
