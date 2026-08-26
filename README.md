# Cadastro Nacional de Municípios · versão Gov.br

Segunda versão isolada do protótipo do Cadastro Nacional de Municípios com Áreas Suscetíveis à Ocorrência de Deslizamentos de Grande Impacto, Inundações Bruscas ou Processos Geológicos ou Hidrológicos Correlatos.

Esta pasta não altera nem substitui o protótipo apresentado anteriormente em `CNM-RISCO`. Ela demonstra a mesma jornada com componentes e princípios do [Padrão Digital Gov.br](https://www.gov.br/ds/home), versão 3.7.0, e foi preparada para servir como referência visual e técnica à equipe de TI.

## Acesso rápido

> **[Abrir o protótipo publicado no GitHub Pages →](https://sedec-dpm-cgnat.github.io/cadastro-municipios-govbr/)**

Consulte também as [regras de negócio](docs/REGRAS-NEGOCIO.md) e a documentação técnica para a equipe de TI.

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
- reinício da simulação para demonstrar novamente o cadastro desde a primeira etapa;
- visões de estado, União e controle com permissões de somente leitura no protótipo;
- documentação de acesso, arquitetura, API, segurança, LGPD e modelo de dados para implementação institucional.

## Documentação para TI

- [Especificação Gov.br e matriz de acesso](docs/ESPECIFICACAO-GOVBR-TI.md)
- [Arquitetura e componentes técnicos](docs/ARQUITETURA-GOVBR.md)
- [Modelo de dados e API proposta](docs/MODELO-DADOS-GOVBR.md)
- [Fontes e referências do Design System](docs/REFERENCIAS-GOVBR.md)

## Observação

O login, a autorização, o upload e os dados exibidos são simulados. A integração produtiva deverá ser homologada pela área responsável e utilizar o ecossistema de identidade digital gov.br, autorização por perfil/escopo e a infraestrutura do Ministério.
