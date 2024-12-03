docker run --name nginx-web1 -p 8081:80 -v ./html1:/usr/share/nginx/html:ro -d nginx
docker run --name nginx-web2 -p 8082:80 -v ./html2:/usr/share/nginx/html:ro -d nginx
docker run --name nginx-web3 -p 8083:80 -v ./html3:/usr/share/nginx/html:ro -d nginx

