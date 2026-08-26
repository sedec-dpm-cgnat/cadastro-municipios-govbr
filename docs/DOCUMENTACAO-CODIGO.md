# Documentação do código do aplicativo

## 1. Finalidade

Este documento orienta a equipe de TI na leitura e na evolução do código do protótipo publicado em:

<https://sedec-dpm-cgnat.github.io/cadastro-municipios-govbr/>

O protótipo é uma aplicação web estática, sem persistência real, autenticação produtiva ou envio de arquivos para um servidor. Ele foi organizado para demonstrar a jornada, as regras de interface e os pontos de integração que deverão ser substituídos na implementação institucional.

## 2. Estrutura do repositório

| Caminho | Responsabilidade |
|---|---|
| [`index.html`](../index.html) | Estrutura semântica da página, áreas públicas, perfis de acesso, Wizard municipal, regras e modal de feedback. |
| [`styles.css`](../styles.css) | Identidade visual, responsividade, estados do Wizard, mensagens, mapa, cards e ajustes sobre o Design System Gov.br. |
| [`app.js`](../app.js) | Comportamento da aplicação: navegação, perfis simulados, validações, uploads demonstrativos, Wizard, mapa Leaflet e filtros. |
| [`data/indicados-2095.js`](../data/indicados-2095.js) | Conjunto demonstrativo dos códigos IBGE da lista vigente de municípios indicados. |
| [`.github/workflows/pages.yml`](../.github/workflows/pages.yml) | Publicação automática do pacote público no GitHub Pages a cada atualização da branch `main`. |
| [`docs/REGRAS-NEGOCIO.md`](REGRAS-NEGOCIO.md) | Regras funcionais, transições, obrigações, transparência, auditoria e parâmetros que exigem decisão institucional. |
| [`docs/ESPECIFICACAO-GOVBR-TI.md`](ESPECIFICACAO-GOVBR-TI.md) | Requisitos Gov.br, matriz de acesso, segurança, LGPD e recomendações para a equipe de TI. |
| [`docs/ARQUITETURA-GOVBR.md`](ARQUITETURA-GOVBR.md) | Proposta de arquitetura, camadas, integrações e componentes técnicos. |
| [`docs/MODELO-DADOS-GOVBR.md`](MODELO-DADOS-GOVBR.md) | Modelo de dados e API proposta para a implementação institucional. |

## 3. Inicialização do front-end

Ao carregar o documento, o evento `DOMContentLoaded` executa quatro blocos de interface e inicia o mapa:

```js
setupShell();
setupProfiles();
setupUpload();
setupMapControls();
loadNationalMap();
```

O `index.html` importa, nesta ordem, Leaflet, a lista de códigos indicados, o pacote do Design System Gov.br e o `app.js`. A ordem da lista antes do aplicativo é importante porque a validação do atesto depende de `window.CNM_INDICATED_CODES`.

## 4. Fluxo do cadastro municipal

O estado do protótipo é mantido pela variável `currentWizardStep`:

| Etapa | Conteúdo | Regra de avanço |
|---|---|---|
| 1. Identificação | Município, responsável e ato formal de designação | Responsável informado e ato anexado. |
| 2. Comprovação | Inventário, relação georreferenciada ou documento de comprovação | Arquivo de comprovação anexado. |
| 3. Manifestação | Atesto condicional da indicação técnica | Exigido somente se o código IBGE estiver em `indicatedCodes`. Para município não indicado, a manifestação não é cobrada. |
| 4. Revisão e efetivação | Resumo, checklist e confirmação demonstrativa | Todas as validações anteriores atendidas. |

As regras são centralizadas em `wizardRequirements(step)`. Os botões de avanço chamam `updateWizardValidation(...)` antes de executar `setWizardStep(...)`. Assim, a etapa 2 não valida o atesto; essa validação ocorre exclusivamente ao avançar da etapa 3 para a revisão.

O botão `Reiniciar simulação` executa `resetMunicipalWizard()`, limpa campos, anexos e atesto e retorna o Wizard para a etapa 1. Os botões de demonstração criam objetos `File` locais para permitir o teste sem transmitir arquivos.

### 4.1. Confirmação pós-cadastro

Depois que a validação da etapa 4 é concluída, `setupProfiles()` oculta o elemento `#municipal-wizard` e exibe `#submission-confirmation`. A tela apresenta situação “Cadastro efetivado”, protocolo demonstrativo e a mensagem de que um e-mail de confirmação foi enviado para a conta cadastrada do responsável.

No protótipo, essa mensagem não dispara uma comunicação real. Na produção, a API deverá criar o protocolo, persistir o evento, enfileirar a notificação e registrar sucesso ou falha da entrega sem bloquear a consulta do protocolo pelo município.

### 4.2. Painel pós-cadastro e documentos obrigatórios

