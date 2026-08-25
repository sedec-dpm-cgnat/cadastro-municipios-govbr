-- Dados demonstrativos. Não usar em produção.
INSERT INTO municipalities (ibge_code, name, uf, latitude, longitude, current_status)
VALUES
  ('3550704', 'São Sebastião', 'SP', -23.7606, -45.4097, 'EM_PREENCHIMENTO'),
  ('3510500', 'Caraguatatuba', 'SP', -23.6203, -45.4133, 'INDICADO'),
  ('3555406', 'Ubatuba', 'SP', -23.4332, -45.0711, 'INDICADO'),
  ('3520400', 'Ilhabela', 'SP', -23.7785, -45.3581, 'INDICADO'),
  ('4314902', 'Porto Alegre', 'RS', -30.0346, -51.2177, 'CADASTRADO')
ON DUPLICATE KEY UPDATE current_status = VALUES(current_status), updated_at = CURRENT_TIMESTAMP;

INSERT INTO technical_indications (municipality_id, source_name, source_version, base_year, indicated_at)
SELECT id, 'Notas Técnicas Casa Civil', 'NT 1/2025 + NT 2/2025', 2024, '2025-02-01'
FROM municipalities
WHERE ibge_code IN ('3550704','3510500','3555406','3520400','4314902');
