# Atividade 5 - Aplicar Regras de Segurança e de Auditoria
> **Unidade Curricular:** UC13 - Banco de Dados  
> **Instituição:** SENAI - Desenvolvimento de Sistemas  
> **Estudante:** João Emanuel Almeida Ramos  
> **Repositório Oficial:** [Atividade 5 - Aplicar regras de segurança e de auditoria](https://github.com/JOAO2666/Atividade-5---Aplicar-regras-de-seguran-a-e-de-auditoria)  
> **Projeto:** Banco de Dados da Clínica Médica (`clinica_medica`)  

---

## 📌 Visão Geral do Projeto

Nesta quinta atividade prática da unidade curricular de Banco de Dados, implementamos as camadas de **Controle de Acesso (DCL - Data Control Language)** e **Auditoria Contínua de Logs (SQL Server Audit)** sobre o banco de dados da **Clínica Médica**.

O objetivo central foi garantir a confidencialidade, integridade e rastreabilidade estrita de dados médicos sensíveis, atendendo aos princípios fundamentais da Segurança da Informação e aos requisitos da **LGPD (Lei Geral de Proteção de Dados - Lei nº 13.709/2018)**.

---

## 🎯 Requisitos e Entregáveis Atendidos

1. **Criação de Credenciais de Acesso:**
   - Criação do **Login de Servidor** `aluno` com senha forte (`Abc12345`).
   - Mapeamento para o **Usuário de Banco de Dados** `usuario_consulta` no catálogo `clinica_medica`.
2. **Restrição e Concessão de Privilégios (DCL):**
   - Concessão de acesso para **Consulta (somente leitura - `SELECT`)** nas tabelas pertinentes.
   - Concessão de permissão para **Inclusão de novos dados (`INSERT`)** na tabela `paciente`.
   - Restrição estrita de acesso: Bloqueio formal de alterações (`UPDATE`) e exclusões (`DELETE`) via `DENY`.
   - Verificação das regras ativas via stored procedure de sistema `sp_helprotect`.
3. **Configuração do SQL Server Audit (Auditoria de Log):**
   - Criação e ativação da **Auditoria de Servidor (*Server Audit*)** direcionando para arquivo físico no disco em `C:\AuditoriaExemplo\` (atraso de fila de 1000ms, continuação em caso de falha, arquivos ilimitados até 100MB).
   - Criação e ativação da **Especificação de Auditoria de Banco de Dados (*Database Audit Specification*)** voltada a auditar todas as instruções `SELECT` executadas pelo usuário `usuario_consulta` na tabela `dbo.paciente`.
4. **Validação Prática e Testes de Integridade:**
   - Execução de testes autenticado como `usuario_consulta`, comprovando o sucesso de consultas e inclusões.
   - Tentativas de `DELETE` e `UPDATE` bloqueadas com erro de permissão negada (*Error 229: Permission Denied*).
   - Validação da precisão da auditoria (consultas na tabela `medico` não auditadas foram omitidas dos logs).
5. **Extração e Exportação de Logs:**
   - Consulta analítica via função de sistema `sys.fn_get_audit_file`.
   - Exportação estruturada dos logs para o arquivo `auditoria.csv` conforme o guia `BancoDados_Ativ_AuditoriaCSV.pdf`.
6. **Relatórios Acadêmicos:**
   - Relatório técnico completo em Markdown (`Atividade5_Resolucao_ClinicaMedica.md`).
   - Documento acadêmico diagramado para entrega (`Atividade5_Resolucao_ClinicaMedica.docx`).

---

## 📂 Estrutura de Arquivos do Repositório

```text
├── Atividade5_Resolucao_ClinicaMedica.md   # Relatório técnico completo e fundamentado
├── Atividade5_Resolucao_ClinicaMedica.docx # Documento Word diagramado no padrão SENAI
├── clinica_medica_seguranca_auditoria.sql  # Script T-SQL consolidado e executável ponta a ponta
├── ca_permissao.sql                        # Script DCL simplificado da atividade
├── auditoria.csv                           # Arquivo exportado do Visualizador de Log do SSMS
├── BancoDados_auditoria.pdf                # Guia instrucional do passo a passo no SSMS
├── BancoDados_Ativ_AuditoriaCSV.pdf        # Guia instrucional de exportação para CSV
└── README.md                               # Documentação e guia do repositório
```

---

## 🚀 Como Executar o Projeto no SQL Server

### 1. Criar o Diretório de Auditoria no Windows
Certifique-se de que a pasta de destino exista no disco `C:\`:
```powershell
New-Item -ItemType Directory -Path "C:\AuditoriaExemplo" -Force
```

### 2. Executar o Script Principal
Abra o arquivo [`clinica_medica_seguranca_auditoria.sql`](clinica_medica_seguranca_auditoria.sql) no **SQL Server Management Studio (SSMS)** ou execute via `sqlcmd`:
1. **Parte 1:** Cria e popula as tabelas da clínica médica.
2. **Parte 2:** Cria o login `aluno`, usuário `usuario_consulta`, aplica os comandos `GRANT` e `DENY` e valida com `sp_helprotect`.
3. **Parte 3:** Cria e habilita a auditoria de servidor `Audit_ClinicaMedica` e a especificação de banco `DatabaseAuditSpecification_ClinicaMedica`.
4. **Parte 4:** Executa a bateria de testes de consulta, inserção e tentativas de exclusão/alteração bloqueadas.
5. **Parte 5:** Realiza a leitura dos logs através de `sys.fn_get_audit_file`.

### 3. Visualizar e Exportar os Logs no SSMS
1. No Pesquisador de Objetos, navegue até **Segurança > Auditorias**.
2. Clique com o botão direito sobre `Audit_ClinicaMedica` e selecione **Exibir Logs de Auditoria**.
3. Na janela do visualizador, clique em **Exportar**, selecione o formato **CSV (*.csv)** e salve como `auditoria.csv`.

---

## 📊 Matriz de Permissões (DCL)

| Entidade | Objeto | Ação | Permissão | Status / Comportamento |
| :--- | :--- | :--- | :--- | :--- |
| `usuario_consulta` | `dbo.paciente` | `SELECT` | **GRANT** | Autorizado (e registrado na auditoria) |
| `usuario_consulta` | `dbo.paciente` | `INSERT` | **GRANT** | Autorizado (inclusão de novos pacientes) |
| `usuario_consulta` | `dbo.paciente` | `UPDATE` | **DENY** | **Bloqueado** (Erro 229 - Permissão Negada) |
| `usuario_consulta` | `dbo.paciente` | `DELETE` | **DENY** | **Bloqueado** (Erro 229 - Permissão Negada) |
| `usuario_consulta` | `dbo.medico` | `SELECT` | **GRANT** | Autorizado (sem registro na auditoria) |

---

## 📋 Amostra dos Logs de Auditoria Registrados (`auditoria.csv`)

| Data | Hora | Servidor | Ação | Objeto | Usuário | Instrução Executada | Êxito |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 09/10/2026 | 17:30:15 | DESKTOP-SENAI\SQLEXPRESS | AUDIT SESSION CHANGED | Audit_ClinicaMedica | sa | `ALTER SERVER AUDIT [Audit_ClinicaMedica] WITH (STATE = ON)` | True |
| 09/10/2026 | 17:31:02 | DESKTOP-SENAI\SQLEXPRESS | AUDIT SPECIFICATION CHANGED | DatabaseAuditSpecification_ClinicaMedica | sa | `ALTER DATABASE AUDIT SPECIFICATION [...] WITH (STATE = ON)` | True |
| 09/10/2026 | 17:32:10 | DESKTOP-SENAI\SQLEXPRESS | SELECT | paciente | usuario_consulta | `SELECT * FROM dbo.paciente;` | True |
| 09/10/2026 | 17:32:45 | DESKTOP-SENAI\SQLEXPRESS | SELECT | paciente | usuario_consulta | `SELECT nome_paciente, telefone, nome_plano FROM dbo.paciente WHERE tipo_plano = 'Basico';` | True |
| 09/10/2026 | 17:33:20 | DESKTOP-SENAI\SQLEXPRESS | SELECT | paciente | usuario_consulta | `SELECT * FROM dbo.paciente WHERE cpf = '567.890.123-45';` | True |
| 09/10/2026 | 17:34:05 | DESKTOP-SENAI\SQLEXPRESS | SELECT | paciente | usuario_consulta | `SELECT * FROM paciente;` | True |

---

## 📚 Referências e Materiais de Apoio
* [Vídeo SENAI Play - Segurança e auditoria em banco de dados](https://www.youtube.com/watch?v=g4QP6sFZwmk)
* [Documentação Oficial Microsoft Learn - SQL Server Audit](https://learn.microsoft.com/pt-br/sql/relational-databases/security/auditing/sql-server-audit-database-engine)
* [Documentação Oficial Microsoft Learn - sys.fn_get_audit_file](https://learn.microsoft.com/pt-br/sql/relational-databases/system-functions/sys-fn-get-audit-file-transact-sql)
* Lei Federal nº 13.709/2018 (Lei Geral de Proteção de Dados Pessoais - LGPD)
