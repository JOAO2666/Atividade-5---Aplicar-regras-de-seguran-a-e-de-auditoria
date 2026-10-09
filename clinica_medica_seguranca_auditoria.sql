-- ==============================================================================
-- SENAI - CURSO TECNICO EM DESENVOLVIMENTO DE SISTEMAS / BANCO DE DADOS (UC13)
-- Atividade 5: Aplicar Regras de Seguranca e de Auditoria
-- Projeto: Clinica Medica (clinica_medica)
-- Estudante: Joao Emanuel Almeida Ramos
-- ==============================================================================
-- Descricao:
-- 1. Criacao de Login (nivel de servidor) e Usuario (nivel de banco de dados).
-- 2. Concessao de privilegios DCL: Consulta (SELECT) e Inclusao (INSERT).
-- 3. Restricao estrita de privilegios (sem permissao de UPDATE e DELETE).
-- 4. Validacao de permissoes via stored procedure de sistema sp_helprotect.
-- 5. Criacao e habilitacao do SQL Server Audit (Auditoria de Servidor).
-- 6. Criacao e habilitacao da Database Audit Specification (Auditoria de Banco).
-- 7. Execucao de testes de auditoria e violacao de acesso.
-- 8. Consulta e leitura analitica dos logs de auditoria (sys.fn_get_audit_file).
-- ==============================================================================

-- ==============================================================================
-- PARTE 1: PREPARACAO DO AMBIENTE E BANCO DE DADOS
-- ==============================================================================
USE master;
GO

-- Criar a base clinica_medica se nao existir
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'clinica_medica')
BEGIN
    CREATE DATABASE clinica_medica;
    PRINT 'Banco de dados clinica_medica criado com sucesso.';
END
GO

USE clinica_medica;
GO

-- Garantir a existencia da tabela paciente
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'paciente' AND type = 'U')
BEGIN
    CREATE TABLE paciente (
        cpf varchar(14) PRIMARY KEY,
        nome_paciente varchar(40) NOT NULL,
        telefone varchar(14),
        numero_plano int,
        nome_plano varchar(20),
        tipo_plano varchar(10)
    );
    PRINT 'Tabela paciente criada com sucesso.';
END
GO

-- Garantir a existencia da tabela medico (para comparativo de tabelas nao auditadas)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'medico' AND type = 'U')
BEGIN
    CREATE TABLE medico (
        crm int PRIMARY KEY,
        nome_medico varchar(30) NOT NULL,
        especialidade varchar(20) NOT NULL
    );
    PRINT 'Tabela medico criada com sucesso.';
END
GO

-- Carga inicial de dados de teste (caso estejam vazias)
IF NOT EXISTS (SELECT 1 FROM paciente WHERE cpf = '012.345.678-90')
BEGIN
    INSERT INTO paciente VALUES ('012.345.678-90', 'Carlos Eduardo Silva', '(11)98765-4321', 102030, 'Sulmed', 'Especial');
    INSERT INTO paciente VALUES ('123.456.789-12', 'Mariana Souza Santos', '(11)97654-3210', 203040, 'Inovamed', 'Padrao');
    INSERT INTO paciente VALUES ('234.567.890-23', 'Renato Lima Pereira', '(11)96543-2109', 304050, 'Ultramed', 'Basico');
    PRINT 'Carga inicial de pacientes inserida com sucesso.';
END
GO

IF NOT EXISTS (SELECT 1 FROM medico WHERE crm = 102030)
BEGIN
    INSERT INTO medico VALUES (102030, 'Dr. Roberto Arruda', 'Cardiologia');
    INSERT INTO medico VALUES (203040, 'Dra. Camila Toledo', 'Dermatologia');
    PRINT 'Carga inicial de medicos inserida com sucesso.';
END
GO


-- ==============================================================================
-- PARTE 2: CONTROLE DE ACESSO - DCL (DATA CONTROL LANGUAGE)
-- ==============================================================================

USE master;
GO

-- 2.1 Criar o Login a nivel de servidor com senha segura
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'aluno')
BEGIN
    CREATE LOGIN aluno 
    WITH PASSWORD = N'Abc12345', 
         CHECK_EXPIRATION = OFF, 
         CHECK_POLICY = OFF;
    PRINT 'Login [aluno] criado com sucesso no servidor.';
END
ELSE
BEGIN
    PRINT 'Login [aluno] ja existente.';
END
GO

USE clinica_medica;
GO

-- 2.2 Criar o Usuario no banco clinica_medica associado ao Login aluno
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'usuario_consulta')
BEGIN
    CREATE USER usuario_consulta FOR LOGIN aluno;
    PRINT 'Usuario [usuario_consulta] criado no banco clinica_medica.';
END
ELSE
BEGIN
    PRINT 'Usuario [usuario_consulta] ja existente no banco clinica_medica.';
