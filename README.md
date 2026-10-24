# Localizações — Atividade 1

Aplicativo Flutter (Android) que coleta a localização do aparelho a cada
~20 segundos, salva cada posição em SQLite e apresenta o histórico em lista
e em um mapa interativo.

## Como executar

```bash
flutter pub get
flutter run            # com um aparelho ou emulador Android conectado
flutter analyze        # sem problemas apontados
flutter test           # testes do modelo e do item de localização
```

## Funcionalidades

- **Coleta** (tela inicial): verifica o GPS e a permissão de localização,
  orienta o usuário quando a permissão é negada (inclusive de forma
  permanente, com atalho para as configurações) e assina um stream de
  posições com alta precisão e intervalo solicitado de 20 s. No Android a
  leitura roda em um serviço em primeiro plano com notificação visível, então
  continua com o app minimizado ou em outras telas. Os botões de iniciar e
  parar são habilitados conforme o estado, e as gravações são enfileiradas
  para nunca se sobreporem.
- **Histórico**: últimas 100 localizações (mais recente primeiro), com data e
  hora locais, latitude/longitude com 6 casas e precisão com 1 casa. Atualiza
  sem interromper a coleta (botão ou gesto de puxar) e permite limpar todo o
  histórico após confirmação.
- **Mapa**: últimas 100 posições sobre o OpenStreetMap, a mais recente em
  vermelho, enquadramento automático ao carregar, botão para reenquadrar e
  botão para atualizar. Tocar em um marcador mostra seus detalhes.

## Estrutura

```
lib/
├── main.dart, app.dart
└── features/localizacoes/
    ├── models/localizacao.dart                  # registro tipado + conversão de/para mapa
    ├── data/database/banco_localizacoes.dart    # abertura do banco e criação da tabela
    ├── data/repositories/repositorio_localizacoes.dart  # inserir, consultar, excluir todos
    ├── services/servico_localizacao.dart        # GPS, permissões e stream de posições
    ├── services/cache_mapa.dart                 # cache local das imagens do mapa
    └── presentation/
        ├── screens/  tela_coleta, tela_localizacoes, tela_mapa
        └── widgets/  item_localizacao, mapa_localizacoes, aviso_estado
```

`aviso_estado.dart` é um arquivo adicional: o widget de mensagem de erro e de
lista vazia compartilhado pelas telas de histórico e de mapa.

## Persistência

Banco `localizacoes.db`, tabela `localizacoes` (`id`, `latitude`,
`longitude`, `precisao` em metros, `instante` em UTC no formato ISO 8601).
O limite de 100 vale apenas para as consultas; a limpeza executa
`DELETE FROM localizacoes`, preservando a tabela e o arquivo.
O `.gitignore` impede que arquivos `.db` com coordenadas pessoais sejam
versionados.

## Mapa e uso do OpenStreetMap

As imagens vêm de `tile.openstreetmap.org`, com a atribuição
"© OpenStreetMap contributors" sempre visível (o toque abre a página de
direitos autorais) e um User-Agent com o identificador do app. As imagens são
guardadas em `cache_mapa/`, na pasta de cache privada do aplicativo, e
reaproveitadas conforme os cabeçalhos HTTP do servidor, como pede a
[política de uso](https://operations.osmfoundation.org/policies/tiles/).
Para uso além de um trabalho acadêmico, troque por um provedor comercial.

## Ícone

A imagem original está em `assets/icons/localizacoes.png`. O Android usa o
ícone adaptativo `mipmap-anydpi-v26/ic_localizacoes.xml` (fundo
`@color/icone_localizacoes_fundo` + `drawable-nodpi/icone_localizacoes.png`)
e, em versões anteriores ao Android 8, os PNGs `mipmap-*/ic_localizacoes.png`.
Após instalar, confira o ícone na tela inicial e na lista de aplicativos.

## Plataforma

O projeto foi criado somente para Android. Para iOS seria preciso adicionar
`NSLocationWhenInUseUsageDescription`/`NSLocationAlwaysAndWhenInUseUsageDescription`
e o modo de segundo plano `location` no `Info.plist`, usar `AppleSettings`
no serviço de localização e gerar o ícone no `Assets.xcassets`.
