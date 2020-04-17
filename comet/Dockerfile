FROM mcr314/minerva_highway:v202004

RUN ["/bin/busybox", "--install"]
ENV RAILS_ENV=production
ENV GEM_HOME="/usr/local/bundle"
ENV CERTDIR=/app/certificates

COPY . /app/highway

CMD ["bundle", "exec", "thin", "start", "--ssl",      \
    "--address", "::", "--port", "9443",  "--threaded",     \
    "--ssl-cert-file", "/app/certificates/server_prime256v1.crt",\
    "--ssl-key-file",  "/app/certificates/server_prime256v1.key" ]