END
GO

-- 2.3 Conceder Permissao de Consulta (SELECT - Somente Leitura)
GRANT SELECT ON dbo.paciente TO usuario_consulta;
GRANT SELECT ON dbo.medico TO usuario_consulta;
PRINT 'Permissao SELECT concedida para [usuario_consulta].';
GO

-- 2.4 Conceder Permissao de Inclusao de Dados (INSERT)
GRANT INSERT ON dbo.paciente TO usuario_consulta;
PRINT 'Permissao INSERT concedida para [usuario_consulta].';
GO

-- 2.5 Restricao de Acesso: Garantir que o usuario NAO possa alterar ou excluir registros
-- Por padrao, no SQL Server permissoes nao concedidas sao negadas. 
-- Para reforco explicito (Principio do Menor Privilegio / Restricao Rigorosa):
DENY UPDATE, DELETE ON dbo.paciente TO usuario_consulta;
PRINT 'Restricao aplicada: Permissoes UPDATE e DELETE negadas explicitamente para [usuario_consulta].';
GO

-- 2.6 Verificacao de Permissoes Concedidas e Negadas
PRINT '>>> Consultando permissoes ativas do usuario_consulta via sp_helprotect:';
EXEC sp_helprotect @username = 'usuario_consulta';
GO


-- ==============================================================================
-- PARTE 3: CRIACAO E ATIVACAO DO SQL SERVER AUDIT (AUDITORIA DE LOG)
-- ==============================================================================

USE master;
GO

-- 3.1 Criar a Auditoria de Servidor (Server Audit)
-- Destino: Arquivo fisico em C:\AuditoriaExemplo\
-- Queue Delay: 1000 milissegundos
-- Em caso de falha: Continuar (ON_FAILURE = CONTINUE)
-- Limite de Arquivo: Maximo de 100 MB, arquivos de substituicao ilimitados
IF EXISTS (SELECT * FROM sys.server_audits WHERE name = 'Audit_ClinicaMedica')
BEGIN
    ALTER SERVER AUDIT [Audit_ClinicaMedica] WITH (STATE = OFF);
    DROP SERVER AUDIT [Audit_ClinicaMedica];
    PRINT 'Auditoria antiga [Audit_ClinicaMedica] removida para recriacao.';
END
GO

CREATE SERVER AUDIT [Audit_ClinicaMedica]
TO FILE 
(
    FILEPATH = N'C:\AuditoriaExemplo\',
    MAXSIZE = 100 MB,
    MAX_ROLLOVER_FILES = UNLIMITED,
    RESERVE_DISK_SPACE = OFF
)
WITH
(
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);
GO

-- 3.2 Habilitar a Auditoria de Servidor
ALTER SERVER AUDIT [Audit_ClinicaMedica] WITH (STATE = ON);
PRINT 'Auditoria de Servidor [Audit_ClinicaMedica] criada e HABILITADA com exito.';
GO

-- 3.3 Criar a Especificacao de Auditoria de Banco de Dados (Database Audit Specification)
-- Foco: Registrar toda vez que o usuario [usuario_consulta] realizar consulta (SELECT)
-- na tabela dbo.paciente do banco clinica_medica
USE clinica_medica;
GO

IF EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = 'DatabaseAuditSpecification_ClinicaMedica')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION [DatabaseAuditSpecification_ClinicaMedica] WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION [DatabaseAuditSpecification_ClinicaMedica];
    PRINT 'Especificacao de auditoria antiga removida para recriacao.';
END
GO

CREATE DATABASE AUDIT SPECIFICATION [DatabaseAuditSpecification_ClinicaMedica]
FOR SERVER AUDIT [Audit_ClinicaMedica]
ADD (SELECT ON OBJECT::dbo.paciente BY usuario_consulta)
WITH (STATE = ON);
GO

PRINT 'Especificacao de Auditoria [DatabaseAuditSpecification_ClinicaMedica] criada e HABILITADA com exito.';
GO


-- ==============================================================================
-- PARTE 4: TESTES PRATICOS DE SEGURANCA E GERACAO DE EVENTOS DE AUDITORIA
-- ==============================================================================
-- Nota: Para testar no SSMS, voce pode autenticar diretamente com o Login [aluno]
-- ou executar os testes abaixo simulando o contexto do usuario_consulta / aluno.

USE clinica_medica;
GO

PRINT '>>> Iniciando simulacao de operacoes com o usuario [usuario_consulta]...';
EXECUTE AS USER = 'usuario_consulta';
GO

-- 4.1 TESTE DE CONSULTA 1 (Auditado): SELECT geral na tabela paciente
SELECT * FROM dbo.paciente;
GO

