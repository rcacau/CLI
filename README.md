# Agenda CLI

Aplicação de linha de comando (CLI) em Elixir para gerenciamento de contatos pessoais.

O projeto foi desenvolvido com foco em Programação Funcional, usando composição de funções, recursão no loop interativo, pattern matching no dispatch de comandos e persistência local em JSON.

## Objetivo

Permitir o cadastro, consulta, edição, remoção e busca de contatos diretamente no terminal, com dados persistidos no arquivo `contacts.json`.

## Tecnologias e requisitos

- Elixir
- Mix
- Jason (serialização JSON)

## Como executar

1. Instalar dependências:

```bash
mix deps.get
```

2. Iniciar a aplicação:

```bash
mix run -e "AgendaCli.main([])"
```

Observação: este comando inicia o prompt interativo da agenda (`> `) no terminal.

## Como testar automaticamente

```bash
mix test
```

## Estrutura do projeto

- `lib/agenda_cli.ex`
Responsável pelo ponto de entrada da CLI, loop recursivo, parsing manual de comandos e dispatch com pattern matching.

- `lib/agenda_cli/contacts.ex`
Contém as regras de negócio dos contatos: `add`, `edit`, `del`, `show`, `list`, `search`, além de validações.

- `lib/agenda_cli/store.ex`
Responsável pela persistência JSON: `load/0` e `save/1`, criação automática de arquivo e tratamento de JSON inválido/vazio.

- `lib/agenda_cli/application.ex`
Configura inicialização da aplicação via Mix.

## Modelo de contato

Cada contato é salvo no formato:

```elixir
%{
  id: 1713531600000,
  name: "Ana Lima",
  company: "Acme Ltda",
  phone: "85912345678",
  email: "ana@email.com"
}
```

Campos:

- `id` (integer): gerado automaticamente com timestamp em milissegundos.
- `name` (string)
- `company` (string)
- `phone` (string)
- `email` (string)

## Comandos disponíveis

Todos os comandos abaixo devem ser digitados dentro do prompt da aplicação (`> `).

### 1. `add`

Adiciona um contato.

```text
add --name Ana Lima --company Acme --phone 85912345678 --email ana@email.com
```

Regras:

- Gera `id` automaticamente.
- Exige todos os campos: `--name`, `--company`, `--phone`, `--email`.
- Valida email.
- Não aceita telefone vazio.

### 2. `edit <id>`

Edita apenas os campos informados.

```text
edit 123 --phone 85999999999
edit 123 --name Ana Silva --company Acme LTDA
```

Regras:

- Mantém campos não informados.
- Reaplica validação de email/telefone quando esses campos forem enviados.

### 3. `del <id>`

Remove contato pelo id.

```text
del 123
```

### 4. `show <id>`

Exibe um único contato formatado.

```text
show 123
```

### 5. `list`

Lista todos os contatos.

```text
list
```

### 6. `search`

Busca parcial e case-insensitive.

```text
search --name ana
search --phone 85
search --email gmail
```

Regras:

- Aceita apenas uma flag por busca.
- Parsing feito por `parse_search/1`.
- Retornos esperados internamente:
  - `{:name, valor}`
  - `{:phone, valor}`
  - `{:email, valor}`

### 7. `exit`

Encerra a aplicação.

```text
exit
```

## Exemplo de sessão completa

```text
> add --name Ana Lima --company Acme Ltda --phone 85912345678 --email ana@email.com
Contato adicionado.

> list
[1778358363965]
Nome: Ana Lima
Empresa: Acme Ltda
Telefone: 85912345678
Email: ana@email.com

> search --name ana
[1778358363965]
Nome: Ana Lima
Empresa: Acme Ltda
Telefone: 85912345678
Email: ana@email.com

> exit
Até mais!
```

## Persistência JSON

Arquivo usado: `contacts.json`.

Comportamento:

- Carrega os contatos ao iniciar (`AgendaCli.Store.load/0`).
- Salva automaticamente após `add`, `edit` e `del` (`AgendaCli.Store.save/1`).
- Cria `contacts.json` com `[]` se não existir.
- Se o arquivo estiver vazio/corrompido, a aplicação não quebra: inicia com lista vazia e exibe aviso.

## Tratamento de erros

A aplicação trata entradas inválidas sem crashar, com mensagens amigáveis para:

- comando inválido
- id inválido ou inexistente
- email inválido
- telefone vazio
- flags incorretas
- parâmetros ausentes
- busca malformada
- JSON inválido

## Conceitos de Programação Funcional aplicados

- Recursão no loop interativo (`loop/1`) em vez de loop imperativo.
- Pattern matching no dispatch dos comandos (`handle_command/2` em múltiplas cláusulas).
- Pipe operator (`|>`) para composição de processamento e transformação de dados.
- Funções pequenas e módulos separados por responsabilidade.

## Arquivos ignorados no Git

No `.gitignore`:

- `/_build/`
- `/deps/`
- `contacts.json`

## Observações finais

- O projeto foi mantido simples, modular e explicável em apresentação oral.
- Não usa bibliotecas externas de parser CLI.
- Parsing de comandos feito manualmente com `String.split`, `Enum` e funções auxiliares.
