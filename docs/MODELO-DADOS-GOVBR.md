# Modelo de dados e contrato de API

## 1. Entidades centrais

| Entidade | Chave | Conteúdo |
|---|---|---|
| `municipality` | código IBGE | nome, UF, geometria e vigência |
| `source_reference` | UUID | nota técnica, versão, URL, hash e data |
| `indication` | município + fonte | indicação vigente, metodologia e histórico |
| `identity` | `govbr_sub` | identidade mínima retornada pelo provedor |
| `organization` | UUID | prefeitura, órgão estadual, unidade federal ou controle |
| `access_grant` | usuário + papel + escopo | autorização temporal, status e concedente |
| `registration` | UUID | inscrição, status, versão e município |
| `registration_event` | UUID | transições e justificativas |
| `document` | UUID | metadados do objeto, hash, scan e visibilidade |
| `obligation` | inscrição + artigo | sete responsabilidades pós-efetivação |
| `audit_event` | UUID | evento append-only de segurança e negócio |

## 2. Princípios de modelagem

- código IBGE é referência externa, não deve ser substituído por nome do município;
- fontes técnicas são versionadas; nunca atualizar uma lista sem criar nova versão;
- inscrição e indicação são entidades diferentes;
- documento é imutável por versão; substituição cria novo registro;
- status de negócio é controlado por eventos e transições permitidas;
- campos pessoais devem ser minimizados, classificados e protegidos;
- projeção pública deve ser uma view ou read model sem campos restritos;
- geometrias devem ter SRID definido, validade verificada e simplificação própria para web.

## 3. Exemplo de resposta pública

```json
{
  "codigoIbge": "3550704",
  "municipio": "São Sebastião",
  "uf": "SP",
  "indicacao": {
    "status": "INDICADO",
    "fonte": "NT 2/2025",
    "versao": "2025.2",
    "atualizadoEm": "2026-08-25"
  },
  "inscricao": {
    "status": "EM_PREENCHIMENTO",
    "publicada": false
  },
  "geometria": {
    "tipo": "municipio",
    "url": "/api/v1/public/municipios/3550704.geojson"
  }
}
```

## 4. Exemplo de transação de autorização

```json
{
  "usuario": "govbr-sub-interno",
  "papel": "REPRESENTANTE_MUNICIPAL",
  "transacao": "INSCRICAO_CONFIRMAR",
  "escopo": { "codigoIbge": "3550704" },
  "permitido": true,
  "motivo": "vínculo ativo e município no escopo do usuário"
}
```

O valor de `usuario` acima é ilustrativo. Não colocar CPF ou token em logs, exemplos públicos ou fixtures.

## 5. Dados públicos e dados restritos

### Públicos

- município, UF e código IBGE;
- indicação, fonte, versão e data;
- situação cadastral quando a publicação for autorizada;
- documentos marcados como públicos;
- geometrias e metadados de fonte;
- indicadores agregados.

### Restritos

- identidade e vínculo institucional do usuário;
- documentos de uso restrito;
- CPF, contatos e atos de designação;
- pareceres, notas internas e justificativas não publicadas;
- logs de segurança e trilhas de auditoria;
- chaves de armazenamento e URLs privadas.
