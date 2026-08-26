# Especificação Gov.br e matriz de acesso

## 1. Objetivo

O sistema deverá oferecer um serviço público digital para:

1. receber a inscrição do município no Cadastro Nacional;
2. acompanhar manifestação, análise e decisão;
3. habilitar o acompanhamento das responsabilidades do art. 5º após a efetivação;
4. publicar listas, situação, fontes, documentos públicos e mapa nacional;
5. preservar trilha de auditoria, proteção de dados e segregação de funções.

A versão Gov.br do protótipo separa claramente duas decisões:

- **autenticação:** quem é a pessoa, resolvido pelo Login Único gov.br;
- **autorização:** o que ela pode fazer, em qual município/UF/unidade e em qual transação, resolvido pelo sistema e, se adotado pelo Ministério, pelo AutorizaGov.

Essa separação é essencial: uma conta gov.br válida não deve conceder, por si só, acesso a dados ou ações administrativas.

## 2. Padrão de interface

O protótipo aplica a versão 3.7.0 do [Padrão Digital Gov.br](https://www.gov.br/ds/home) por meio de componentes semânticos e overrides mínimos:

| Necessidade | Componente/padrão Gov.br | Uso no serviço |
|---|---|---|
| Identificação institucional | Header, Footer | gov.br, MIDR/SEDEC/DPM, links institucionais |
| Localização | Breadcrumb | Página inicial, transparência, cadastro, documentos |
| Entrada no serviço | Sign-in, Button, Radio | Escolha do perfil antes da autenticação |
| Formulário | Input, Select, Checkbox, Message | Identificação, manifestação e validações |
| Cadastro em etapas | Wizard/Step | Identificação, comprovação, manifestação e revisão |
| Documentos | Upload, List, Loading, Message | Pacote inicial e sete campos pós-inscrição |
| Informação pública | Card, Tag, Table, Pagination | Listas, fontes, situação e documentos |
| Feedback | Message, Notification, Modal | Sucesso, alerta, erro, sessão e manutenção |
| Mapa | Componente de aplicação integrado | Leaflet + malha IBGE + camadas temáticas |

Diretrizes aplicadas:

- Rawline como tipografia principal;
- escala de layout em múltiplos de 8 px e escala fina de 4 px;
- paleta institucional e cores de estado com contraste verificado;
- foco de teclado sempre visível, `label` associado, HTML semântico e `aria-live` para feedback;
- skip link, navegação responsiva e ausência de dependência exclusiva de arrastar/hover;
- linguagem direta: um título, uma ação principal e uma explicação curta por etapa.

As referências são o [Padrão Mínimo](https://www.gov.br/ds/introducao/padrao-minimo), os [Componentes](https://www.gov.br/ds/components/visao-geral), [Acessibilidade](https://www.gov.br/ds/acessibilidade), [Upload](https://www.gov.br/ds/components/upload), [Wizard](https://www.gov.br/ds/components/wizard?tab=designer) e [Fundamentos Visuais](https://www.gov.br/ds/fundamentos-visuais/visao-geral).

## 3. Acesso público

Não exige login:

- explicação do Cadastro Nacional e da indicação técnica;
- lista de municípios indicados e cadastrados;
- mapa nacional e consulta por código IBGE, município e UF;
- dados estatísticos agregados;
- documentos e versões marcados como públicos;
- downloads CSV/GeoJSON e documentação da API pública;
- metodologia vigente, notas técnicas e histórico de atualização.

O painel público não deve expor CPF, e-mail, telefone, documentos pessoais, rascunhos, pareceres internos ou trilhas restritas.

## 4. Matriz de perfis

### 4.1 Perfis apresentados ao usuário

| Perfil | Escopo padrão | Pode fazer | Não pode fazer |
|---|---|---|---|
| Município | Código IBGE do município vinculado | iniciar/editar inscrição, enviar pacote, manifestar-se, acompanhar documentos próprios, atualizar obrigações após efetivação | consultar outro município, alterar lista técnica, aprovar a própria inscrição, publicar dados |
| Estado | UF e municípios autorizados | consultar evolução regional, registrar apoio, acompanhar pendências e exportar relatórios do escopo | alterar cadastro municipal, aprovar inscrição, publicar lista nacional, acessar dados fora da UF |
| União | unidade administrativa e abrangência nacional definida | manter fontes/listas, analisar processos, registrar decisão, publicar dados, acompanhar indicadores | atuar fora da unidade concedida; não deve acumular aprovação e administração de acesso sem segregação |
| Controle e fiscalização | dados públicos; escopo restrito quando formalmente concedido | consultar, exportar evidências, visualizar trilha autorizada e solicitar informação | inserir/alterar cadastro, excluir documento, alterar situação ou conceder acesso |

### 4.2 Perfis operacionais internos recomendados

Os quatro perfis acima são portas de entrada. No backend, a equipe deve decompor a operação em papéis menores:

| Papel interno | Finalidade |
|---|---|
| Gestor de acesso | atribuir/revogar perfis e escopos; não analisa o próprio processo |
| Operador municipal | preparar dados e documentos do município |
| Representante municipal | confirmar manifestação e enviar o cadastro |
| Analista técnico | analisar documentos e registrar pendências |
| Publicador | revisar e publicar dados públicos |
| Administrador de referência | manter municípios, UFs, fontes e versões |
| Auditor | consultar eventos e relatórios sem alterar dados |
| Administrador de sistema | configuração técnica, sem poder aprovar processo de negócio |

Essa separação segue o modelo de perfis e transações descrito pelo [AutorizaGov](https://www.gov.br/governodigital/pt-br/plataformas-e-servicos-digitais/autorizagov/funcionalidades-do-autorizagov200b): perfis representam papéis e transações representam as operações permitidas.

## 5. Requisitos de autenticação e autorização

### Autenticação

- integrar ao [ecossistema de identidade digital gov.br](https://www.gov.br/governodigital/pt-br/estrategias-e-governanca-digital/transformacao-digital/servico-de-integracao-aos-produtos-de-identidade-digital-gov.br);
- usar Authorization Code/OIDC conforme o roteiro oficial, sem armazenar senha gov.br;
- manter `state`, `nonce`, PKCE quando suportado, redirect URI exata e validação de issuer/audience/expiração do token;
- toda comunicação em HTTPS; não usar WebView para o fluxo de autenticação;
- criar sessão própria com cookie `Secure`, `HttpOnly`, `SameSite`, expiração e revogação;
- registrar somente o identificador mínimo necessário e o nível de confiabilidade retornado;
- exigir autenticação novamente para operação sensível ou sessão expirada.

### Autorização

- avaliar cada requisição no backend; esconder botão no frontend não é controle de segurança;
- aplicar RBAC para o papel e ABAC para UF, município, órgão, situação do processo e transação;
- manter vínculo explícito entre usuário e entidade: município, órgão estadual, unidade federal ou órgão de controle;
- exigir aprovação por gestor de acesso para novos vínculos e alteração de escopo;
- aplicar segregação de funções: quem envia não aprova; quem administra acesso não audita a própria concessão;
- negar por padrão (`deny by default`) e registrar toda concessão, revogação e tentativa negada;
- versionar permissões e manter histórico para reconstruir o estado de uma decisão.

### Nível de conta gov.br

Como requisito de projeto, recomenda-se:

- consulta pública: sem login;
- consulta autenticada de órgão: conta gov.br compatível com a política institucional;
- alteração de cadastro, upload e manifestação municipal: nível mínimo definido pela homologação do serviço, recomendado **Prata**;
- atos que exigirem assinatura eletrônica avançada ou manifestação qualificada: considerar **Prata/Ouro** conforme regra jurídica e integração de assinatura;
- nunca confundir nível da conta com prova de representação do município. O vínculo institucional deverá ser validado por cadastro de responsáveis, ato de designação ou procedimento aceito pelo Ministério.

O nível mínimo final deve ser confirmado pela área jurídica, segurança e gestora do serviço durante a homologação gov.br.

## 6. Estados de negócio

O processo deve usar uma máquina de estados, não apenas um campo textual:

`RASCUNHO → ENVIADO → EM_ANALISE → PENDENCIA → DEVOLVIDO → APROVADO → EFETIVADO → SUSPENSO/ARQUIVADO`

Regras essenciais:

- o atesto aparece somente na etapa de manifestação e somente quando `municipio.indicado_atual = true`;
- o upload inicial é obrigatório antes de `ENVIADO`;
- a inscrição não é efetivada apenas pelo preenchimento do formulário;
- documentos pós-inscrição somente ficam editáveis quando `status = EFETIVADO`;
- toda transição exige usuário, data/hora, justificativa quando aplicável e versão dos documentos;
- documentos substituídos não devem ser apagados fisicamente: recebem nova versão e permanecem no histórico.

## 7. Upload e documentos

O componente deve aceitar ZIP como formato preferencial, sem impedir PDF, GeoJSON, GPKG ou outros formatos aprovados pela especificação técnica. O backend deverá:

- impor limite de tamanho e quantidade;
- validar extensão, MIME real e assinatura do arquivo;
- descompactar em área temporária isolada, com proteção contra path traversal e zip bomb;
- verificar malware/antivírus antes de disponibilizar o arquivo;
- calcular SHA-256 e bloquear duplicata conforme regra do processo;
- registrar nome, tamanho, MIME, hash, usuário, município, data, versão e classificação pública/restrita;
- armazenar fora do diretório público, servindo o download por URL autorizada e temporária;
- gerar miniatura/metadados apenas quando necessário;
- aplicar retenção e eliminação conforme tabela de temporalidade e orientação jurídica.

## 8. Critérios de aceite do frontend

- navegação completa por teclado;
- foco visível e ordem lógica;
- leitura funcional por leitor de tela nos formulários, mensagens e tabelas;
- mapa com alternativa textual: busca por município, UF e código IBGE;
- mapa não pode ser o único meio de conhecer a situação;
- contraste, zoom de texto e responsividade validados;
- feedback de upload com estado de carregamento, sucesso e erro;
- testes com Lighthouse/axe, teclado, leitor de tela e viewport móvel;
- nenhum segredo, token ou regra de autorização no JavaScript público.
