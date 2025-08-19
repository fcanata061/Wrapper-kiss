#!/bin/sh
# bootstrap-kiss.sh - Bootstrap do Package Manager KISS
# Cria estrutura, baixa repositórios, configura PATH e instala extras.

set -e

PREFIX="/usr/local"
KISS_REPO_DIR="/var/db/kiss/repo"
KISS_DB="/var/db/kiss/installed"
KISS_CACHE="/var/cache/kiss"
KISS_LOG="/var/log/kiss"
KISS_CONTRIB_DIR="/usr/share/kiss/contrib"
KISS_BIN="$PREFIX/bin/kiss"

msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m!!\033[0m %s\n" "$*" >&2; exit 1; }

# --- Criação de diretórios principais ---
setup_dirs() {
    msg "Criando diretórios de sistema..."
    mkdir -p "$KISS_REPO_DIR" "$KISS_DB" "$KISS_CACHE" "$KISS_LOG"
    mkdir -p /etc/kiss /etc/profile.d "$KISS_CONTRIB_DIR"
    mkdir -p /mnt/usr/kiss   # Overlay local do usuário
}

# --- Baixa e instala o binário kiss ---
install_kiss() {
    msg "Baixando e instalando o package manager KISS..."
    curl -sL https://raw.githubusercontent.com/kisslinux/kiss/master/kiss > "$KISS_BIN"
    chmod +x "$KISS_BIN"
}

# --- Configuração dos repositórios e contrib ---
setup_repos() {
    msg "Clonando repositórios oficiais..."
    [ ! -d "$KISS_REPO_DIR/core" ] && \
        git clone https://github.com/kisslinux/repo "$KISS_REPO_DIR/core"

    [ ! -d "$KISS_REPO_DIR/extra" ] && \
        git clone https://github.com/kisslinux/community "$KISS_REPO_DIR/extra"

    [ ! -d "$KISS_REPO_DIR/contrib" ] && \
        git clone https://github.com/kisslinux/contrib "$KISS_REPO_DIR/contrib"

    msg "Instalando scripts extras (contrib)..."
    if [ ! -d "$KISS_CONTRIB_DIR/.git" ]; then
        git clone https://github.com/kisslinux/contrib "$KISS_CONTRIB_DIR"
    fi

    for script in "$KISS_CONTRIB_DIR"/*; do
        [ -f "$script" ] && ln -sf "$script" "$PREFIX/bin/$(basename "$script")"
    done

    msg "Criando arquivos de configuração..."
    cat > /etc/kiss/kiss.conf <<EOF
export KISS_ROOT=/
export KISS_TMPDIR=/tmp
export KISS_CHOICE=1
EOF

    cat > /etc/profile.d/kiss.sh <<EOF
# Configuração do KISS Linux Package Manager
# Ordem importa: /mnt/usr/kiss tem prioridade sobre os outros repositórios
export KISS_PATH=/mnt/usr/kiss:$KISS_REPO_DIR/core:$KISS_REPO_DIR/extra:$KISS_REPO_DIR/contrib
export KISS_ROOT=/
export KISS_TMPDIR=/tmp
export KISS_CHOICE=1
EOF
    chmod +x /etc/profile.d/kiss.sh
}

# --- Help de uso ---
usage() {
    cat <<EOF
KISS Package Manager - Bootstrap concluído!

Repositórios ativos (ordem de prioridade):
  1. /mnt/usr/kiss       (overlay local do usuário)
  2. core                ($KISS_REPO_DIR/core)
  3. extra               ($KISS_REPO_DIR/extra)
  4. contrib             ($KISS_REPO_DIR/contrib)

Estrutura criada:
  - $KISS_BIN             (binário do gerenciador)
  - $KISS_DB              (banco de pacotes instalados)
  - $KISS_CACHE           (cache de builds)
  - $KISS_LOG             (logs do gerenciador)
  - $KISS_CONTRIB_DIR     (scripts extras)
  - /mnt/usr/kiss         (repositório overlay do usuário)

Exemplo de uso:
  kiss update             Atualiza repositórios
  kiss search <pkg>       Procura pacote
  kiss install <pkg>      Instala pacote
  kiss remove <pkg>       Remove pacote
  kiss build <pkg>        Compila pacote
  kiss list               Lista pacotes instalados
  kiss manifest <pkg>     Mostra arquivos instalados

Overlay local (/mnt/usr/kiss):
  Coloque aqui seus pacotes personalizados.
  Estrutura esperada:
    /mnt/usr/kiss/<pacote>/build
    /mnt/usr/kiss/<pacote>/version
    /mnt/usr/kiss/<pacote>/sources
    /mnt/usr/kiss/<pacote>/depends
  Pacotes neste diretório terão prioridade sobre os oficiais.

Scripts extras (contrib):
  Foram instalados em $PREFIX/bin, ex:
    kiss-orphans   → lista pacotes órfãos
    kiss-revdepends → mostra dependentes reversos
    kiss-export    → exporta pacotes
EOF
}

# --- Execução principal ---
main() {
    setup_dirs
    install_kiss
    setup_repos
    usage
    msg "Bootstrap do KISS concluído com sucesso!"
}

main "$@"
