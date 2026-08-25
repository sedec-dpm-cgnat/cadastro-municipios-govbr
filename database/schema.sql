-- Cadastro Nacional de Municípios — esquema inicial MySQL 8+
-- Banco de testes. Não inclui credenciais nem dados pessoais reais.

CREATE TABLE municipalities (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ibge_code CHAR(7) NOT NULL UNIQUE,
  name VARCHAR(160) NOT NULL,
  uf CHAR(2) NOT NULL,
  latitude DECIMAL(10,7) NULL,
  longitude DECIMAL(10,7) NULL,
  current_status ENUM('INDICADO','EM_PREENCHIMENTO','EM_ANALISE','CADASTRADO','DEVOLVIDO') NOT NULL DEFAULT 'INDICADO',
  public_visible TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_municipalities_uf_status (uf, current_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE technical_indications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  municipality_id BIGINT UNSIGNED NOT NULL,
  source_name VARCHAR(255) NOT NULL,
  source_url VARCHAR(500) NULL,
  source_version VARCHAR(80) NULL,
  indication_type VARCHAR(120) NULL,
  base_year SMALLINT NULL,
  indicated_at DATE NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_indication_municipality FOREIGN KEY (municipality_id) REFERENCES municipalities(id),
  INDEX idx_indication_source (source_name, source_version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE enrollment_processes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  municipality_id BIGINT UNSIGNED NOT NULL,
  protocol_number VARCHAR(80) NULL UNIQUE,
  requested_at DATETIME NULL,
  manifestation_at DATETIME NULL,
  approved_at DATETIME NULL,
  status ENUM('EM_PREENCHIMENTO','EM_ANALISE','CADASTRADO','DEVOLVIDO') NOT NULL DEFAULT 'EM_PREENCHIMENTO',
  reviewer_note TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_process_municipality FOREIGN KEY (municipality_id) REFERENCES municipalities(id),
  INDEX idx_process_status (status, updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE risk_evidence_packages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  process_id BIGINT UNSIGNED NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  storage_key VARCHAR(500) NOT NULL,
  mime_type VARCHAR(160) NULL,
  file_size BIGINT UNSIGNED NOT NULL,
  sha256 CHAR(64) NOT NULL,
  preferred_archive TINYINT(1) NOT NULL DEFAULT 0,
  contains_georeferenced_inventory TINYINT(1) NULL,
  methodology_note TEXT NULL,
  uploaded_by VARCHAR(120) NULL,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_evidence_process FOREIGN KEY (process_id) REFERENCES enrollment_processes(id),
  INDEX idx_evidence_hash (sha256)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE municipal_attestations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  process_id BIGINT UNSIGNED NOT NULL,
  attestation_text TEXT NOT NULL,
  agreed TINYINT(1) NOT NULL DEFAULT 0,
  responsible_name VARCHAR(160) NOT NULL,
  responsible_role VARCHAR(160) NOT NULL,
  document_reference VARCHAR(160) NULL,
  manifested_at DATETIME NULL,
  CONSTRAINT fk_attestation_process FOREIGN KEY (process_id) REFERENCES enrollment_processes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE art5_obligations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  municipality_id BIGINT UNSIGNED NOT NULL,
  item_number TINYINT UNSIGNED NOT NULL,
  title VARCHAR(220) NOT NULL,
  status ENUM('BLOQUEADA','NAO_INICIADA','EM_ELABORACAO','ENVIADA','APROVADA','ATUALIZAR') NOT NULL DEFAULT 'BLOQUEADA',
  due_at DATE NULL,
  last_updated_at DATETIME NULL,
  note TEXT NULL,
  UNIQUE KEY uq_municipality_item (municipality_id, item_number),
  CONSTRAINT fk_art5_municipality FOREIGN KEY (municipality_id) REFERENCES municipalities(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE document_files (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  municipality_id BIGINT UNSIGNED NOT NULL,
  process_id BIGINT UNSIGNED NULL,
  obligation_id BIGINT UNSIGNED NULL,
  original_name VARCHAR(255) NOT NULL,
  storage_key VARCHAR(500) NOT NULL,
  mime_type VARCHAR(160) NULL,
  file_size BIGINT UNSIGNED NOT NULL,
  sha256 CHAR(64) NOT NULL,
  version_label VARCHAR(80) NULL,
  public_status ENUM('PRIVADO','PUBLICADO','RESTRITO') NOT NULL DEFAULT 'PRIVADO',
  uploaded_by VARCHAR(120) NULL,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_doc_municipality FOREIGN KEY (municipality_id) REFERENCES municipalities(id),
  CONSTRAINT fk_doc_process FOREIGN KEY (process_id) REFERENCES enrollment_processes(id),
  CONSTRAINT fk_doc_obligation FOREIGN KEY (obligation_id) REFERENCES art5_obligations(id),
  INDEX idx_doc_public_status (public_status, uploaded_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE map_layers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  municipality_id BIGINT UNSIGNED NULL,
  name VARCHAR(180) NOT NULL,
  provider VARCHAR(120) NOT NULL,
  source_url VARCHAR(500) NULL,
  geometry_storage_key VARCHAR(500) NULL,
  layer_type VARCHAR(80) NULL,
  published TINYINT(1) NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_layer_municipality FOREIGN KEY (municipality_id) REFERENCES municipalities(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE audit_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  municipality_id BIGINT UNSIGNED NULL,
  process_id BIGINT UNSIGNED NULL,
  actor_identifier VARCHAR(160) NULL,
  event_type VARCHAR(100) NOT NULL,
  from_status VARCHAR(60) NULL,
  to_status VARCHAR(60) NULL,
  payload_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_municipality FOREIGN KEY (municipality_id) REFERENCES municipalities(id),
  CONSTRAINT fk_audit_process FOREIGN KEY (process_id) REFERENCES enrollment_processes(id),
  INDEX idx_audit_process_date (process_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
