# Publicação de teste na VPS Hostinger

## Preparação

1. Criar um banco MySQL separado, por exemplo `cnm_risco_test`.
2. Criar um usuário exclusivo da aplicação, sem reutilizar o usuário do painel.
3. Importar `database/schema.sql` e, somente para demonstração, `database/seed_demo.sql`.
4. Configurar o arquivo de ambiente no servidor. Nunca publicar `.env` no GitHub.
5. Criar uma pasta privada para os uploads e impedir acesso direto por URL.
6. Publicar o frontend em um subdomínio de homologação, como `cadastro-teste.seudominio.gov.br`.

## Segurança mínima

- usar HTTPS;
- limitar tamanho e quantidade de uploads;
- validar extensão e MIME no servidor;
- calcular SHA-256 dos arquivos;
- verificar arquivos compactados antes de extrair;
- manter backup do banco e dos uploads;
- registrar auditoria de mudança de situação;
- usar credenciais diferentes para desenvolvimento, homologação e produção.

## Ordem recomendada

O protótipo estático pode ser publicado imediatamente. A API e o upload real devem ser ativados depois da criação do banco de testes, da configuração de armazenamento e da definição do fluxo de autenticação gov.br.
