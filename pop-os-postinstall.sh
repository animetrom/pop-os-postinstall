#!/usr/bin/env bash
#
# pos-os-postinstall.sh - Instalar e configura programas no Pop!_OS (22.04 LTS ou superior)
#
# ------------------------------------------------------------------------ #
#
# COMO USAR?
#   $ ./pos-os-postinstall.sh
#
# ----------------------------- VARIÁVEIS ----------------------------- #
set -e

## Função para obter a última versão de um .deb do GitHub ##
latest_github_release(){
  repo=$1
  curl -s "https://api.github.com/repos/$repo/releases/latest" | grep "browser_download_url.*amd64.deb" | cut -d '"' -f 4
}

## URLS

URL_FIREFOXPWA=$(latest_github_release "filips123/PWAsForFirefox")
URL_XDMAN=$(latest_github_release "subhra74/xdm")
URL_WHATSAPP=$(latest_github_release "eneshecan/whatsapp-for-linux")
URL_DISCORD="https://discord.com/api/download?platform=linux&format=deb"
URL_APP_OUTLET=$(latest_github_release "AppOutlet/AppOutlet")
URL_FREETUBE=$(latest_github_release "FreeTubeApp/FreeTube")

## DIRETÓRIOS E ARQUIVOS

DIRETORIO_DOWNLOADS="$HOME/Downloads/Programs"
FILE="/home/$USER/.config/gtk-3.0/bookmarks"

# CORES

VERMELHO='\e[1;91m'
VERDE='\e[1;92m'
SEM_COR='\e[0m'

# FUNÇÕES

# Atualizando repositório e fazendo atualização do sistema

apt_update(){
  sudo apt update && sudo apt dist-upgrade -y
}

# Internet conectando?
testes_internet(){
if ! ping -c 1 8.8.8.8 -q &> /dev/null; then
  echo -e "${VERMELHO}[ERROR] - Seu computador não tem conexão com a Internet. Verifique a rede.${SEM_COR}"
  exit 1
else
  echo -e "${VERDE}[INFO] - Conexão com a Internet funcionando normalmente.${SEM_COR}"
fi
}

## Removendo travas eventuais do apt ##
travas_apt(){
  sudo rm /var/lib/dpkg/lock-frontend
  sudo rm /var/cache/apt/archives/lock
}

## Adicionando/Confirmando arquitetura de 32 bits ##
add_archi386(){
  sudo dpkg --add-architecture i386
}
## Atualizando o repositório ##
just_apt_update(){
  sudo apt update -y
}

##DEB SOFTWARES TO INSTALL

PROGRAMAS_PARA_INSTALAR=(
  gparted
  gufw
  synaptic
  vlc
  gnome-sushi 
  folder-color
  git
  wget
  ubuntu-restricted-extras
  v4l2loopback-utils
  flameshot
)

##FLATPAK SOFTWARES TO INSTALL

PROGRAMAS_PARA_INSTALAR_FLATPAK=(
  com.mattjakeman.ExtensionManager
  com.usebottles.bottles
  io.github.flattool.Warehouse
  org.gajim.Gajim
  it.mijorus.gearlever
  com.github.ryonakano.pinit
  io.github.glaumar.QRookie
  com.spotify.Client
  org.remmina.Remmina
  io.github.tdesktop_x64.TDesktop
)

## Função para instalar pacotes .deb e corrigir dependências ##
install_deb_with_deps(){
  deb_file=$1
  echo -e "${VERDE}[INFO] - Instalando $deb_file${SEM_COR}"
  sudo dpkg -i "$deb_file" || (sudo apt-get install -f -y && sudo dpkg -i "$deb_file")
}

## Download e instalação de programas externos ##

