#!/bin/bash
#source ./config.ini

#echo "username:"$username
#echo "password:"$password

# et -e
logger "Arrancando instalacion y configuracion de MongoDB"
USO="Uso : install.sh [opciones]
Ejemplo:
install.sh -f /ruta/config.ini 
install.sh -u administrador -p password [-n 27017]
Opciones:
-f /ruta/config.ini
-u usuario
-p password
-n numero de puerto (opcional)
-a muestra esta ayuda
"
function ayuda() {
    echo "${USO}"
    if [[ ${1} ]]

    then
    echo ${1}
    fi
}
# Gestionar los argumentos
while getopts ":f:u:p:n:a" OPCION
do
case ${OPCION} in
# agregamos esta opcion en el case para que pueda leer archivos pasados por parametros con el argumento -f
f)
source $OPTARG

if [ -z $username ]
then
ayuda "El usuario debe ser especificado en config.ini (username=\"usuario\")"; exit 1
fi
if [ -z $password ]
then
ayuda "La password debe ser especificada en config.ini (password=\"contraseña\")"; exit 1
fi

USUARIO=$username
PASSWORD=$password
PUERTO=$port
break;;
u)
USUARIO=$OPTARG
echo "Parametro USUARIO establecido con '${USUARIO}'";;
p)
PASSWORD=$OPTARG
echo "Parametro PASSWORD establecido";;
n)
PUERTO_MONGOD=$OPTARG
echo "Parametro PUERTO_MONGOD establecido con '${PUERTO_MONGOD}'";;
a) ayuda; exit 0;;
:) ayuda "Falta el parametro para -$OPTARG"; exit 1;; \?) ayuda "La
opcion no existe : $OPTARG"; exit 1;;
esac
done
if [ -z ${USUARIO} ]
then
ayuda "El usuario (-u) debe ser especificado"; exit 1
fi
if [ -z ${PASSWORD} ]
then
ayuda "La password (-p) debe ser especificada"; exit 1
fi
if [ -z ${PUERTO_MONGOD} ]
then
PUERTO_MONGOD=27017
fi
# Preparar el repositorio (apt-get) de mongodb añadir su clave apt
rm /etc/apt/sources.list.d/mongodb*.list
#apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 4B7C549A058F8B6B
#echo "deb [ arch=amd64,arm64 xenial/mongodb-org/4.2 ] https://repo.mongodb.org/apt/ubuntu multiverse" | tee /etc/apt/sources.list.d/mongodb.list
#curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
#echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list


if [[ -z "$(mongo --version 2> /dev/null | grep '4.2.1')" ]]
then
# Instalar paquetes comunes, servidor, shell, balanceador de shards y herramientas
apt-get -y update \
&& apt-get install -y \
mongodb-org=4.2.1 \
mongodb-org-server=4.2.1 \
mongodb-org-shell=4.2.1 \
mongodb-org-mongos=4.2.1 \
mongodb-org-tools=4.2.1 \
&& rm -rf /var/lib/apt/lists/* \
&& pkill -u mongodb || true \
&& pkill -f mongod || true \
&& rm -rf /var/lib/mongodb
fi
# Crear las carpetas de logs y datos con sus permisos
[[ -d "/datos/bd" ]] || mkdir -p -m 755 "/datos/bd"
[[ -d "/datos/log" ]] || mkdir -p -m 755 "/datos/log"
# Establecer el dueño y el grupo de las carpetas db y log
chown mongodb /datos/log /datos/bd
chgrp mongodb /datos/log /datos/bd
# Crear el archivo de configuración de mongodb con el puerto solicitado
mv /etc/mongod.conf /etc/mongod.conf.orig
(
cat <<MONGOD_CONF
# /etc/mongod.conf
systemLog:
 destination: file
 path: /datos/log/mongod.log
 logAppend: true
storage:
 dbPath: /datos/bd
 engine: wiredTiger
 journal:
    enabled: true
net:
 port: ${PUERTO_MONGOD}
security:
 authorization: enabled
MONGOD_CONF
) > /etc/mongod.conf
# Reiniciar el servicio de mongod para aplicar la nueva configuracion
systemctl restart mongod
logger "Esperando a que mongod responda..."

# Se implementa validacion para verificar que mongodb este ejecutandose
if [ "$(systemctl show -p ActiveState mongod | sed 's/ActiveState=//g')" != "active" ] && [ "$(systemctl show -p SubState mongod | sed 's/SubState=//g')"  != "running" ]
then
        # echo "$SERVICE is inactive" | mailx -r admin@server.com -s "$SERVICE not running on $HOSTNAME"  my_account@server.com
        echo "Algo esta mal con la instalacion de mongo..."; exit 1
else
        echo "---> Mongo esta corriendo sin novedades...";
fi
sleep 15

# Crear usuario con la password proporcionada como parametro
mongo admin << CREACION_DE_USUARIO
db.createUser({
user: "${USUARIO}",
pwd: "${PASSWORD}",
roles:[{
role: "root",
db: "admin"
},{
role: "restore",
db: "admin"
}] })
CREACION_DE_USUARIO


logger "El usuario ${USUARIO} ha sido creado con exito!"



exit 0