docker run -d --env-file .ora_db_env.dat -p 1521:1521 --name oracle-std --shm-size="8g" container-registry.oracle.com/database/standard:latest
docker logs oracle-std
docker exec -it oracle-std ./setPassword.sh oracle

sqlplus system/oracle@//localhost:1521/FREEPDB1



#### https://github.com/oracle/docker-images