Na tela de confirmação, o botão `#open-obligations` abre o painel `#obligations-workspace`. O cadastro já está efetivado quando a confirmação é exibida; o botão apenas conduz o usuário à jornada de documentos e obrigações pós-cadastro.

As sete obrigações são definidas em `obligationDefinitions` no `app.js` e renderizadas por `renderObligationCards()`. Cada item possui campo de upload, situação (`Não iniciado`, `Em andamento` ou `Concluído`) e observação. `updateObligationSummary()` atualiza os indicadores 0/7, andamento e pendências. Os botões `Usar arquivo demonstrativo` criam arquivos locais apenas para permitir a apresentação do fluxo sem transmitir conteúdo.

Na implementação, o painel deve ser retornado pela API somente quando o usuário estiver autorizado para o município e o processo estiver efetivado. Os sete documentos, metadados, prazos, responsáveis, versões, hashes e alterações devem ser persistidos e auditados; a interface do protótipo não substitui o armazenamento institucional nem a validação administrativa.

## 5. Perfis e autenticação simulada

`profiles` contém os quatro perfis demonstrados: Município, Estado, União e Controle e fiscalização. A função `setupProfiles()` atualiza o escopo, as permissões e o painel exibido.

Na produção, o botão `Continuar com gov.br` deverá ser substituído pelo fluxo oficial de autenticação e retorno ao serviço. A autenticação identifica a pessoa; a autorização deverá ser realizada no back-end por perfil, transação e escopo territorial. O front-end nunca deve ser a única barreira de segurança.

## 6. Uploads demonstrativos

`setupUpload()` trata dois campos:

- `formal-act-file`: ato formal que designa o representante municipal;
- `risk-file`: comprovação da existência de áreas de risco.

Os campos pós-cadastro são gerados por `setupObligations()` a partir de `obligationDefinitions`. Cada `obligation-file` permanece no navegador durante a demonstração e atualiza a linha correspondente; os selects `obligation-state-*` alimentam os indicadores do painel.

No protótipo, o arquivo permanece apenas no navegador e seu nome é apresentado na tela. Na produção, a API deverá receber o arquivo por conexão autenticada, validar extensão e tamanho, verificar antivírus, gerar hash, registrar metadados, versionar o documento e armazená-lo em repositório institucional.

## 7. Mapa nacional

`loadNationalMap()` cria o mapa Leaflet e consulta:

- limites municipais e estaduais na API de malhas do IBGE;
- nomes e UFs na API de localidades do IBGE;
- códigos indicados no arquivo local `data/indicados-2095.js`.

`featureStatus()` classifica cada município como `registered`, `in-progress`, `indicated` ou `other`. `mapStyle()` aplica as regras visuais: cadastrados com hachura vermelha, indicados com poligonal vermelha e demais municípios com contorno preto sem preenchimento. A camada estadual serve como referência visual e os controles Leaflet permitem zoom e navegação.

Os cinco municípios cadastrados e o município em preenchimento são dados demonstrativos no `app.js`. Em produção, essas coleções devem vir de uma API pública versionada, com fonte, data de atualização e situação do processo.

## 8. Execução local

Na raiz do projeto:

```powershell
python -m http.server 4174
```

Depois, acessar <http://127.0.0.1:4174>.

Não é recomendado abrir o `index.html` diretamente pelo sistema de arquivos, pois as requisições do mapa e os scripts podem sofrer restrições de origem.

## 9. Publicação

O workflow de Pages copia somente os arquivos necessários ao protótipo público para `dist/`: `index.html`, `styles.css`, `app.js` e `data/indicados-2095.js`. A documentação permanece disponível no repositório do GitHub e não é incluída no pacote público da página.

Para publicar uma atualização:

1. alterar e testar os arquivos;
2. executar `node --check app.js`;
3. revisar a alteração e criar um commit na branch `main`;
4. fazer push para o GitHub;
5. acompanhar a execução do workflow **Publicar protótipo no GitHub Pages**;
6. testar o endereço público após a conclusão.

## 10. Próxima etapa de implementação

Para transformar o protótipo em serviço institucional, a equipe deverá substituir os pontos simulados por:

1. autenticação gov.br e autorização por perfil/escopo;
2. API REST ou serviço equivalente para municípios, cadastros, documentos e obrigações;
3. banco relacional com suporte espacial, preferencialmente PostgreSQL/PostGIS;
4. armazenamento institucional de objetos com versionamento e hash;
5. fila de processamento de arquivos, antivírus e validação geoespacial;
6. trilha de auditoria imutável e observabilidade;
7. geração controlada de CSV, GeoJSON e relatórios;
8. integração com SEI, fontes oficiais, serviços de mapas e demais sistemas definidos pelo Ministério.

As decisões de negócio, prazos, perfis internos, campos públicos, retenção e parâmetros de arquivos estão documentadas nos documentos técnicos vinculados ao README e devem ser homologadas antes da contratação ou implantação.
