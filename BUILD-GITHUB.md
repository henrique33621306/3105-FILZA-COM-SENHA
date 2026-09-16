# Build automático da IPA

O projeto está configurado para compilar no GitHub Actions usando `macos-15`.

## Antes de enviar

1. Coloque uma cópia legal e sem assinatura da IPA-base na raiz do projeto.
2. Renomeie o arquivo para `base-unsigned.ipa`.
3. Confirme que a IPA contém `Payload/*.app/Info.plist` e usa o bundle esperado pelo script.
4. Envie toda a pasta para um repositório GitHub. Se a IPA não puder ser redistribuída, use um repositório privado e respeite a licença do aplicativo-base.

## Resultado

Em cada push para `main` ou `master`, ou ao executar manualmente **Build unsigned IPA**:

1. o runner instala o Theos;
2. compila `FilzaApplySandboxExt.dylib`, incluindo a tela de login;
3. monta `3105-unsigned.ipa` a partir de `base-unsigned.ipa`;
4. valida o ZIP e gera o SHA-256;
5. publica ambos em **Actions → Artifacts → 3105-unsigned-ipa**.

A IPA gerada não é assinada. Instalação e assinatura ficam fora deste workflow.