install_debs(){

  echo -e "${VERDE}[INFO] - Baixando pacotes .deb${SEM_COR}"

  mkdir -p "$DIRETORIO_DOWNLOADS"

  wget -c "$URL_FIREFOXPWA" -O "$DIRETORIO_DOWNLOADS/firefoxpwa.deb"
  install_deb_with_deps "$DIRETORIO_DOWNLOADS/firefoxpwa.deb"

  wget -c "$URL_XDMAN" -P "$DIRETORIO_DOWNLOADS"

  wget -c "$URL_WHATSAPP" -P "$DIRETORIO_DOWNLOADS"

  wget -c "$URL_DISCORD" -P "$DIRETORIO_DOWNLOADS"

  wget -c "$URL_APP_OUTLET" -P "$DIRETORIO_DOWNLOADS"

  wget -c "$URL_FREETUBE" -P "$DIRETORIO_DOWNLOADS"

  ## Instalando pacotes .deb baixados na sessão anterior ##
  echo -e "${VERDE}[INFO] - Instalando pacotes .deb baixados${SEM_COR}"
  for deb in $DIRETORIO_DOWNLOADS/*.deb; do
    install_deb_with_deps "$deb"
  done

  # Instalar programas no apt
  echo -e "${VERDE}[INFO] - Instalando pacotes apt do repositório${SEM_COR}"

  for nome_do_programa in ${PROGRAMAS_PARA_INSTALAR[@]}; do
    if ! dpkg -l | grep -q $nome_do_programa; then # Só instala se já não estiver instalado
      sudo apt install "$nome_do_programa" -y
    else
      echo "[INSTALADO] - $nome_do_programa"
    fi
  done

}

## Instalando pacotes Flatpak ##
install_flatpaks(){

  echo -e "${VERDE}[INFO] - Instalando pacotes flatpak${SEM_COR}"

  for flatpak_program in ${PROGRAMAS_PARA_INSTALAR_FLATPAK[@]}; do
    flatpak install flathub $flatpak_program -y
  done
}

## Adicionar repositório e instalar Minecraft Bedrock Launcher ##
install_minecraft_bedrock_launcher(){

  echo -e "${VERDE}[INFO] - Adicionando repositório do Minecraft Bedrock Launcher${SEM_COR}"

  # Adicionar GPG key
  curl -sS https://minecraft-linux.github.io/pkg/deb/pubkey.gpg | sudo tee -a /etc/apt/trusted.gpg.d/minecraft-linux-pkg.asc

  # Obter versão do sistema
  DISTRO=$(lsb_release -cs)

  # Adicionar repositório
  echo "deb [arch=amd64,arm64] https://minecraft-linux.github.io/pkg/deb ${DISTRO}-nightly main" | sudo tee /etc/apt/sources.list.d/minecraft-linux-pkg.list

  # Atualizar repositórios
  if ! sudo apt update; then
    echo -e "${VERMELHO}[ERROR] - Não foi possível adicionar o repositório do Minecraft Bedrock Launcher para a distribuição ${DISTRO}.${SEM_COR}"
    return 1
  fi

  # Instalar pacotes
  sudo apt install mcpelauncher-manifest mcpelauncher-ui-manifest msa-manifest -y
}

## Adicionar repositório e instalar qBittorrent Enhanced ##
install_qbittorrent_enhanced(){

  echo -e "${VERDE}[INFO] - Adicionando repositório do qBittorrent Enhanced${SEM_COR}"

  # Adicionar PPA
  sudo add-apt-repository ppa:poplite/qbittorrent-enhanced -y

  # Atualizar repositórios
  if ! sudo apt update; then
    echo -e "${VERMELHO}[ERROR] - Não foi possível adicionar o repositório do qBittorrent Enhanced.${SEM_COR}"
    return 1
  fi

  # Instalar qBittorrent Enhanced
  sudo apt install qbittorrent-enhanced -y
}

# -------------------------------------------------------------------------- #
# ----------------------------- PÓS-INSTALAÇÃO ----------------------------- #

## Configuração do Dual Boot ##

dualboot_config(){
  echo -e "${VERDE}[INFO] - Configurando Dual Boot${SEM_COR}"

  sudo apt install os-prober -y
  sudo os-prober
  sudo apt update && sudo apt upgrade -y
  sudo apt install grub-efi grub2-common grub-customizer -y
  sudo grub-install
  sudo cp /boot/grub/x86_64-efi/grub.efi /boot/efi/EFI/pop/grubx64.efi

  echo -e "${VERDE}[INFO] - Dual Boot configurado parcialmente.${SEM_COR}"
  echo -e "${VERMELHO}[MANUAL] - Abra o GRUB CUSTOMIZER e defina o caminho /boot/efi/EFI/pop/grubx64.efi no campo OUTPUT_FILE.${SEM_COR}"
}

## Finalização, atualização e limpeza ##

system_clean(){
  apt_update -y
  flatpak update -y
  sudo apt autoclean -y
  sudo apt autoremove -y
  nautilus -q
}

# -------------------------------------------------------------------------- #
# ----------------------------- CONFIGS EXTRAS ----------------------------- #

# Cria pastas para produtividade no nautilus
extra_config(){

  mkdir -p /home/$USER/TEMP
  mkdir -p /home/$USER/EDITAR 
  mkdir -p /home/$USER/Resolve
  mkdir -p /home/$USER/AppImage
  mkdir -p /home/$USER/Vídeos/'OBS Rec'

  # Adiciona atalhos ao Nautilus

  if test -f "$FILE"; then
      echo "$FILE já existe"
  else
      echo "$FILE não existe, criando..."
      touch /home/$USER/.config/gtk-3.0/bookmarks
  fi

  echo "file:///home/$USER/EDITAR 🔵 EDITAR" >> $FILE
  echo "file:///home/$USER/AppImage" >> $FILE
  echo "file:///home/$USER/Resolve 🔴 Resolve" >> $FILE
  echo "file:///home/$USER/TEMP 🕖 TEMP" >> $FILE
}

# -------------------------------------------------------------------------------- #
# -------------------------------EXECUÇÃO----------------------------------------- #

travas_apt
testes_internet
travas_apt
apt_update
travas_apt
add_archi386
just_apt_update
install_debs
install_flatpaks
install_qbittorrent_enhanced
install_minecraft_bedrock_launcher
extra_config
apt_update
system_clean
dualboot_config

## finalização

echo -e "${VERDE}[INFO] - Script finalizado, instalação concluída! :)${SEM_COR}"
