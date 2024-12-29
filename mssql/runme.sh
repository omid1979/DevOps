docker pull mcr.microsoft.com/mssql/server:2022-latest

docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Aa@12345" \
   -p 1433:1433 --name sql1 --hostname sql1 \
   -d \
   mcr.microsoft.com/mssql/server:2022-latest

docker exec -it sql1 /opt/mssql-tools18/bin/sqlcmd \
-S localhost -U sa \
 -P "$(read -sp "Enter current SA password: "; echo "${REPLY}")" \
 -Q "ALTER LOGIN sa WITH PASSWORD=\"$(read -sp "Enter new SA password: "; echo "${REPLY}")\""

#/opt/mssql-tools18/bin/sqlcmd -S localhost -U <userid> -P "<password>"
#
#
