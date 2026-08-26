# Arquitetura de referência para a equipe de TI

## 1. Visão de implantação

```text
Usuário
  │ HTTPS
  ▼
WAF / balanceador / ingress
  │
  ├── Frontend web Gov.br (React/Angular/Vue ou server-side)
  │       └── Design System Gov.br + Leaflet + acessibilidade
  │
  └── API do Cadastro Nacional
          ├── autenticação OIDC/Login gov.br
          ├── autorização RBAC/ABAC e escopos
          ├── workflow de inscrição e obrigações
          ├── serviço de documentos/antivírus/versões
          ├── auditoria e notificações
          └── APIs de referência: IBGE, SGB/CPRM, CEMADEN, S2iD
                    │
                    ├── PostgreSQL + PostGIS
                    ├── armazenamento de objetos institucional
                    ├── fila de tarefas
                    └── observabilidade/SIEM
```

O mapa público pode carregar a geometria generalizada do IBGE por cache/CDN. O backend deve manter uma cópia controlada dos códigos e versões das fontes, evitando que a disponibilidade momentânea de uma API externa impeça a consulta pública.

## 2. Frontend

### Stack sugerida

- React, Angular ou Vue conforme padrão do Ministério;
- pacote oficial `@govbr-ds/core` ou biblioteca oficial adotada pela equipe;
- TypeScript, lint, testes unitários e testes de componentes;
- Leaflet para navegação e PostGIS/GeoJSON para camadas;
- cliente OIDC sem expor segredo no browser;
- geração de CSV/GeoJSON pelo backend quando o conjunto for grande.

### Módulos

1. `PublicPortal`: explicação, indicadores, busca, downloads e mapa;
2. `IdentityEntry`: seleção de perfil e início do Login gov.br;
3. `MunicipalRegistration`: Wizard, Upload, manifestação e revisão;
4. `RegistrationOperations`: confirmação, efetivação automática e publicação;
5. `Obligations`: sete obrigações pós-efetivação;
6. `NationalMap`: camadas IBGE, indicação, cadastro e status;
7. `AuditConsole`: somente para auditoria autorizada;
8. `AccessAdmin`: gestão de usuários, papéis e escopos.

### Estado e roteamento

- rotas públicas não devem exigir sessão;
- rotas privadas devem validar sessão e permissões no carregamento e no backend;
- estado do Wizard deve ser recuperável como rascunho;
- mensagens de erro devem manter contexto e permitir correção sem perder os campos;
- não usar localStorage para documentos, tokens ou dados pessoais sensíveis.

## 3. Backend/API

### Stack sugerida

- API REST versionada (`/api/v1`) ou arquitetura institucional já adotada;
- OpenAPI como contrato obrigatório;
- PostgreSQL/PostGIS;
- armazenamento de objetos compatível com a infraestrutura do Ministério;
- fila assíncrona para antivírus, extração, geração de arquivos e notificações;
- Redis somente para cache/sessão técnica, sem ser fonte de verdade;
- logs estruturados com correlação por `request_id` e `processo_id`.

### Serviços

| Serviço | Responsabilidade |
|---|---|
| Identity Adapter | troca do código OIDC por identidade validada e criação da sessão |
| Access Service | perfis, transações, escopos, concessões e revogações |
| Municipality Registry | município, UF, código IBGE, indicação vigente e vínculos |
| Registration Workflow | rascunho, confirmação, efetivação automática e liberação das obrigações |
| Document Service | upload, hash, antivírus, versões, download autorizado |
| Map Service | GeoJSON simplificado, cache, filtros e metadados de fonte |
| Publication Service | projeção pública sem dados restritos |
| Audit Service | eventos append-only, consulta autorizada e exportação |
| Notification Service | e-mail institucional de confirmação, avisos e prazos |

### Endpoints mínimos

```text
GET    /api/v1/public/municipios?uf=&situacao=&q=
GET    /api/v1/public/municipios/{ibge}
GET    /api/v1/public/municipios.geojson?filtro=
GET    /api/v1/public/fontes
GET    /api/v1/me
GET    /api/v1/me/permissoes
POST   /api/v1/municipios/{ibge}/inscricao
PATCH  /api/v1/inscricoes/{id}
POST   /api/v1/inscricoes/{id}/documentos
POST   /api/v1/inscricoes/{id}/manifestacao
POST   /api/v1/inscricoes/{id}/confirmar
GET    /api/v1/inscricoes/{id}/historico
GET    /api/v1/inscricoes/{id}/obrigacoes
PATCH  /api/v1/obrigacoes/{id}
GET    /api/v1/auditoria?entidade=&periodo=
```

Os endpoints administrativos devem exigir autorização por transação e escopo. O frontend nunca deve decidir se uma ação é permitida.

## 4. Segurança e operação

- TLS ponta a ponta e headers de segurança;
- WAF, rate limit e proteção contra abuso nos endpoints públicos;
- validação de entrada, ORM/queries parametrizadas e proteção CSRF quando aplicável;
- secrets no cofre institucional, nunca no repositório ou bundle frontend;
- backup criptografado, restauração testada e RPO/RTO definidos;
- SAST, dependabot/renovação de dependências, DAST e teste de penetração antes da produção;
- alertas para falha de login, tentativas negadas, downloads anormais, malware e alteração de listas;
- ambientes separados: desenvolvimento, homologação, produção;
- dados fictícios em desenvolvimento; dados reais somente em ambiente autorizado;
- logs sem CPF completo, token, documento pessoal ou conteúdo de arquivo.

Como referência, a equipe deve considerar o [Guia de Requisitos Mínimos para APIs](https://www.gov.br/governodigital/pt-br/privacidade-e-seguranca/ppsi/guia_requisitos_minimos_apis.pdf), o [Modelo de Política de Controle de Acesso](https://www.gov.br/governodigital/pt-br/privacidade-e-seguranca/ppsi/modelo_politica_controle_acesso.pdf) e o [Guia de Requisitos Mínimos para Aplicações Web](https://www.gov.br/governodigital/pt-br/privacidade-e-seguranca/framework-guias-e-modelos/copy_of_pagina_guias_e_modelos).

## 5. Integrações externas

| Fonte | Uso | Regra |
|---|---|---|
| Login gov.br | identidade | backend valida tokens; não armazenar senha |
| IBGE | municípios, UFs, códigos e malhas | guardar versão/data e usar cache |
| Casa Civil | notas e listas de indicação | carga versionada e revisão humana |
| SGB/CPRM | cartografia de riscos geológicos | referência técnica, não substitui documento municipal |
| CEMADEN | monitoramento/previsão | não misturar com camada de suscetibilidade |
| S2iD | cadastros efetivados, se formalmente disponibilizado | integração por acordo e escopo definido |

Para interoperabilidade, avaliar o [Conecta gov.br](https://www.gov.br/governodigital/pt-br/infraestrutura-nacional-de-dados/interoperabilidade/conecta-gov.br/conecta-gov-br) quando houver API de referência adequada.

## 6. Entregáveis da implementação

1. arquitetura aprovada e threat model;
2. contrato OpenAPI e matriz de permissões;
3. protótipo navegável homologado com usuários municipais;
4. backend com workflow e auditoria;
5. banco PostGIS e migrações versionadas;
6. serviço de documentos com antivírus e retenção;
7. integração gov.br em homologação;
8. testes de acessibilidade e segurança;
9. manual operacional e plano de sustentação;
10. plano de carga inicial das listas técnicas e reconciliação com S2iD.
