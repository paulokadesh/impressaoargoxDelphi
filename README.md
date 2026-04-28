# EtiquetaML — Utilitário ZPL (Argox)

Aplicação VCL (Delphi) para **carregar um arquivo ZPL (`.txt/.zpl`)**, **normalizar para 10cm x 5cm** e:

- **Salvar** uma versão “para preview” (limitada) já normalizada
- **Gerar preview em PDF** via Labelary (online)
- **Enviar RAW** para a impressora do Windows (útil para impressoras em modo ZPL)

> Importante: se a sua impressora estiver em **PPLA/PPLB** (ex.: “Argox OS-2140 PPLA”), **ZPL não imprime**. Nesse caso, você precisa de **emulação ZPL**/driver ZPL ou converter o layout para PPLA.

## Funcionalidades

- **Selecionar arquivo**: abre um `.txt`/`.zpl` contendo ZPL.
- **Selecionar impressora**: lista as impressoras instaladas no Windows.
- **Forçar tamanho 10cm x 5cm**: injeta em cada `^XA...^XZ`:
  - `^PW` e `^LL` (conforme o DPI informado)
  - `^FWN` (orientação normal, evita herança de rotação da impressora)
- **Salvar ZPL**: salva um arquivo em **UTF-8 (sem BOM)** já normalizado e **limitado para preview**:
  - mantém só as **primeiras 50** etiquetas
  - força `^PQ1` (evita estourar limites do Labelary)
- **Preview (PDF)**: envia o ZPL para a API do Labelary e baixa um **PDF**.
- **Teste ZPL**: envia uma etiqueta simples (com `^CI28`) para validar se a impressora aceita ZPL.
- **Imprimir**: envia o ZPL para a impressora via **spooler do Windows** usando `OpenPrinter/WritePrinter` (RAW).

## Como compilar

- Abra o projeto no Delphi e compile normalmente (VCL / Win32).

Arquivos principais:
- `EtiquetaML.pas` / `EtiquetaML.dfm`: Form principal e lógica.
- `ProjEtiquetaML.dpr`: inicialização do projeto.

## Como usar

1. Selecione o arquivo ZPL em **Arquivo**.
2. Selecione a impressora em **Impressora**.
3. Ajuste o **DPI** (tipicamente `203` ou `300`).
4. Use:
   - **Salvar ZPL** para abrir no `labelary.com/viewer.html` (preview manual), ou
   - **Preview (PDF)** para gerar e abrir um PDF automaticamente, ou
   - **Imprimir** para enviar RAW ao driver.

## Dicas para o Labelary (viewer)

No `labelary.com/viewer.html`:
- **Print Density**: `8 dpmm (203 dpi)` ou `12 dpmm (300 dpi)`
- **Label Size**: `100 x 50 mm`

## Limitações / Notas

- **Impressora em PPLA**: ZPL não será interpretado. É comum “piscar” e não imprimir.
- **Preview via Labelary**: requer internet e tem limites de quantidade (por isso o app limita em 50 etiquetas no preview).

