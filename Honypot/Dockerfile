# Use the official Alpine Linux image as base.
FROM alpine

# Update package index and install bash.
RUN apk update && apk add --no-cache bash python3
WORKDIR /app
COPY keep-alive.sh /usr/local/bin/
COPY honeypot.py   .
RUN chmod +x /usr/local/bin/keep-alive.sh
#CMD ["/usr/local/bin/keep-alive.sh"]
EXPOSE 80 8080 2222 22 21 23 1443 443 1883 5432 9090 8000 4000 
CMD ["python3", "honeypot.py"]
