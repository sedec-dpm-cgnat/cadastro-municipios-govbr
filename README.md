# Cadastro Nacional de Municípios · versão Gov.br

Segunda versão isolada do protótipo do Cadastro Nacional de Municípios com Áreas Suscetíveis à Ocorrência de Deslizamentos de Grande Impacto, Inundações Bruscas ou Processos Geológicos ou Hidrológicos Correlatos.

Esta pasta não altera nem substitui o protótipo apresentado anteriormente em `CNM-RISCO`. Ela demonstra a mesma jornada com componentes e princípios do [Padrão Digital Gov.br](https://www.gov.br/ds/home), versão 3.7.0, e foi preparada para servir como referência visual e técnica à equipe de TI.

> **Atenção — material de referência:** este repositório contém um protótipo funcional para avaliação do futuro serviço. Não é o sistema oficial, não efetiva inscrições e não deve receber dados pessoais, documentos reais ou credenciais. Login, arquivos, mapa temático e indicadores apresentados são simulados ou demonstrativos.

## O que é este projeto?

É uma proposta de experiência digital para o Cadastro Nacional de Municípios com Áreas Suscetíveis à Ocorrência de Deslizamentos de Grande Impacto, Inundações Bruscas ou Processos Geológicos ou Hidrológicos Correlatos. A página permite navegar pela consulta pública, visualizar a distinção entre municípios indicados e cadastrados, selecionar perfis de acesso e simular a jornada municipal de identificação, comprovação, manifestação, revisão, efetivação automática e acompanhamento dos documentos obrigatórios.

O projeto foi organizado para apoiar três finalidades:

1. apresentar às áreas gestoras uma experiência simples, direta e visualmente alinhada ao Gov.br;
2. permitir que a equipe de TI avalie componentes, estados de tela e integrações necessárias;
3. registrar regras de negócio, arquitetura, modelo de dados e documentação do código para orientar a implementação institucional em PHP e PostgreSQL/PostGIS.

## O que não está implementado aqui?

Esta versão não possui autenticação real gov.br, banco de dados, persistência de rascunhos, armazenamento institucional de documentos ou API de produção. O botão de login, os uploads e a efetivação são simulações locais no navegador. A futura versão institucional deverá ser implementada e homologada na infraestrutura do Ministério pela equipe responsável.

## Acesso rápido

> **[Abrir o protótipo publicado no GitHub Pages →](https://sedec-dpm-cgnat.github.io/cadastro-municipios-govbr/)**

Consulte também as [regras de negócio](docs/REGRAS-NEGOCIO.md) e a [documentação do código do aplicativo](docs/DOCUMENTACAO-CODIGO.md).

## Executar

```powershell
python -m http.server 4174
```

Abra `http://127.0.0.1:4174`.

## O que esta versão demonstra

- cabeçalho institucional, breadcrumb, botões, cards, mensagens, tags e rodapé alinhados ao Design System Gov.br;
- seleção de perfil antes do botão de autenticação gov.br;
- painel público sem autenticação, com mapa Leaflet, poligonais IBGE, filtros e downloads;
- distinção cartográfica entre indicados, cadastrados e demais municípios;
- área municipal com Wizard iniciado pela identificação do responsável, upload do ato formal de designação, atesto condicional e preparação da jornada pós-inscrição;
- tela de confirmação após a efetivação, com protocolo demonstrativo e aviso de e-mail de confirmação para a conta cadastrada;
- painel pós-cadastro com as sete obrigações do art. 5º, upload de documentos comprobatórios, situação, observações e resumo do cadastro;
- reinício da simulação para demonstrar novamente o cadastro desde a primeira etapa;
- visões de estado, União e controle com permissões de somente leitura no protótipo;
- documentação de acesso, arquitetura, API, segurança, LGPD e modelo de dados para implementação institucional.

## Documentação para TI

- [Documentação do código do aplicativo](docs/DOCUMENTACAO-CODIGO.md)
- [Especificação Gov.br e matriz de acesso](docs/ESPECIFICACAO-GOVBR-TI.md)
- [Arquitetura e componentes técnicos](docs/ARQUITETURA-GOVBR.md)
- [Modelo de dados e API proposta](docs/MODELO-DADOS-GOVBR.md)
- [Fontes e referências do Design System](docs/REFERENCIAS-GOVBR.md)

## Observação

O login, a autorização, o upload e os dados exibidos são simulados. A integração produtiva deverá ser homologada pela área responsável e utilizar o ecossistema de identidade digital gov.br, autorização por perfil/escopo e a infraestrutura do Ministério.
