-- ==============================================================================
-- SENAI - Seguranca da Informacao - Controle de Acesso (DCL) e Testes DML
-- Arquivo: ca_permissao.sql
-- Base de Dados: clinica_medica
-- ==============================================================================

-- 1. Criacao do Login a nivel de servidor
CREATE LOGIN aluno WITH PASSWORD = 'Abc12345';
GO

-- 2. Contextualizacao na base da clinica medica
USE clinica_medica;
GO

-- 3. Criacao do Usuario de banco associado ao Login
CREATE USER usuario_consulta FOR LOGIN aluno;
GO

-- 4. Concessao de Permissoes (Somente Consulta e Inclusao de dados)
GRANT SELECT TO usuario_consulta;
GRANT INSERT TO usuario_consulta;
GO

-- 5. Restricao de Acesso (Nao permitir alteracao nem exclusao)
-- (No SQL Server, sem o GRANT de UPDATE/DELETE ou com DENY explicito)
DENY UPDATE, DELETE TO usuario_consulta;
GO

-- 6. Consultar permissoes concedidas/negadas utilizando a stored procedure sp_helprotect
EXEC clinica_medica.dbo.sp_helprotect @username = 'usuario_consulta';
GO


-- ==============================================================================
-- Teste de login com controle de acesso - comandos DML do SQL
-- ==============================================================================
-- (Executar conectado com o Login 'aluno' ou simulando a sessao)

USE clinica_medica;
GO

-- Consulta permitida (SELECT):
SELECT * FROM paciente;
GO

-- Inclusao permitida (INSERT):
INSERT INTO paciente VALUES('567.890.123-45','Rogerio Ramos','(11)97890-1234',678901,'Inovamed','Basico');
GO

-- Tentativa de exclusao bloqueada (DELETE restrito/negado):
-- O SGBD retornara erro de permissao negada (Erro 229)
-- DELETE FROM paciente WHERE cpf = '567.890.123-45';

-- Outra inclusao permitida:
INSERT INTO paciente VALUES('789.012.345-67','Abilio Sanches','(11)99012-3456',901234,'Ultramed','Padrao');
GO

SELECT * FROM paciente;
GO


-- ==============================================================================
-- Exclusao de usuario e login (Manutencao / Limpeza)
-- ==============================================================================
-- DROP USER usuario_consulta;
-- DROP LOGIN aluno;
