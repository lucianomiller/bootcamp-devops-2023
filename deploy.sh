#!/bin/bash
#Variable
repo="https://github.com/roxsross/bootcamp-devops-2023.git"
file="bootcamp-devops-2023"
branch="clase2-linux-bash"
app_path="app-295devops-travel"
USERID=$(id -u)

config_file="/etc/apache2/mods-enabled/dir.conf"
db_php="bootcamp-devops-2023/app-295devops-travel/config.php"
#colores
LRED='\033[1;31m'
LGREEN='\033[1;32m'
NC='\033[0m'
LBLUE='\033[0;34m'
LYELLOW='\033[1;33m'



if [ "${USERID}" -ne 0 ]; then
    echo -e "\n${LRED}Correr con usuario ROOT${NC}"
    exit
fi 

echo "====================================="
apt-get update -p

#### git ######

echo -e "\n${LGREEN}El Servidor se encuentra Actualizado ...${NC}"

if dpkg -s git > /dev/null 2>&1; then
    echo -e "\n${LBLUE}GIT se encuentra ya instalado ...${NC}"
else    
    echo -e "\n${LYELLOW}instalando GIT ...${NC}"
    apt install -y git
fi


#### base de datos maria db ######
 
if dpkg -s mariadb-server > /dev/null 2>&1; then
    echo -e "\n${LBLUE}El Servidor se encuentra Actualizado ...${NC}"
else    
    echo -e "\n${LYELLOW}instalando MARIA DB ...${NC}"
    apt install -y mariadb-server
###Iniciando la base de datos
    systemctl start mariadb
    systemctl enable mariadb
fi

#apache [WEB]

if dpkg -s apache2 > /dev/null 2>&1; then
    echo -e "\n${LBLUE}El Apache2 se encuentra ya instalado ...${NC}"
else    
    echo -e "\n\e[92mInstalando Apache2 ...\033[0m\n"
    apt install -y apache2
    apt install -y php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl
    systemctl start apache2
    systemctl enable apache2
    mv /var/www/html/index.html /var/www/html/index.html.bkp
fi

# Modificar el archivo dir.conf de Apache
if [ -f "$config_file" ]; then
    # Realizar los cambios en el archivo dir.conf
    sed -i 's/DirectoryIndex.*/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g' "$config_file"
    echo "Se han actualizado las configuraciones en $config_file"
    systemctl reload apache2
else
    echo "El archivo $config_file no existe. Asegúrate de que Apache esté instalado o de que la ruta sea la correcta."
fi

# Clonar el repositorio
if [ -d "$file" ]; then
    echo -e "\n${LBLUE}La carpeta $file existe ...${NC}"
    git pull --single-branch --branch $branch
else
    git clone $repo --single-branch --branch $branch
fi

echo -e "\n${LYELLOW}instalando WEB ...${NC}"
sleep 1
#git clone $repo --branch $branch --single-branch

# Insertar password en el archivo config.php
if [ ! -f "$db_php" ]; then
    echo "El archivo $db_php no existe. Asegúrate de que la ruta sea correcta."
    exit 
else
    # Inserta la contraseña en el archivo config.php
    sed -i "s/\$dbPassword = \"\";/\$dbPassword = \"codepass\";/" "$db_php"
    echo "Contraseña de la base de datos insertada en $db_php"
fi

# Copiar el contenido de la carpeta app-295devops-travel a /var/www/html
cp -r $file/$app_path/* /var/www/html

###Configuracion de la base de datos 
if mysql -e "USE devopstravel;" 2>/dev/null; then
    echo -e "\n${LGREEN}La base de datos 'devopstravel' ya existe ...${NC}"
else
    echo -e "\n${LBLUE}Configurando base de datos ...${NC}"
    mysql -e "
    CREATE DATABASE devopstravel;
    CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
    GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
    FLUSH PRIVILEGES;"
    #ejecutar script
    mysql < $file/$app_path/database/devopstravel.sql
fi

echo "====================================="

### reload
systemctl reload apache2

./discord.sh $file