-- 4.2 TESTE DE CONSULTA 2 (Auditado): SELECT com filtro condicional
SELECT nome_paciente, telefone, nome_plano 
FROM dbo.paciente 
WHERE tipo_plano = 'Basico';
GO

-- 4.3 TESTE DE INCLUSAO (Permitido por DCL): Inserir novo paciente
INSERT INTO dbo.paciente (cpf, nome_paciente, telefone, numero_plano, nome_plano, tipo_plano)
VALUES ('567.890.123-45', 'Rogerio Ramos', '(11)97890-1234', 678901, 'Inovamed', 'Basico');
GO

-- 4.4 TESTE DE CONSULTA 3 (Auditado): Verificar novo paciente inserido
SELECT * FROM dbo.paciente WHERE cpf = '567.890.123-45';
GO

-- 4.5 TESTE DE COMPARACAO DE AUDITORIA: SELECT na tabela medico
-- O usuario tem permissao de leitura, mas esta tabela NAO esta configurada na auditoria.
-- O comando executara com sucesso, porem NAO sera gerado log em Audit_ClinicaMedica.
SELECT * FROM dbo.medico;
GO

-- 4.6 TESTE DE RESTRICAO DE SEGURANCA 1: Tentativa de EXCLUSAO (Bloqueado)
-- Deve retornar Erro 229 (Permissao Negada / Denied)
BEGIN TRY
    DELETE FROM dbo.paciente WHERE cpf = '567.890.123-45';
    PRINT 'FALHA DE SEGURANCA: Exclusao nao deveria ter sido permitida!';
END TRY
BEGIN CATCH
    PRINT 'SUCESSO NO CONTROLE DE ACESSO: Exclusao bloqueada com sucesso.';
    PRINT 'Mensagem de Erro: ' + ERROR_MESSAGE();
END CATCH
GO

-- 4.7 TESTE DE RESTRICAO DE SEGURANCA 2: Tentativa de ALTERACAO (Bloqueado)
-- Deve retornar Erro 229 (Permissao Negada / Denied)
BEGIN TRY
    UPDATE dbo.paciente SET nome_paciente = 'Rogerio Ramos Modificado' WHERE cpf = '567.890.123-45';
    PRINT 'FALHA DE SEGURANCA: Alteracao nao deveria ter sido permitida!';
END TRY
BEGIN CATCH
    PRINT 'SUCESSO NO CONTROLE DE ACESSO: Alteracao bloqueada com sucesso.';
    PRINT 'Mensagem de Erro: ' + ERROR_MESSAGE();
END CATCH
GO

-- Reverter o contexto de simulacao para o administrador (sa / dbo)
REVERT;
GO
PRINT '>>> Contexto de seguranca revertido para o administrador.';
GO


-- ==============================================================================
-- PARTE 5: CONSULTA E EXTRACAO DOS LOGS DE AUDITORIA
-- ==============================================================================
-- O SQL Server armazena os eventos em arquivos binarios com extensao .sqlaudit
-- na pasta configurada (C:\AuditoriaExemplo\).
-- Utilizamos a funcao de tabela sys.fn_get_audit_file para ler os eventos registrados.

USE master;
GO

PRINT '>>> Exibindo registros capturados pelo SQL Server Audit:';
SELECT 
    event_time AS [Data_Hora_UTC],
    action_id AS [Acao],
    succeeded AS [Exito],
    session_server_principal_name AS [Login_Servidor],
    server_principal_name AS [Usuario_Conectado],
    database_principal_name AS [Usuario_Banco],
    database_name AS [Banco_Dados],
    schema_name AS [Esquema],
    object_name AS [Objeto_Tabela],
    statement AS [Instrucao_SQL]
FROM sys.fn_get_audit_file('C:\AuditoriaExemplo\*', DEFAULT, DEFAULT)
ORDER BY event_time DESC;
GO


-- ==============================================================================
-- PARTE 6: PROCEDIMENTO DE DESATIVACAO E LIMPEZA (OPCIONAL / MANUTENCAO)
-- ==============================================================================
/*
-- 1. Desabilitar e remover a especificacao de auditoria do banco
USE clinica_medica;
GO
ALTER DATABASE AUDIT SPECIFICATION [DatabaseAuditSpecification_ClinicaMedica] WITH (STATE = OFF);
DROP DATABASE AUDIT SPECIFICATION [DatabaseAuditSpecification_ClinicaMedica];
GO

-- 2. Desabilitar e remover a auditoria do servidor
USE master;
GO
ALTER SERVER AUDIT [Audit_ClinicaMedica] WITH (STATE = OFF);
DROP SERVER AUDIT [Audit_ClinicaMedica];
GO

-- 3. Remover usuario e login
USE clinica_medica;
GO
DROP USER IF EXISTS usuario_consulta;
GO

USE master;
GO
DROP LOGIN IF EXISTS aluno;
GO
*/
