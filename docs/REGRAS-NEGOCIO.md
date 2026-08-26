# Regras de negócio — Cadastro Nacional de Municípios

## 1. Objetivo

Este documento traduz para o fluxo digital do protótipo as regras funcionais do Cadastro Nacional de Municípios com Áreas Suscetíveis à Ocorrência de Deslizamentos de Grande Impacto, Inundações Bruscas ou Processos Geológicos ou Hidrológicos Correlatos.

As regras devem ser validadas pela área normativa e pela equipe de TI antes da implantação. A fonte jurídica principal é o [Decreto nº 10.692/2021](https://www.planalto.gov.br/ccivil_03/_ato2019-2022/2021/decreto/d10692.htm), especialmente os arts. 3º a 7º.

## 2. Conceitos e situações

| Conceito | Tratamento no sistema |
|---|---|
| Município indicado | Município constante da lista técnica vigente da União ou indicado pelo Estado. A indicação não equivale à inscrição efetivada. |
| Município solicitante | Município que inicia a inscrição por iniciativa própria, conforme a origem registrada no processo. |
| Cadastro em preenchimento | Rascunho persistido, ainda sem envio para análise. |
| Cadastro em análise | Pedido enviado, com protocolo, aguardando conferência administrativa e técnica. |
| Cadastro efetivado | Pedido deferido e incluído no Cadastro Nacional. |
| Pendência | Pedido que precisa de complementação ou correção, com justificativa e prazo definidos pela área competente. |
| Indeferido | Pedido encerrado por decisão fundamentada. O histórico deve permanecer disponível para auditoria. |

## 3. Regras funcionais

### RN01 — Autenticação e identificação

1. O usuário deve selecionar o perfil de acesso antes de iniciar a autenticação.
2. A versão de produção deve usar a identidade autenticada pelo Login Único gov.br.
3. A sessão deve vincular usuário, CPF mascarado ou identificador técnico equivalente, órgão, município ou unidade administrativa autorizada.
4. O sistema deve registrar data, hora, transação e resultado da autenticação.

### RN02 — Perfis e escopos

1. **Município:** cria e acompanha o processo do próprio código IBGE, envia documentos e responde a pendências.
2. **Estado:** consulta e acompanha municípios do escopo estadual autorizado, registra apoio técnico e exporta relatórios permitidos.
3. **União:** administra listas, fontes, análise nacional, decisões e publicação de dados conforme autorização administrativa.
4. **Controle e fiscalização:** consulta dados públicos e, mediante autorização formal, acessa evidências e trilhas de auditoria sem alterar o cadastro.
5. Toda API deve aplicar autorização por perfil, transação e escopo territorial. O front-end não deve ser a única camada de controle.

### RN03 — Origem da inscrição

1. A origem do pedido deve ser uma das opções: solicitação do Município, indicação do Estado ou indicação da União.
2. A fonte da indicação, a versão da lista e a data de referência devem ser armazenadas.
3. Um município indicado pode iniciar o processo, mas a indicação deve permanecer visível como atributo separado da situação cadastral.

### RN04 — Comprovação de área de risco

1. Todo processo deve conter pelo menos um arquivo de comprovação antes do envio.
2. São aceitos, conforme parametrização institucional, inventário ou outros documentos expedidos por órgãos ou entidades federais, estaduais ou municipais.
3. Também podem ser aceitos documentos gerados por agentes privados legalmente habilitados, desde que aplicada metodologia adotada por órgão ou entidade da União, dos Estados ou dos Municípios.
4. O inventário deve conter cadastro ou relação georreferenciada dos imóveis e infraestruturas expostas ao alto impacto na área considerada.
5. O protótipo aceita ZIP, GeoJSON, JSON, PDF, SHP e GPKG para simulação. A versão de produção deve validar extensão, tamanho, integridade, antivírus e, quando aplicável, geometria e sistema de referência espacial.

### RN05 — Manifestação prévia para município indicado

1. Se o código IBGE estiver na lista vigente de indicados, o campo de manifestação deve ser exibido e ser obrigatório.
2. O avanço fica bloqueado enquanto o responsável não atestar a concordância com a indicação técnica.
3. A manifestação deve registrar usuário, órgão, data, hora, versão da lista e texto apresentado ao responsável.
4. Se o município não estiver na lista de indicados, o campo de atesto não deve ser exibido; a comprovação documental continua obrigatória.

### RN06 — Validação e avanço do Wizard

1. A etapa de identificação exige município e responsável pelo cadastro.
2. A etapa de comprovação exige arquivo selecionado.
3. A etapa de manifestação exige atesto somente quando RN05 for aplicável.
4. Ao tentar avançar sem cumprir requisito, o sistema deve informar exatamente o que falta, sem apagar os dados já preenchidos.
5. O usuário pode salvar um rascunho e retomar posteriormente.

### RN07 — Revisão, protocolo e análise

1. Antes do envio, o sistema deve apresentar resumo do município, responsável, origem, arquivo e manifestação.
2. O envio deve gerar protocolo único e registrar versão do processo.
3. Após o envio, a situação deve mudar para **Em análise**.
4. A área competente pode efetivar, solicitar complementação ou indeferir, sempre com usuário, data, justificativa e documentos relacionados.
5. O município não deve conseguir apagar versões ou decisões; correções devem gerar nova versão e histórico.

### RN08 — Obrigações após a inclusão

Para municípios inscritos, o painel deve acompanhar os documentos e prazos relacionados ao art. 5º do Decreto nº 10.692/2021:

1. instituição de órgão municipal de defesa civil;
2. mapeamento georreferenciado das áreas suscetíveis;
3. plano de contingência de proteção e defesa civil no prazo de um ano contado da inclusão;
4. plano de implantação de obras e serviços para redução de riscos;
5. mecanismos de controle e fiscalização de novas edificações;
6. carta geotécnica de aptidão à urbanização e diretrizes urbanísticas; e
7. atualização anual do Cadastro Nacional sobre a evolução das ocupações.

Cada obrigação deve possuir situação, documento, data de referência, prazo, responsável, observação e histórico de alterações.

### RN09 — Transparência e dados públicos

1. A consulta pública deve diferenciar indicação, preenchimento, análise e cadastro efetivado.
2. O mapa deve permitir consulta por município, UF, situação e código IBGE.
3. Toda publicação deve informar fonte, versão, data de atualização e limitações dos dados.
4. As exportações públicas devem conter somente campos definidos como públicos e não podem expor dados pessoais desnecessários.

### RN10 — Auditoria, integridade e proteção de dados

1. Ações relevantes devem gerar evento de auditoria: login, criação, alteração, upload, manifestação, envio, decisão, exportação e concessão de acesso.
2. Arquivos devem ser armazenados em objeto imutável ou versionado, com hash, metadados e controle de acesso.
3. O sistema deve aplicar minimização, finalidade, retenção e controle de acesso conforme a LGPD e as normas institucionais.
4. Órgãos de controle e Ministério Público devem receber acesso apenas ao escopo autorizado, preservando a rastreabilidade das consultas.

## 4. Matriz resumida de transições

| Situação atual | Ação | Pré-condição | Próxima situação |
|---|---|---|---|
| Em preenchimento | Salvar rascunho | Usuário autenticado | Em preenchimento |
| Em preenchimento | Enviar | Comprovação e manifestação condicional válidas | Em análise |
| Em análise | Solicitar complementação | Decisão fundamentada | Pendência |
| Em análise | Deferir | Conferência concluída | Cadastro efetivado |
| Em análise | Indeferir | Decisão fundamentada | Indeferido |
| Pendência | Corrigir e reenviar | Complementação apresentada | Em análise |
| Cadastro efetivado | Atualização anual | Registro anual informado | Cadastro efetivado, nova versão |

## 5. Parâmetros que precisam de decisão institucional

- tamanho máximo e política de formatos dos arquivos;
- lista vigente e processo formal de sua publicação;
- unidades responsáveis pela análise e pelos recursos;
- prazos operacionais para complementação e decisão;
- campos públicos e campos restritos;
- política de retenção e descarte de documentos;
- metodologia de validação geoespacial;
- integração oficial com gov.br, AuthorizaGov, SEI, armazenamento institucional e serviços de mapas.

