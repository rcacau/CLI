# Agenda CLI

Aplica??o de linha de comando (CLI) em Elixir para gerenciamento de contatos pessoais.

O projeto foi desenvolvido com foco em Programa??o Funcional, usando composi??o de fun??es, recurs?o no loop interativo, pattern matching no dispatch de comandos e persist?ncia local em JSON.

## Objetivo

Permitir o cadastro, consulta, edi??o, remo??o e busca de contatos diretamente no terminal, com dados persistidos no arquivo `contacts.json`.

## Tecnologias e requisitos

- Elixir
- Mix
- Jason (serializa??o JSON)

## Como executar

1. Instalar depend?ncias:

```bash
mix deps.get
```

2. Iniciar a aplica??o:

```bash
mix run -e "AgendaCli.main([])"
```

Observa??o: este comando inicia o prompt interativo da agenda (`> `) no terminal.

## Como testar automaticamente

```bash
mix test
```

## Estrutura do projeto

- `lib/agenda_cli.ex`
Respons?vel pelo ponto de entrada da CLI, loop recursivo, parsing manual de comandos e dispatch com pattern matching.

- `lib/agenda_cli/contacts.ex`
Cont?m as regras de neg?cio dos contatos: `add`, `edit`, `del`, `show`, `list`, `search`, al?m de valida??es.

- `lib/agenda_cli/store.ex`
Respons?vel pela persist?ncia JSON: `load/0` e `save/1`, cria??o autom?tica de arquivo e tratamento de JSON inv?lido/vazio.

- `lib/agenda_cli/application.ex`
Configura inicializa??o da aplica??o via Mix.

## Modelo de contato

Cada contato ? salvo no formato:

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

## Comandos dispon?veis

Todos os comandos abaixo devem ser digitados dentro do prompt da aplica??o (`> `).

### 1. `add`

Adiciona um contato.

```text
add --name Ana Lima --company Acme --phone 85912345678 --email ana@email.com
```

Regras:

- Gera `id` automaticamente.
- Exige todos os campos: `--name`, `--company`, `--phone`, `--email`.
- Valida email.
- N?o aceita telefone vazio.

### 2. `edit <id>`

Edita apenas os campos informados.

```text
edit 123 --phone 85999999999
edit 123 --name Ana Silva --company Acme LTDA
```

Regras:

- Mant?m campos n?o informados.
- Reaplica valida??o de email/telefone quando esses campos forem enviados.

### 3. `del <id>`

Remove contato pelo id.

```text
del 123
```

### 4. `show <id>`

Exibe um ?nico contato formatado.

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

Encerra a aplica??o.

```text
exit
```

## Exemplo de sess?o completa

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
Ate mais!
```

## Persist?ncia JSON

Arquivo usado: `contacts.json`.

Comportamento:

- Carrega os contatos ao iniciar (`AgendaCli.Store.load/0`).
- Salva automaticamente ap?s `add`, `edit` e `del` (`AgendaCli.Store.save/1`).
- Cria `contacts.json` com `[]` se n?o existir.
- Se o arquivo estiver vazio/corrompido, a aplica??o n?o quebra: inicia com lista vazia e exibe aviso.

## Tratamento de erros

A aplica??o trata entradas inv?lidas sem crashar, com mensagens amig?veis para:

- comando inv?lido
- id inv?lido ou inexistente
- email inv?lido
- telefone vazio
- flags incorretas
- par?metros ausentes
- busca malformada
- JSON inv?lido

## Conceitos de Programa??o Funcional aplicados

- Recurs?o no loop interativo (`loop/1`) em vez de loop imperativo.
- Pattern matching no dispatch dos comandos (`handle_command/2` em m?ltiplas cl?usulas).
- Pipe operator (`|>`) para composi??o de processamento e transforma??o de dados.
- Fun??es pequenas e m?dulos separados por responsabilidade.

## Arquivos ignorados no Git

No `.gitignore`:

- `/_build/`
- `/deps/`
- `contacts.json`

## Observa??es finais

- O projeto foi mantido simples, modular e explic?vel em apresenta??o oral.
- N?o usa bibliotecas externas de parser CLI.
- Parsing de comandos feito manualmente com `String.split`, `Enum` e fun??es auxiliares.
